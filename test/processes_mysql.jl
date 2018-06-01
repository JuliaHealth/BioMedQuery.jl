using EzXML
import HTTP

#************************ LOCALS TO CONFIGURE!!!! **************************
const email= ""
#Enviroment variable that need to be setup
const umls_user = get(ENV, "UMLS_USER", "")
const umls_pswd = get(ENV, "UMLS_PSSWD", "")
const search_term="(obesity[MeSH Major Topic]) AND (\"2010\"[Date - Publication])"
const max_articles = 2
const overwrite_db=true
const verbose = false


#************************ MYSQL **********************************************
const host="127.0.0.1" #If want to hide - use enviroment variables instead
const mysql_usr="root"
const mysql_pswd=""
const dbname="pubmed_processes_test"
const dbname_pmid ="pmid_processes_test"
const medline_file = 1
const medline_year = 2018
#*****************************************************************************

const conn = DBUtils.init_mysql_database(host, mysql_usr, mysql_pswd, dbname)
PubMed.create_tables!(conn)

@testset "Search and Save" begin
    println("-----------------------------------------")
    println("       Testing Search and Save")

    pubmed_search_and_save!(email, search_term, max_articles,
    conn, verbose)


    #query the article table and make sure the count is correct
    all_pmids = PubMed.all_pmids(conn)
    @test length(all_pmids) == max_articles

    const conn_pmid = DBUtils.init_mysql_database(host, mysql_usr, mysql_pswd, dbname_pmid)
    PubMed.create_pmid_table!(conn_pmid)
    pubmed_pmid_search_and_save!(email, search_term, max_articles, conn_pmid, verbose)

    #query the article table and make sure the count is correct
    all_pmids = BioMedQuery.PubMed.all_pmids(conn_pmid)
    @test length(all_pmids) == max_articles

    MySQL.disconnect(conn_pmid)

end

# If this is a Travis build and is a PR, then $TRAVIS_PULL_REQUEST is equal to the PR number.
# If this is a Travis build and is not a PR, then $TRAVIS_PULL_REQUEST is equal to "false".
# If this is not a Travis build, then $TRAVIS_PULL_REQUEST is unset.
is_not_travis_pull_request = get(ENV, "TRAVIS_PULL_REQUEST", "false") == "false"

@testset "MESH2UMLS" begin
    if is_not_travis_pull_request
        println("-----------------------------------------")
        println("       Testing MESH2UMLS")
        append = false

        success = true
        try
            @time begin
                map_mesh_to_umls_async!(conn, umls_user, umls_pswd; append_results=append, timeout=1)
            end
        catch e
            if isa(e, HTTP.ExceptionRequest.StatusError)
                warn(string("ignoring error: "), e)
                success = false
            else
                rethrow(e)
            end
        end
        if success
            all_pairs_query = db_query(conn, "SELECT mesh FROM mesh2umls;")
            all_pairs = all_pairs_query[1]
            @test length(all_pairs) > 0
        end

        success = true
        try
            @time begin
                map_mesh_to_umls!(conn, umls_user, umls_pswd; append_results=append, timeout=1)
            end
        catch e
            if isa(e, HTTP.ExceptionRequest.StatusError)
                warn(string("ignoring error: "), e)
                success = false
            else
                rethrow(e)
            end
        end
        if success
            all_pairs_query = db_query(conn, "SELECT mesh FROM mesh2umls;")
            all_pairs = all_pairs_query[1]
            @test length(all_pairs) > 0
        end
    end
end

@testset "Occurrences" begin
    if is_not_travis_pull_request
        println("-----------------------------------------")
        println("       Testing Occurrences")
        umls_concept = "Disease or Syndrome"

        success = true
        try
            @time begin
                labels2ind, occur = umls_semantic_occurrences(conn, umls_concept)
            end
        catch e
            if isa(e, HTTP.ExceptionRequest.StatusError)
                warn(string("ignoring error: "), e)
                success = false
            else
                rethrow(e)
            end
        end
        if success
            @test length(keys(labels2ind)) > 0
            @test length(find(x->x=="Obesity", collect(keys(labels2ind)))) ==1
        end
    end
end

@testset "Medline Load" begin
println("-----------------------------------------")
println("       Testing Medline Loader")

    PubMed.create_tables!(conn) #drop and re-create pubmed article tables

    load_medline(conn, dirname(@__FILE__), start_file=medline_file, end_file=medline_file, year=medline_year, test=true)

    path = joinpath(dirname(@__FILE__),"medline","raw_files",Processes.get_file_name(medline_file, medline_year, true))
    doc = EzXML.readxml(path)

    raw_articles = EzXML.root(doc)

    all_pmids = PubMed.all_pmids(conn)
    @test length(all_pmids) == countelements(raw_articles)
    res = MySQL.query(conn, "SELECT DISTINCT orcid FROM author_ref;", DataFrame)
    @test size(res)[1] > 2

    rm(joinpath(dirname(@__FILE__),"medline"), recursive=true)

end

@testset "Search and Parse" begin
    println("-----------------------------------------")
    println("       Testing Search and Parse")

    dfs = pubmed_search_and_parse(email, search_term, max_articles, verbose)

    @test size(dfs["basic"])[1] == max_articles

end

MySQL.disconnect(conn)
mysql_conn = MySQL.connect(host, mysql_usr, mysql_pswd)
MySQL.execute!(mysql_conn, "DROP DATABASE IF EXISTS $dbname;")
MySQL.execute!(mysql_conn, "DROP DATABASE IF EXISTS $dbname_pmid;")
MySQL.disconnect(mysql_conn)


println("------------End Test Processes MySQL-----------")
println("-----------------------------------------------")
