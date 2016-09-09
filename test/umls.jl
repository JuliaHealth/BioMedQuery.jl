
using BioMedQuery.UMLS

user= ""
psswd = ""
try
    user = ENV["UMLS_USER"]
    psswd = ENV["UMLS_PSSWD"]
catch
    println("UMLS tests require the following enviroment variables:")
    println("UMLS_USER")
    println("UMLS_PSSWD")
end

credentials = Credentials(user, psswd)
term = "obesity"
query = Dict("string"=>term, "searchType"=>"exact" )


@testset "Testing UMLS" begin
    tgt = get_tgt(credentials)
    all_results= search_umls(tgt, query)
    @test length(all_results[1]["result"]["results"]) == 2
    cui = best_match_cui(all_results)
    @test cui == "C0028754"
    sm = get_semantic_type(tgt, cui)
    @test sm[1] == "Disease or Syndrome"
end
