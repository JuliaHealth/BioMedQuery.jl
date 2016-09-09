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
function umls_semantic_occurrences(db, umls_semantic_type)

    #retrieve a list of filtered descriptors
    filtered_mesh = Set(filter_mesh_by_concept(db, umls_semantic_type))

    println("-------------------------------------------------------------")
    println("Found ", length(filtered_mesh), " MESH decriptor related to  ", umls_semantic_type)
    println(filtered_mesh)
    println("-------------------------------------------------------------")

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

    println("-------------------------------------------------------------")
    println("Found ", narticle, " articles with valid descriptors")
    println("-------------------------------------------------------------")
    return des_ind_dict, disease_occurances

end


# Retrieve all mesh descriptors associated with the given umls_concept
function filter_mesh_by_concept(db, umls_concept)

    uc = string("'", replace(umls_concept, "'", "''") , "'")
    query  = db_query(db, "SELECT mesh FROM mesh2umls
    WHERE umls LIKE $uc ")

    #return data array
    return get_value(query.columns[1])

end
