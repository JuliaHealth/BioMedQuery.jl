using BioMedQuery.Entrez
using SQLite
using MySQL
using XMLconvert

"""
pubmed_search_and_save(email, search_term, article_max::Int64,
db_path, verbose=false)

###Arguments

* email: valid email address (otherwise pubmed will block you)
* search_term : search string to submit to PubMed
e.g (asthma[MeSH Terms]) AND ("2001/01/29"[Date - Publication] : "2010"[Date - Publication])
see http://www.ncbi.nlm.nih.gov/pubmed/advanced for help constructing the string
* article_max : maximum number of articles to return. Defaults to 600,000
* db_path: path to output database
* verbose: if true, the NCBI xml response files are saved to current directory
"""
function pubmed_search_and_save(email, search_term::String, article_max,
    save_efetch_func, db_config, verbose=false)

    retstart = 0
    retmax = 10000  #e-utils only allows 10,000 at a time
    article_max = article_max

    if article_max < retmax
        retmax = article_max
    end

    db = nothing
    article_total = 0

    for rs=retstart:retmax:(article_max- 1)

        rm = rs + retmax
        if rm > article_max
            retmax = article_max - rs
        end

        println("Getting ", retmax, " articles, starting at index ", rs)

        #1. Formulate PubMed/MEDLINE search for articles between 2000 and 201
        #with obesity indicated as the major MeSH descriptor.
        println("------Searching Entrez--------")
        search_dic = Dict("db"=>"pubmed","term" => search_term,
        "retstart" => rs, "retmax"=>retmax, "tool" =>"BioJulia",
        "email" => email)
        esearch_response = esearch(search_dic)

        if verbose
            xmlASCII2file(esearch_response, "./esearch.xml")
        end

        #convert xml to dictionary
        esearch_dict = eparse(esearch_response)

        #2. Obtain PubMed/MEDLINE records (in MEDLINE or XML format) for
        #formulated search using NCBI E-Utilities.
        println("------Fetching Entrez--------")
        fetch_dic = Dict("db"=>"pubmed","tool" =>"BioJulia", "email" => email,
        "retmode" => "xml", "rettype"=>"null")
        #get the list of ids and perfom a fetch
        if !haskey(esearch_dict, "IdList")
            println("Error with esearch_dict:")
            println(esearch_dict)
            error("Response esearch_dict does not contain IdList")
        end

        ids = []
        for id_node in esearch_dict["IdList"][1]["Id"]
            push!(ids, id_node)
        end

        efetch_response = efetch(fetch_dic, ids)

        if verbose
            xmlASCII2file(efetch_response, "./efetch.xml")
        end

        efetch_dict = eparse(efetch_response)

        #save the results of an entrez fetch to a sqlite database
        println("------Saving to database--------")
        db = save_efetch_func(efetch_dict, db_config, verbose)

        #after the first pass - make sure the database is not deleted
        db_config[:overwrite] = false

        article_total+=length(ids)

        if (length(ids) < retmax)
            break
        end

    end

    println("Finished searching, total number of articles: ", article_total)
    return db
end


"""
pubmed_search_and_save_mysql(email, search_term::String, article_max,
     con::MySQL.MySQLHandle, clean_efetch_tables = false, verbose=false)

###Arguments

* `email`: valid email address (otherwise pubmed will block you)
* `search_term` : search string to submit to PubMed
e.g (asthma[MeSH Terms]) AND ("2001/01/29"[Date - Publication] : "2010"[Date - Publication])
see http://www.ncbi.nlm.nih.gov/pubmed/advanced for help constructing the string
* `article_max` : maximum number of articles to return. Defaults to 600,000
* `con`: MySQL connection
* `clean_efetch_tables`: If true the pubmed/efetch related tables are cleaned/overwritten
* `verbose`: if true, the NCBI xml response files are saved to current directory
"""
function pubmed_search_and_save_mysql(email, search_term::String, article_max,
     con::MySQL.MySQLHandle, clean_efetch_tables = false, verbose=false)

    retstart = 0
    retmax = 10000  #e-utils only allows 10,000 at a time
    article_max = article_max

    if article_max < retmax
        retmax = article_max
    end

    all_pmids = Array{Int64}[]
    article_total = 0

    for rs=retstart:retmax:(article_max- 1)

        rm = rs + retmax
        if rm > article_max
            retmax = article_max - rs
        end

        # info("Getting ", retmax, " max articles, starting at index ", rs)

        #1. Formulate PubMed/MEDLINE search for articles between 2000 and 201
        #with obesity indicated as the major MeSH descriptor.
        println("------Searching Entrez--------")
        search_dic = Dict("db"=>"pubmed","term" => search_term,
        "retstart" => rs, "retmax"=>retmax, "tool" =>"BioMedQueryJL",
        "email" => email)
        esearch_response = esearch(search_dic)

        if verbose
            xmlASCII2file(esearch_response, "./esearch.xml")
        end

        #convert xml to dictionary
        esearch_dict = eparse(esearch_response)

        #2. Obtain PubMed/MEDLINE records (in MEDLINE or XML format) for
        #formulated search using NCBI E-Utilities.
        println("------Fetching Entrez--------")
        fetch_dic = Dict("db"=>"pubmed","tool" =>"BioJulia", "email" => email,
        "retmode" => "xml", "rettype"=>"null")
        #get the list of ids and perfom a fetch
        if !haskey(esearch_dict, "IdList")
            println("Error with esearch_dict:")
            println(esearch_dict)
            error("Response esearch_dict does not contain IdList")
        end

        ids = Array{typeof(esearch_dict["IdList"][1]["Id"][1])}[]
        println(esearch_dict["IdList"][1])
        try
            for id_node in esearch_dict["IdList"][1]["Id"]
                push!(ids, id_node)
            end
        catch
            warn("No Ids returned in currnt esearch")
        end

        efetch_response = efetch(fetch_dic, ids)

        if verbose
            xmlASCII2file(efetch_response, "./efetch.xml")
        end

        efetch_dict = eparse(efetch_response)

        #save the results of an entrez fetch to a sqlite database
        println("------Saving to database--------")
        all_pmids = save_efetch_mysql(efetch_dict, con, clean_efetch_tables, verbose)

        #after the first pass - make sure the tables are not cleaned
        clean_efetch_tables = false

        article_total+=length(ids)

        if (length(ids) < retmax)
            break
        end

    end

    println("Finished searching, total number of articles: ", article_total)
    return all_pmids
end


function pubmed_pmid_search(email, search_term::String, article_max, verbose=false)

     retstart = 0
     retmax = 10000  #e-utils only allows 10,000 at a time
     article_max = article_max

     if article_max < retmax
         retmax = article_max
     end

     all_pmids = Array{Int64,1}()
     article_total = 0

     for rs=retstart:retmax:(article_max- 1)

         rm = rs + retmax
         if rm > article_max
             retmax = article_max - rs
         end

         # info("Getting ", retmax, " max articles, starting at index ", rs)

         #1. Formulate PubMed/MEDLINE search for articles between 2000 and 201
         #with obesity indicated as the major MeSH descriptor.
         println("------Searching Entrez--------")
         search_dic = Dict("db"=>"pubmed","term" => search_term,
         "retstart" => rs, "retmax"=>retmax, "tool" =>"BioMedQueryJL",
         "email" => email)
         esearch_response = esearch(search_dic)

         if verbose
             xmlASCII2file(esearch_response, "./esearch.xml")
         end

         #convert xml to dictionary
         esearch_dict = eparse(esearch_response)

         #get the list of ids and perfom a fetch
         if !haskey(esearch_dict, "IdList")
             println("Error with esearch_dict:")
             println(esearch_dict)
             error("Response esearch_dict does not contain IdList")
         end

         ids = Array{Int64,1}()
         try
             println(esearch_dict["IdList"][1]["Id"])
             for id_node in esearch_dict["IdList"][1]["Id"]
                 push!(ids, id_node)
                 push!(all_pmids, id_node)
             end
         catch
             warn("No Ids returned in currnt esearch")
         end

         article_total+=length(ids)

         if (length(ids) < retmax)
             break
         end

     end

     println("Finished searching, total number of articles: ", article_total)
     return all_pmids
 end

function pubmed_pmid_search_and_save(email, search_term::String, article_max,
    save_pmid_func, db_config, verbose=false)

    pmids = pubmed_pmid_search(email, search_term, article_max, verbose)
    db = save_pmid_func(pmids, db_config, verbose)

    narticles = length(pmids)
    info("Finished saving $narticles articles")

end

"""
pubmed_search_and_save(email::String, pmids::Array{Int64},
    save_efetch_func, db_config, verbose=false)

###Arguments

* email: valid email address (otherwise pubmed will block you)
* pmid : list of pmids to retrieve info from PubMed
* save_efetch_func: save_efetch_mysql or save_efetch_sqlite
* db_config: e.g Dict(:host=>host,
                      :dbname=>dbname,
                      :username=>mysql_usr,
                      :pswd=>mysql_pswd,
                      :overwrite=>overwrite)
* verbose: if true, the NCBI xml response files are saved to current directory
"""
function pubmed_search_and_save{T <: AbstractArray}(email::String, pmids::T,
    save_efetch_func, db_config, verbose=false)

    fetch_dic = Dict("db"=>"pubmed", "tool" =>"BioJulia", "email" => email,
    "retmode" => "xml", "rettype"=>"null")
    efetch_response = efetch(fetch_dic, pmids)
    if verbose
        xmlASCII2file(efetch_response, "./efetch.xml")
    end
    efetch_dict = eparse(efetch_response)

    #save the results of an entrez fetch to database
    println("------Saving to database--------")
    db = save_efetch_func(efetch_dict, db_config, verbose)

    #after the first pass - make sure the database is not deleted
    db_config[:overwrite] = false

    return db

end
