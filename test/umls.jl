
using BioMedQuery.UMLS
using BioMedQuery.DBUtils

# user= ""
# psswd = ""
# try
#     user = ENV["UMLS_USER"]
#     psswd = ENV["UMLS_PSSWD"]
# catch
#     println("UMLS tests require the following enviroment variables:")
#     println("UMLS_USER")
#     println("UMLS_PSSWD")
# end

# credentials = Credentials(user, psswd)
# term = "obesity"
# query = Dict("string"=>term, "searchType"=>"exact" )


# @testset "Testing UMLS" begin
#     tgt = get_tgt(credentials)
#     all_results= search_umls(tgt, query)
#     @test length(all_results[1]["result"]["results"]) == 2
#     cui = best_match_cui(all_results)
#     @test cui == "C0028754"
#     sm = get_semantic_type(tgt, cui)
#     @test sm[1] == "Disease or Syndrome"
# end


@testset "Populate Semantic Network" begin

    host="localhost"
    username="root"
    password=""
    umls_sn_dbname="umls_sn_test"
    overwrite_db=true

    db_config = Dict(:host=>host,
                     :dbname=>umls_sn_dbname,
                     :username=>username,
                     :pswd=>password,
                     :overwrite=>overwrite_db)
    umls_sn_db = populate_net_mysql(db_config)

    #check collection of tables
    tables_query = BioMedQuery.DBUtils.select_all_tables(umls_sn_db)
    tables = ["SRDEF","SRFIL","SRFLD","SRSTR","SRSTRE1","SRSTRE2"]
    @test sort(tables) == sort(tables_query)

    db_query(umls_sn_db, "DROP DATABASE IF EXISTS $umls_sn_dbname;")

end
