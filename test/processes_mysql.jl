using LightXML
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
const host=MYSQL_HOST #If want to hide - use enviroment variables instead
const mysql_usr=MYSQL_USER
const mysql_pswd=MYSQL_PASSWORD
const dbname="pubmed_processes_test"
const dbname_pmid ="pmid_processes_test"
const medline_file = 1
const medline_year = 2019
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

    conn_pmid = DBUtils.init_mysql_database(host, mysql_usr, mysql_pswd, dbname_pmid)
    PubMed.create_pmid_table!(conn_pmid)
    pubmed_pmid_search_and_save!(email, search_term, max_articles, conn_pmid, verbose)

    #query the article table and make sure the count is correct
    all_pmids = BioMedQuery.PubMed.all_pmids(conn_pmid)
    @test length(all_pmids) == max_articles

    MySQL.disconnect(conn_pmid)

end

credentials_set = get(ENV, "TRAVIS_SECURE_ENV_VARS", "true")=="true" && umls_user != ""

@testset "UMLS" begin

    if credentials_set
        println("-----------------------------------------")
        println("       Testing MESH2UMLS")
        append = false

        map_mesh_to_umls_async!(conn, umls_user, umls_pswd; append_results=append, timeout=1)
        all_pairs_query = db_query(conn, "SELECT mesh FROM mesh2umls;")
        all_pairs = all_pairs_query[:mesh]
        @test length(all_pairs) > 0

        println("-----------------------------------------")
        println("       Testing Occurrences")
        umls_concept = "Disease or Syndrome"

        labels2ind, occur = umls_semantic_occurrences(conn, umls_concept)

        @test length(keys(labels2ind)) > 0
        @test length(findall(x->x=="Obesity", collect(keys(labels2ind)))) ==1
    else
        @warn "Skipping UMLS tests as no credentials provided"
    end
end

@testset "Medline Load" begin
    println("-----------------------------------------")
    println("       Testing Medline Loader")

    PubMed.create_tables!(conn) #drop and re-create pubmed article tables

    load_medline!(conn, @__DIR__, start_file=medline_file, end_file=medline_file, year=medline_year, test=true)

    path = joinpath(@__DIR__,"medline","raw_files",Processes.get_file_name(medline_file, medline_year, true))
    doc = parse_file(path)

    raw_articles = root(doc)

    all_pmids = PubMed.all_pmids(conn)
    @test length(all_pmids) == length(get_elements_by_tagname(raw_articles, "PubmedArticle"))
    res = MySQL.Query(conn, "SELECT DISTINCT orcid FROM author_ref;") |> DataFrame
    @test size(res)[1] > 2

    rm(joinpath(dirname(@__FILE__),"medline"), recursive=true)

end

MySQL.disconnect(conn)
mysql_conn = MySQL.connect(host, mysql_usr, mysql_pswd)
MySQL.execute!(mysql_conn, "DROP DATABASE IF EXISTS $dbname;")
MySQL.execute!(mysql_conn, "DROP DATABASE IF EXISTS $dbname_pmid;")
MySQL.disconnect(mysql_conn)


println("------------End Test Processes MySQL-----------")
println("-----------------------------------------------")
