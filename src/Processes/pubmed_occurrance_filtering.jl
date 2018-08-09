# Utilities to filter occurrences of UMLS semantic type in pubmed articles
# Date: September 7, 2016
# Authors: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5

using BioMedQuery.PubMed
using DataFrames
using SparseArrays

"""
    umls_semantic_occurrences(db, umls_semantic_type)

Return a sparse matrix indicating the presence of MESH descriptors associated
with a given umls semantic type in all articles of the input database

## Output

* `des_ind_dict`: Dictionary matching row number to descriptor names
* `disease_occurances` : Sparse matrix. The columns correspond to a feature vector, where each row is a MESH descriptor. There are as many columns as articles. The occurance/abscense of a descriptor is labeled as 1/0
"""
function umls_semantic_occurrences(db, umls_concepts...)

    filtered_mesh = Set(filter_mesh_by_concept(db, umls_concepts...))

    #create a map of filtered descriptor name to index to guarantee order
    des_ind_dict = Dict{String, Int}()

    for (i, fm) in enumerate(filtered_mesh)
        des_ind_dict[fm]= i
    end

    articles = all_pmids(db)

    #create the data-matrix
    disease_occurances = spzeros(length(filtered_mesh), length(articles))

    #Can this process be more efficient using database join/select?
    narticle = 0

    for (i, pmid) in enumerate(articles)

        #not all mesh are of the desired semantic type
        article_filtered_mesh = PubMed.get_article_mesh_by_concept(db, pmid, umls_concepts...)

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
        article_dis_feature[indices] .= 1

        #append to data matrix
        disease_occurances[:, i] = article_dis_feature
        narticle+=1
    end

    println("-------------------------------------------------------------")
    println("Found ", narticle, " articles with valid descriptors")
    println("-------------------------------------------------------------")
    return des_ind_dict, disease_occurances

end


# Retrieve all mesh descriptors associated with the given umls_concept
function filter_mesh_by_concept(db, umls_concepts...)

    concept_set_string = "'" * join(umls_concepts,"','") * "'"

    query = string("SELECT mesh FROM mesh2umls WHERE umls IN ($(concept_set_string))")
    println("Filter mesh query string : $(query)")

    sel  = db_query(db, query)
    return sel[1]
end

"""
    umls_semantic_occurrences(dfs, mesh2umls_df, umls_semantic_type)

Return a sparse matrix indicating the presence of MESH descriptors associated
with a given umls semantic type in all articles of the input database

## Output

* `des_ind_dict`: Dictionary matching row number to descriptor names
* `disease_occurances` : Sparse matrix. The columns correspond to a feature vector, where each row is a MESH descriptor. There are as many columns as articles. The occurance/abscense of a descriptor is labeled as 1/0
"""
function umls_semantic_occurrences(dfs::Dict{String,DataFrame}, mesh2umls_df::DataFrame, umls_concepts...)

    filtered_mesh = Set(filter_mesh_by_concept(mesh2umls_df, umls_concepts...))

    #create a map of filtered descriptor name to index to guarantee order
    des_ind_dict = Dict{String, Int}()

    for (i, fm) in enumerate(filtered_mesh)
        des_ind_dict[fm]= i
    end

    articles = dfs["basic"][:pmid]

    #create the data-matrix
    disease_occurances = spzeros(length(filtered_mesh), length(articles))

    #Can this process be more efficient using database join/select?
    narticle = 0

    for (i, pmid) in enumerate(articles)

        #not all mesh are of the desired semantic type
        article_filtered_mesh = get_article_mesh_by_concept(dfs, filtered_mesh, pmid)

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
        article_dis_feature[indices] .= 1

        #append to data matrix
        disease_occurances[:, i] = article_dis_feature
        narticle+=1
    end

    println("-------------------------------------------------------------")
    println("Found ", narticle, " articles with valid descriptors")
    println("-------------------------------------------------------------")
    return des_ind_dict, disease_occurances

end


# Retrieve all mesh descriptors associated with the given umls_concept
function filter_mesh_by_concept(mesh2umls_df::DataFrame, umls_concepts...)

    res = filter(row -> row[:concept] in umls_concepts, mesh2umls_df)

    return res[:descriptor]
end


#convert sparse matrix from semantic occurances function into a dataframe ready to be plugged into the apriori function
function occurances_to_itemsets(des_ind_dict, disease_occurances)
    name_dict = sort(collect(des_ind_dict), by=x->x[2])
    col_names = DataArray(String, length(des_ind_dict))
    for i in 1:length(des_ind_dict)
        name = name_dict[i][1]
        col_names[i] = name
    end
    itemsets = DataFrame(Matrix(convert(Array{Int64}, disease_occurances')))
    names!(itemsets, [symbol(col_names[i]) for i in 1:length(col_names)])
    return itemsets
end

# dataframe version of SQL function in pubmed_sql_utils
function get_article_mesh_by_concept(dfs::Dict{String,DataFrame}, filtered_mesh, article::Int)

    filtered_by_pmid = filter(row -> row[:pmid] == article , dfs["mesh_heading"])

    get_uids = filter(row -> row[:uid] in filtered_by_pmid[:desc_uid], dfs["mesh_desc"])

    filtered_by_mesh = filter(row -> row[:name] in filtered_mesh, get_uids)


    return filtered_by_mesh[:name]

end
