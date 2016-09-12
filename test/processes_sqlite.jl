using BioMedQuery.Processes
using BioMedQuery.Entrez
using BioMedQuery.Entrez.DB
using BioMedQuery.DBUtils

using SQLite
using BioMedQuery.UMLS

#************************ LOCALS TO CONFIGURE!!!! **************************
email= ENV["NCBI_EMAIL"] #This is an enviroment variable that you need to setup
search_term="(obesity[MeSH Major Topic]) AND (\"2010\"[Date - Publication] : \"2012\"[Date - Publication])"
max_articles = 10
overwrite_db=true
verbose = false
#************************ SQLite **************************
db_path="./pubmed_save_and_search_test.db"
#***************************************************************************

db = nothing

@testset "Save and Search" begin

    println("-----------------------------------------")
    println("       Testing Search and Save")
    db_config = Dict(:db_path=>db_path,
                     :overwrite=>overwrite_db)
    db = pubmed_search_and_save(email, search_term, max_articles,
    save_efetch_sqlite, db_config, verbose)
    #query the article table and make sure the count is correct
    all_pmids = BioMedQuery.Entrez.DB.all_pmids(db)
    @test length(all_pmids) == max_articles

end

@testset "MESH2UMLS" begin
    println("-----------------------------------------")
    println("       Testing MESH2UMLS")
    user = ENV["UMLS_USER"]
    psswd = ENV["UMLS_PSSWD"]
    credentials = Credentials(user, psswd)
    append = false

    @time begin
        map_mesh_to_umls!(db, credentials; append_results=append)
    end

    all_pairs_query = db_query(db, "SELECT mesh FROM mesh2umls;")
    all_pairs = all_pairs_query[1].values
    @test length(all_pairs) > 0
    println(typeof(all_pairs))
    @test isa(all_pairs, Array{UTF8String,1})
end

@testset "Occurrences" begin

    println("-----------------------------------------")
    println("       Testing Occurrences")
    umls_concept = "Disease or Syndrome"
    @time begin
        labels2ind, occur = umls_semantic_occurrences(db, umls_concept)
    end

    @test length(keys(labels2ind)) > 0
    @test length(find(x->x=="obesity", collect(keys(labels2ind)))) ==1
end

# remove temp files
if isfile(db_path)
    rm(db_path)
end
println("------------End Test Processes SQLite-----------")
println("------------------------------------------------")
