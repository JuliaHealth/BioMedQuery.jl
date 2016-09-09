using BioMedQuery.UMLS
using BioMedQuery.Entrez.DB
using BioMedQuery.DBUtils

"""
map_mesh_to_umls!(db, c::Credentials)

Build and store in the given database a map from MESH descriptors to
UMLS Semantic Concepts

###Arguments

- `db`: Database. Must contain TABLE:mesh_descriptor. For each of the
descriptors in that table, search and insert the associated semantic
concepts into a new (cleared) TABLE:mesh2umls
- `c::Credentials`: UMLS username and password
"""
function map_mesh_to_umls!(db, c::Credentials; append_results=false)

    #if the mesh2umls relationship table doesn't esxist, create it
    db_query(db, "CREATE table IF NOT EXISTS mesh2umls (
    mesh VARCHAR(255),
    umls VARCHAR(255),
    FOREIGN KEY(mesh) REFERENCES mesh_descriptor(name),
    PRIMARY KEY(mesh, umls)
    )")

    #clear the relationship table
    if !append_results
        db_query(db, "DELETE FROM mesh2umls")
    end

    #select all mesh descriptors
    mq = db_query(db,"SELECT name FROM mesh_descriptor;")

    #get the array of terms
    mesh_terms =get_value(mq.columns[1])
    println("----------Matching MESH to UMLS-----------")
    tgt = get_tgt(c)
    for mt in mesh_terms
        #submit umls query
        term = mt
        query = Dict("string"=>term, "searchType"=>"exact" )
        # println("term: ", term)

        all_results= search_umls(tgt, query)

        if length(all_results) > 0

            cui = best_match_cui(all_results)
            #   println("Cui: ", cui)
            if cui == ""
                println("Nothing!")
                println(all_results)
            end
            all_concepts = get_semantic_type(tgt, cui)

            for concept in all_concepts
                # insert "semantic concept" into database
                insert_row!(db, "mesh2umls", Dict(:mesh=> term, :umls=> concept))
                # println(concept)
            end

        end
        print(".")
    end
    println("--------------------------------------------------")
end


"""
map_mesh_to_umls_async!(db, c::Credentials; timeout, append_results, verbose)
Build (using async UMLS-API calls) and store in the given database a map from
MESH descriptors to UMLS Semantic Concepts. For large queies this function will
be faster than it's synchrounous counterpart

###Arguments

- `db`: Database. Must contain TABLE:mesh_descriptor. For each of the
descriptors in that table, search and insert the associated semantic
concepts into a new (cleared) TABLE:mesh2umls
- `c::Credentials`: UMLS username and password
- `append_results::Bool` : If false a NEW and EMPTY mesh2umls database table in creted
"""
function map_mesh_to_umls_async!(db, c::Credentials; timeout = Inf, append_results=false, verbose=false)

    #if the mesh2umls relationship table doesn't esxist, create it
    db_query(db, "CREATE table IF NOT EXISTS mesh2umls (
    mesh VARCHAR(255),
    umls VARCHAR(255),
    FOREIGN KEY(mesh) REFERENCES mesh_descriptor(name),
    PRIMARY KEY(mesh, umls)
    )")

    #clear the relationship table
    if !append_results
        db_query(db, "DELETE FROM mesh2umls")
    end

    #select all mesh descriptors
    mq = db_query(db,"SELECT name FROM mesh_descriptor;")

    #get the array of terms
    mesh_terms =get_value(mq.columns[1])
    println("----------Matching MESH to UMLS-----------")

    tgt = get_tgt(c)
    errors = 200*ones(length(mesh_terms))
    times = -ones(length(mesh_terms))

    for m=1:50:length(mesh_terms)
        end_loop=m+50
        if end_loop > length(mesh_terms)
            end_loop = length(mesh_terms)
        end
        @sync for i=m:end_loop
            #submit umls async batch query
            @async begin

                term = mesh_terms[i]
                query = Dict("string"=>term, "searchType"=>"exact" )
                # println("term: ", term)
                all_results = []
                try
                    t = @elapsed all_results= search_umls(tgt, query, timeout=timeout)
                    times[i] = t
                    print(".")
                catch err
                    print("!")
                    errors[i] = err.code
                end
                if length(all_results) > 0

                    cui = best_match_cui(all_results)
                    if cui == ""
                        println("Nothing!")
                        println(all_results)
                    end
                    all_concepts = get_semantic_type(tgt, cui)

                    for concept in all_concepts
                        insert_row!(db, "mesh2umls", Dict(:mesh=> term, :umls=> concept), verbose)
                    end
                end
            end
        end
    end
    println("")
    println("--------------------------------------------------")
    return (times,errors)
end
