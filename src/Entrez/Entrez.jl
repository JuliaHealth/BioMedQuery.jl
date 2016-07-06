# Interface to NCBI Entrez utilities
# http://www.ncbi.nlm.nih.gov/books/NBK25497/
# Date: May 6, 2016
# Authors: Isabel Restrepo, Paul Stey
# BCBI - Brown University
# Version: Julia 0.4.5
module Entrez

using Requests
using LightXML
using HttpCommon

using  XMLconvert

include("EntrezDB.jl")
using .DB

export esearch, efetch, eparse, save_efetch

function esearch(search_dic)
    # Seach Entrez database
    cgi = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
    variables = Dict("db"=>"db")
    variables = merge(variables, search_dic)
    # return variables
    return open_entrez(cgi, variables, false)
end


# Helper function to build the url and open a handle to it
# Uses HTTP POST instead of GET for long queries
function open_entrez(cgi, params, post=false)
    if get(params, "tool", "") == ""
        params["tool"] = "BioJulia"
    end
    if get(params, "email", "") == ""
        error("Email address is required to search Entrez")
    end
    #open a handle to Entrez
    if post
        response = Requests.post(cgi; data=params)

    else
        response = Requests.get(cgi; query=params)
    end

    println("NCBI Response: ", STATUS_CODES[response.status])

    if response.status != 200
        error("Bad response from NCBI ENTREZ")
    end

    # convert binary xml data to ascii
    return ASCIIString(response.data)
end

function efetch(fetch_dic, id_list)
    post = false
    cgi = "http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"
    # NCBI prefers an HTTP POST instead of an HTTP GET if there are
    # more than about 200 IDs
    if length(id_list) > 200
        post = true
    end
    id_list = join(id_list,",")
    variables = Dict("db"=>"db", "id"=>id_list)
    variables = merge(variables, fetch_dic)
    return open_entrez(cgi, variables,  post)
end

function eparse(response)
    xdoc = parse_string(response)

    # get the root element
    xroot = root(xdoc)  # an instance of XMLElement
    # get all child nodes and append to dictionary
    node_element = xroot
    #convert attributes to elements
    attributes_to_elements!(xroot)
    #convert to a dictionary
    dict = xml2dict(xroot)
    return dict
end

#save the results (dictionary) of an entrez fetch to a SQlite databass
function save_efetch(efetch_dict, path)
    #init database with its structure only if file doesn't exist
    db = DB.init_database(path)


    #Create database file
    # db = SQLite.DB(path)
    #for each article save related info

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

        pmid = DB.NULL;
        title = DB.NULL;
        pubYear = DB.NULL;


        # PMID is used as primary key - therefore it must be present
        if haskey(article["MedlineCitation"][1],"PMID")
            pmid = article["MedlineCitation"][1]["PMID"][1]["PMID"][1]
        else
            println("Error: Could not save to DB key:PMID not found - cannot be NULL")
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
            DB.insert_row(db, "article", Dict(:pmid => pmid,
            :title=>title,
            :pubYear=>pubYear))

            # insert all authors
            forename = DB.NULL
            lastname = DB.NULL
            if haskey(article["MedlineCitation"][1]["Article"][1], "AuthorList")
                authors = article["MedlineCitation"][1]["Article"][1]["AuthorList"][1]["Author"]
                for author in authors

                    if author["ValidYN"][1] == "N"
                        continue
                    end

                    if haskey(author, "ForeName")
                        forename = author["ForeName"][1]
                    end
                    if haskey(author, "LastName")
                        lastname = author["LastName"][1]
                    end
                    # Save author data
                    author_id = DB.insert_row(db, "author",
                    Dict(:id => DB.NULL,
                    :forename => forename,
                    :lastname => lastname))

                    # TO DO: Author insertion may have failed because of
                    # puplicate - this doesn't mean that relationship
                    # shoulden't be created
                    if (author_id >= 0 )
                        DB.insert_row(db, "author2article",
                        Dict(:aid =>author_id, :pmid => pmid))
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

                        DB.insert_row(db, "mesh_descriptor",
                        Dict(:id=>did_int, :name=>descriptor_name))

                        heading["DescriptorName"][1]["MajorTopicYN"][1] == "Y" ? dmjr = 1 : dmjr = 0


                        #save the qualifiers
                        if haskey(heading,"QualifierName")
                            qualifiers = heading["QualifierName"]
                            for qual in qualifiers
                                qualifier_name = qual["QualifierName"][1]
                                qualifier_name = normalize_string(qualifier_name, casefold=true)

                                qid = qual["UI"][1]
                                qid_int = parse(Int64, qid[2:end])  #remove preceding Q

                                DB.insert_row(db, "mesh_qualifier",
                                Dict(:id=>qid_int, :name=>qualifier_name) )

                                qual["MajorTopicYN"][1] == "Y" ? qmjr = 1 : qmjr = 0

                                #save the heading related to this paper
                                DB.insert_row(db, "mesh_heading",
                                Dict(:id=>DB.NULL, :pmid=> pmid, :did=>did_int,
                                :qid=>qid_int, :dmjr=>dmjr, :qmjr=>qmjr) )
                            end
                        else
                            #save the heading related to this paper
                            DB.insert_row(db, "mesh_heading",
                            Dict(:id=>DB.NULL, :pmid=> pmid, :did=>did_int,
                            :qid=>DB.NULL, :dmjr=>dmjr, :qmjr=>DB.NULL) )
                        end
                    end
                end
            end

        end

    end

    return db

end
end
