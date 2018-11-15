using BioServices.UMLS
using BioMedQuery.PubMed
using BioMedQuery.DBUtils
using DataFrames

"""
    map_mesh_to_umls_async!(db, c::Credentials; timeout, append_results, verbose)

Build (using async UMLS-API calls) and store in the given database a map from
MESH descriptors to UMLS Semantic Concepts. For large queies this function will
be faster than it's synchrounous counterpart

## Arguments

* `db`: Database. Must contain TABLE:mesh_descriptor. For each of the descriptors  in that table, search and insert the associated semantic concepts into a new (cleared) TABLE:mesh2umls
* `user` : UMLS username
* `psswd` : UMLS Password
* `append_results::Bool` : If false a NEW and EMPTY mesh2umls database table in creted
* `batch_size`: Number of
"""
function map_mesh_to_umls_async!(db, user, psswd; timeout = 5, append_results=false, verbose=false, batch_size=50)

    # Determine engine
    sql_engine = (typeof(db)== MySQL.Connection) ? MySQL : SQLite
    engine_info = (sql_engine == MySQL) ? "ENGINE=InnoDB DEFAULT CHARSET=utf8" : ""


    #if the mesh2umls relationship table doesn't esxist, create it
    sql_engine.execute!(db, "CREATE table IF NOT EXISTS mesh2umls (
                                mesh VARCHAR(255),
                                umls VARCHAR(255),
                                PRIMARY KEY(mesh, umls)
                            ) $engine_info;")

    #clear the relationship table
    if !append_results
        sql_engine.execute!(db, "DELETE FROM mesh2umls")
    end

    #select all mesh descriptors
    mq = sql_engine.Query(db,"SELECT name FROM mesh_desc;") |> DataFrame

    #get the array of terms
    mesh_terms = mq[:name]
    println("----------Matching MESH to UMLS-----------")
    println(mesh_terms)

    tgt = get_tgt(username = user, password = psswd)
    errors = 200*ones(length(mesh_terms))
    times = -ones(length(mesh_terms))

    for m=1:batch_size:length(mesh_terms)
        end_loop=m+batch_size
        if end_loop > length(mesh_terms)
            end_loop = length(mesh_terms)
        end
        @sync for i=m:end_loop
            #submit umls async batch query
            @async begin
                term = mesh_terms[i]
                query = Dict("string"=>term, "searchType"=>"exact" )
                # println("term: ", term)
                for attempt=1:5
                    try
                        all_results= search_umls(tgt, query, timeout=timeout)
                        @info "Descriptor $i out of $(length(mesh_terms)): $term"
                        if length(all_results) > 0
                            cui = best_match_cui(all_results)
                            if cui == ""
                                println("Nothing!")
                                println(all_results)
                            end
                            all_concepts = get_semantic_types(tgt, cui)
                            for concept in all_concepts
                                insert_row!(db, "mesh2umls", Dict(:mesh=> term, :umls=> concept), verbose)
                            end
                        end
                        break
                    catch err
                        @warn "! failed attempt $attempt out of 5 for term $term with error " err
                    end
                end
            end
        end
    end

end

"""
    map_mesh_to_umls_async(mesh_df, user, psswd; timeout, append_results, verbose)

Build (using async UMLS-API calls) and return a map from
MESH descriptors to UMLS Semantic Concepts. For large queies this function will
be faster than it's synchrounous counterpart

## Arguments

* `mesh_df`: DataFrame countaining Mesh_Descriptors. This is the dataframe with the key `mesh_desc` that is returned from pubmed_search_and_parse.
* `user` : UMLS username
* `psswd` : UMLS Password
"""
function map_mesh_to_umls_async(mesh_df::DataFrame, user, psswd; timeout = 5, verbose=false)

    mesh = Vector{String}()
    umls = Vector{String}()

    #get the array of terms
    mesh_terms = mesh_df[:name]
    num_mesh = length(mesh_terms)

    println("----------Matching MESH to UMLS-----------")
    println(mesh_terms)

    tgt = get_tgt(username = user, password = psswd)
    errors = 200*ones(num_mesh)
    times = -ones(num_mesh)
    batch_size = 50

    for m=1:batch_size:num_mesh

        end_loop = m + batch_size > num_mesh ? num_mesh : m + batch_size

        @sync for i=m:end_loop
            #submit umls async batch query
            @async begin
                term = mesh_terms[i]
                query = Dict("string"=>term, "searchType"=>"exact" )
                # println("term: ", term)
                for attempt=1:5
                    try
                        all_results= search_umls(tgt, query, timeout=timeout)
                        @info "Descriptor $i, out of $num_mesh: $term"
                        if length(all_results) > 0
                            cui = best_match_cui(all_results)
                            if cui == ""
                                println("Nothing!")
                                println(all_results)
                            end
                            all_concepts = get_semantic_types(tgt, cui)
                            for concept in all_concepts
                                push!(mesh, term)
                                push!(umls, concept)
                            end
                        end
                        break
                    catch err
                        @warn "! failed attempt $attempt out of 5 for term $term with error "  err
                    end
                end
            end
        end
    end

    return sort(unique(DataFrame(descriptor = mesh, concept = umls)))

end
