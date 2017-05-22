# Utilities to filter occurrences of UMLS semantic type in pubmed articles
# Date: September 7, 2016
# Authors: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5

using BioMedQuery.Entrez.DB


"""
umls_semantic_occurrences(db, umls_semantic_type)

Return a sparse matrix indicating the presence of MESH descriptors associated
with a given umls semantic type in all articles of the input database

###Output

* `des_ind_dict`: Dictionary matching row number to descriptor names
* `disease_occurances` : Sparse matrix. The columns correspond to a feature
vector, where each row is a MESH descriptor. There are as many
columns as articles. The occurance/abscense of a descriptor is labeled as 1/0
"""

function umls_semantic_occurrences(db, umls_semantic_type_1, umls_semantic_type_2 = "none", umls_semantic_type_3 = "none", umls_semantic_type_4 = "none", umls_semantic_type_5 = "none")

    mesh_descriptor = mysql_execute(db, "SELECT * FROM mesh_descriptor;") #get mesh descriptor data from MySQL
    mesh_heading = mysql_execute(db, "SELECT * FROM mesh_heading;") #get header data from MySQL
    mesh2umls = mysql_execute(db, "SELECT * FROM mesh2umls;") #get data umls data from MySQL
    rename!(mesh_descriptor, [:id, :name], [:did, :mesh_descriptor]) #change columns name for join
    data = sort(join(mesh_descriptor, mesh_heading, on = :did)[:,[:mesh_descriptor, :pmid]], cols=:pmid) #data of mesh terms for each article
    rename!(mesh2umls, :mesh, :mesh_descriptor) #change column name for join
    if umls_semantic_type_2 == "none"
        umls_filtered = mesh2umls[mesh2umls[:umls] .== "$umls_semantic_type_1",:] #filter by semantic type
    elseif umls_semantic_type_3 == "none"
        umls_filtered = mesh2umls[(mesh2umls[:umls] .== "$umls_semantic_type_1") | (mesh2umls[:umls] .== "$umls_semantic_type_2"),:] #filter by semantic type
    elseif umls_semantic_type_4 == "none"
        umls_filtered = mesh2umls[(mesh2umls[:umls] .== "$umls_semantic_type_1") | (mesh2umls[:umls] .== "$umls_semantic_type_2") | (mesh2umls[:umls] .== "$umls_semantic_type_3"),:] #filter by semantic type
    elseif umls_semantic_type_5 == "none"
        umls_filtered = mesh2umls[(mesh2umls[:umls] .== "$umls_semantic_type_1") | (mesh2umls[:umls] .== "$umls_semantic_type_2") | (mesh2umls[:umls] .== "$umls_semantic_type_3") | (mesh2umls[:umls] .== "$umls_semantic_type_4"),:] #filter by semantic type
    else
        umls_filtered = mesh2umls[(mesh2umls[:umls] .== "$umls_semantic_type_1") | (mesh2umls[:umls] .== "$umls_semantic_type_2") | (mesh2umls[:umls] .== "$umls_semantic_type_3") | (mesh2umls[:umls] .== "$umls_semantic_type_4") | (mesh2umls[:umls] .== "$umls_semantic_type_5"),:] #filter by semantic type
    end
    data_filtered = join(data, umls_filtered, on = :mesh_descriptor) #new data after filtering
    arts_filtered = unique(data_filtered[:pmid]) #article ID's after filtering
    mesh_counts_filtered = sort(collect(zip(values(countmap(data_filtered[:mesh_descriptor])),keys(countmap(data_filtered[:mesh_descriptor])))),rev=true) #counts for mesh descriptors after filtering
    mesh_descrips_filtered=DataFrame(Any,0,2)
    for i in 1:length(mesh_counts_filtered)
        mesh_descrip_filtered = [mesh_counts_filtered[i][1],mesh_counts_filtered[i][2]]
        push!(mesh_descrips_filtered, mesh_descrip_filtered)
    end #get mesh counts into usable form
    frequency = DataArray(Float64, length(mesh_descrips_filtered[2]))
    for i in 1:length(mesh_descrips_filtered[2])
        freq = length(unique(data_filtered[data_filtered[:mesh_descriptor] .== mesh_descrips_filtered[i,2],2]))/length(arts_filtered)
        frequency[i] = freq
    end #calculate frequency for each mesh term
    mesh_descrips_filtered[:freq]=frequency #add frequencies to data
    sort!(mesh_descrips_filtered, cols = :freq, rev = true) #sort by frequency
    rename!(mesh_descrips_filtered, [:x1, :x2], [:count, :mesh_descriptor]) #rename columns

    filtered_mesh = Set(mesh_descrips_filtered[:mesh_descriptor])

    #create a map of filtered descriptor name to index to guarantee order
    des_ind_dict = Dict()

    for (i, fm) in enumerate(filtered_mesh)
        des_ind_dict[fm]= i
    end

    articles = all_pmids(db)

    #create the data-matrix
    disease_occurances = spzeros(length(filtered_mesh), length(articles))

    #Can this process be more efficient using database join/select?
    narticle = 0

    for (i, pmid) in enumerate(articles)

        #get all mesh descriptors associated with give article
        article_mesh = Set(Entrez.DB.get_article_mesh(db, pmid))

        #not all mesh are of the desired semantic type
        article_filtered_mesh = intersect(article_mesh, filtered_mesh)

        #skip if empty
        if isempty(article_filtered_mesh)
            continue
        end

        #otherwise form feature vector for this article
        indices = []
        for d in article_filtered_mesh
            push!(indices, des_ind_dict[d])
        end

        #TO DO: Not sure about the type. Should we choose bool to save space
        # or float to support opperations
        article_dis_feature  = zeros(Int, (length(filtered_mesh),1))
        article_dis_feature[indices] = 1

        #append to data matrix
        disease_occurances[:, i] = article_dis_feature
        narticle+=1
    end

    name_dict = sort(collect(des_ind_dict), by=x->x[2])

    col_names = DataArray(AbstractString, length(des_ind_dict))

    for i in 1:length(des_ind_dict)
        name = name_dict[i][1]
        col_names[i] = name
    end

    itemsets = DataFrame(Matrix(convert(Array{Int64}, disease_occurances')))

    names!(itemsets, [symbol(col_names[i]) for i in 1:length(col_names)])

    println("-------------------------------------------------------------")
    println("Found ", narticle, " articles with valid descriptors")
    println("-------------------------------------------------------------")
    return itemsets

end


# Retrieve all mesh descriptors associated with the given umls_concept
function filter_mesh_by_concept(db, umls_concept)

    uc = string("'", replace(umls_concept, "'", "''") , "'")
    query  = db_query(db, "SELECT mesh FROM mesh2umls
    WHERE umls LIKE $uc ")

    #return data array
    return get_value(query.columns[1])

end
