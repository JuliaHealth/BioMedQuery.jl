include("entrez_db.jl")
using .DB
using ..DBUtils
using SQLite




# """
#     save_efetch(efetch_dict, db_path)
#
# Save the results (dictionary) of an entrez fetch to a SQLite database.
#
# ####Note:
#
# It is best to assure the databese file does not exist. If the file
# path corresponds to an exixting database, the system
# attempts to use that database, which must contain the correct tables.
#
# ###Example
#
# ```julia
# #SQLite example
# db_backend("SQLite")
# db_config = Dict(:db_path=>"test_db.slqite", :overwrite=>true)
# db = save_efetch(efetch_dict, db_config)
# ```
#
# """
for f in [:mysql, :sqlite]
    save_efetch_func = Symbol(string("save_efetch_", f))
    # insert_row_func = Symbol(string("insert_row_", f, "!"))
    init_db_func = Symbol(string("init_database_", f))
    # select_fun= Symbol(string("select_", f))
    # get_value_func= Symbol(string("get_value_", f))
    @eval begin
        function ($save_efetch_func)(efetch_dict, db_config, verbose=false)
            #init database with its structure only if file doesn't exist
            db = ($init_db_func)(db_config)

            if !haskey(efetch_dict, "PubmedArticle")
                println("Error: Could not save to DB key:PubmedArticleSet not found")
                return
            end
            articles = efetch_dict["PubmedArticle"]

            #articles should be an array
            if !isa(articles, Array{Any, 1})
                println("Error: Could not save to DB articles should be in an Array")
                return
            end

            println("Saving " , length(articles) ,  " articles to database")

            for article in articles

                if !haskey(article,"MedlineCitation")
                    println("Error: Could not save to DB key:MedlineCitation not found")
                    return
                end

                pmid = nothing;
                title = nothing;
                pubYear = nothing;


                # PMID is used as primary key - therefore it must be present
                if haskey(article["MedlineCitation"][1],"PMID")
                    pmid = article["MedlineCitation"][1]["PMID"][1]["PMID"][1]
                else
                    println("Error: Could not save to DB key:PMID not found - cannot be nothing")
                    return
                end

                # Retrieve basic article info
                if haskey(article["MedlineCitation"][1],"Article")
                    if haskey(article["MedlineCitation"][1]["Article"][1], "ArticleTitle")
                        title = article["MedlineCitation"][1]["Article"][1]["ArticleTitle"][1]
                    end
                    if haskey(article["MedlineCitation"][1]["Article"][1], "ArticleDate")
                        if haskey(article["MedlineCitation"][1]["Article"][1]["ArticleDate"][1], "Year")
                            pubYear = article["MedlineCitation"][1]["Article"][1]["ArticleDate"][1]["Year"][1]
                        end
                    else  #series of attempts to pull a publication year from alternative xml elements
                        try
                            pubYear = article["MedlineCitation"][1]["Article"][1]["Journal"][1]["JournalIssue"][1]["PubDate"][1]["Year"][1]
                        catch
                            try
                                pubYear = article["MedlineCitation"][1]["Article"][1]["Journal"][1]["JournalIssue"][1]["PubDate"][1]["MedlineDate"][1]
                                pubYear = parse(Int64, pubYear[1:4])
                            catch
                                println("Warning: No date found")
                            end
                        end
                    end

                    # Save article data
                    insert_row!(db, "article", Dict(:pmid => pmid,
                    :title=>title,
                    :pubYear=>pubYear), verbose)

                    # insert all authors
                    forename = nothing
                    lastname = nothing
                    if haskey(article["MedlineCitation"][1]["Article"][1], "AuthorList")
                        authors = article["MedlineCitation"][1]["Article"][1]["AuthorList"][1]["Author"]
                        for author in authors

                            if author["ValidYN"][1] == "N"
                                continue
                            end

                            if haskey(author, "ForeName")
                                forename = author["ForeName"][1]
                            else
                                forname = "Unknown"
                            end

                            if haskey(author, "LastName")
                                lastname = author["LastName"][1]
                            else
                                println("Skipping Author: ", author)
                                continue
                            end

                            # Authors must be unique - if inserting fails see if already exists

                            # Save author data
                            author_id = -1
                            try
                                author_id = insert_row!(db, "author",
                                Dict(:id => nothing,
                                :forename => forename,
                                :lastname => lastname), verbose)
                            catch
                                sel = db_select(db, ["id"], "author",
                                Dict(:forename => forename, :lastname => lastname))
                                if length(sel[1]) > 0
                                    author_id = get_value(sel[1][1])
                                    if verbose
                                        println("Author already in db: ", lastname, ", ", forename, " - id: ", author_id)
                                    end
                                else
                                    error("Can't save nor find Author: ", lastname, ", ", forename)
                                end

                            end

                            if (author_id >= 0 )
                                insert_row!(db, "author2article",
                                Dict(:aid =>author_id, :pmid => pmid), verbose)
                            else
                                error("Invalid ID for Author: ", lastname, ", ", forename)
                            end

                        end
                    end

                    # Save related "keywords" of MESH Descriptors
                    if haskey(article["MedlineCitation"][1], "MeshHeadingList")
                        if haskey(article["MedlineCitation"][1]["MeshHeadingList"][1], "MeshHeading")
                            mesh_headings = article["MedlineCitation"][1]["MeshHeadingList"][1]["MeshHeading"]
                            for heading in mesh_headings

                                if !haskey(heading,"DescriptorName")
                                    println("Error: MeshHeading must have DescriptorName")
                                    return
                                end

                                #save descriptor
                                descriptor_name = heading["DescriptorName"][1]["DescriptorName"][1]
                                descriptor_name = normalize_string(descriptor_name, casefold=true)

                                did = heading["DescriptorName"][1]["UI"][1]
                                did_int = parse(Int64, did[2:end])  #remove preceding D

                                #name of mesh descriptor must be unique
                                try
                                    insert_row!(db, "mesh_descriptor",
                                    Dict(:id=>did_int, :name=>descriptor_name), verbose)
                                catch
                                    try
                                        sel = db_select(db, ["id"], "mesh_descriptor",
                                        Dict(:name => descriptor_name))
                                        if get_value(sel[1][1]) != did_int
                                            error("Found matching descriptor but did is inconsistent")
                                        end
                                        if verbose
                                            println("Descriptor already in db: ", descriptor_name, " - did: ", did)
                                        end
                                    catch
                                        error("Can't insert nor find duplicate")
                                    end
                                end

                                heading["DescriptorName"][1]["MajorTopicYN"][1] == "Y" ? dmjr = 1 : dmjr = 0

                                #save the qualifiers
                                if haskey(heading,"QualifierName")
                                    qualifiers = heading["QualifierName"]
                                    for qual in qualifiers
                                        qualifier_name = qual["QualifierName"][1]
                                        qualifier_name = normalize_string(qualifier_name, casefold=true)

                                        qid = qual["UI"][1]
                                        qid_int = parse(Int64, qid[2:end])  #remove preceding Q

                                        try
                                            insert_row!(db, "mesh_qualifier",
                                            Dict(:id=>qid_int, :name=>qualifier_name), verbose )
                                        catch
                                            sel = db_select(db, ["id"], "mesh_qualifier",
                                            Dict(:name => qualifier_name))
                                            if get_value(sel[1][1]) != qid_int
                                                error("Found matching qualifier but qid is inconsistent")
                                            end
                                            if verbose
                                                println("Qualifier already in DB: ", qualifier_name, " - qid: ", qid)
                                            end
                                        end

                                        qual["MajorTopicYN"][1] == "Y" ? qmjr = 1 : qmjr = 0

                                        #save the heading related to this paper
                                        insert_row!(db, "mesh_heading",
                                        Dict(:id=>nothing, :pmid=> pmid, :did=>did_int,
                                        :qid=>qid_int, :dmjr=>dmjr, :qmjr=>qmjr), verbose )

                                    end
                                else
                                    #save the heading related to this paper
                                    insert_row!(db, "mesh_heading",
                                    Dict(:id=>nothing, :pmid=> pmid, :did=>did_int,
                                    :qid=>nothing, :dmjr=>dmjr, :qmjr=>nothing), verbose )
                                end
                            end
                        end
                    end

                end

            end

            return db

        end
    end
end
