#************************ LOCALS TO CONFIGURE!!!! **************************
const email= "" #This is an enviroment variable that you need to setup
const search_term="(obesity[MeSH Major Topic]) AND (\"2010\"[Date - Publication] : \"2012\"[Date - Publication])"
const max_articles = 2
const overwrite_db=true
const verbose = false
#************************ SQLite **************************
const db_path="./test_processes.sqlite"
#***************************************************************************

if isfile(db_path)
    rm(db_path)
end 

const conn_sql = SQLite.DB(db_path)
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

@testset "MESH2UMLS" begin
    println("-----------------------------------------")
    println("       Testing MESH2UMLS")
    umls_user = ENV["UMLS_USER"]
    umls_pswd = ENV["UMLS_PSSWD"]
    append = false

    @time begin
        map_mesh_to_umls_async!(conn_sql, umls_user, umls_pswd; append_results=append)
    end

    all_pairs_query = db_query(conn_sql, "SELECT mesh FROM mesh2umls;")
    all_pairs = all_pairs_query[1]
    @test length(all_pairs) > 0

    @time begin
        map_mesh_to_umls!(conn_sql, umls_user, umls_pswd; append_results=append)
    end

    all_pairs_query = db_query(conn_sql, "SELECT mesh FROM mesh2umls;")
    all_pairs = all_pairs_query[1]
    @test length(all_pairs) > 0
end

@testset "Occurrences" begin

    println("-----------------------------------------")
    println("       Testing Occurrences")
    umls_concept = "Disease or Syndrome"
    @time begin
        labels2ind, occur = umls_semantic_occurrences(conn_sql, umls_concept)
    end

    @test length(keys(labels2ind)) > 0
    @test length(find(x->x=="Obesity", collect(keys(labels2ind)))) ==1
end

# remove temp files
if isfile(db_path)
    rm(db_path)
end
println("------------End Test Processes SQLite-----------")
println("------------------------------------------------")
