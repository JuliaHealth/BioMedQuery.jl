import HTTP

#************************ LOCALS TO CONFIGURE!!!! **************************
const email= "" #This is an enviroment variable that you need to setup
const search_term="(obesity[MeSH Major Topic]) AND (\"2010\"[Date - Publication] : \"2012\"[Date - Publication])"
const max_articles = 2
const overwrite_db=true
const verbose = false
const umls_user = get(ENV, "UMLS_USER", "")
const umls_pswd = get(ENV, "UMLS_PSSWD", "")
#************************ SQLite **************************

const conn_sql = SQLite.DB()
PubMed.create_tables!(conn_sql)

@testset "Save and Search" begin

    println("-----------------------------------------")
    println("       Testing Search and Save")

    pubmed_search_and_save!(email, search_term, max_articles,
    conn_sql, verbose)
    #query the article table and make sure the count is correct
    all_pmids = BioMedQuery.PubMed.all_pmids(conn_sql)
    @test length(all_pmids) == max_articles

end

global credentials_set = get(ENV, "TRAVIS_SECURE_ENV_VARS", "true")=="true" && umls_user != ""

@testset "UMLS" begin

    if credentials_set
        println("-----------------------------------------")
        println("       Testing MESH2UMLS")

        append = false

        map_mesh_to_umls_async!(conn_sql, umls_user, umls_pswd; append_results=append, timeout=1)

        all_pairs_query = db_query(conn_sql, "SELECT mesh FROM mesh2umls;")
        all_pairs = all_pairs_query[1]
        @test length(all_pairs) > 0


        println("-----------------------------------------")
        println("       Testing Occurrences")
        umls_concept = "Disease or Syndrome"

        labels2ind, occur = umls_semantic_occurrences(conn_sql, umls_concept)

        @test length(keys(labels2ind)) > 0
        @test length(findall(x->x=="Obesity", collect(keys(labels2ind)))) ==1
    else
        @warn "Skipping UMLS tests as no credentials provided"
    end

end

println("------------End Test Processes SQLite-----------")
println("------------------------------------------------")
