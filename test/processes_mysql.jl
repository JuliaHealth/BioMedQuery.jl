using BioMedQuery.Processes
using BioMedQuery.Entrez
using BioMedQuery.Entrez.DB
using BioMedQuery.DBUtils

using MySQL
using BioMedQuery.UMLS

#************************ LOCALS TO CONFIGURE!!!! **************************
email= ENV["NCBI_EMAIL"] #Enviroment variable that need to be setup
umls_user = ENV["UMLS_USER"]
umls_pswd = ENV["UMLS_PSSWD"]
search_term="(obesity[MeSH Major Topic]) AND (\"2010\"[Date - Publication] : \"2012\"[Date - Publication])"
max_articles = 10
overwrite_db=true
verbose = false


#************************ MYSQL **********************************************
host="localhost" #If want to hide - use enviroment variables instead
mysql_usr="root"
mysql_pswd=""
dbname="pubmed_processes_test"
#*****************************************************************************

db = nothing

@testset "Search and Save" begin
    println("-----------------------------------------")
    println("       Testing Search and Save")
    db_config = Dict(:host=>host,
                     :dbname=>dbname,
                     :username=>mysql_usr,
                     :pswd=>mysql_pswd,
                     :overwrite=>overwrite_db)

    println()
    @time db = pubmed_search_and_save(email, search_term, max_articles,
    save_efetch_mysql, db_config, verbose)

    #query the article table and make sure the count is correct
    all_pmids = BioMedQuery.Entrez.DB.all_pmids(db)
    @test length(all_pmids) == max_articles

end

@testset "MESH2UMLS" begin
    println("-----------------------------------------")
    println("       Testing MESH2UMLS")
    credentials = Credentials(umls_user, umls_pswd)
    append = false

    @time begin
        map_mesh_to_umls_async!(db, credentials; append_results=append)
    end

    all_pairs_query = db_query(db, "SELECT mesh FROM mesh2umls;")
    all_pairs = all_pairs_query[1]
    @test length(all_pairs) > 0
    @test isa(all_pairs, DataArrays.DataArray{AbstractString,1})

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


db_query(db, "DROP DATABASE IF EXISTS $dbname;")

println("------------End Test Processes MySQL-----------")
println("-----------------------------------------------")
