using BioMedQuery.Processes

const email= ""
#Enviroment variable that need to be setup
const umls_user = get(ENV, "UMLS_USER", "")
const umls_pswd = get(ENV, "UMLS_PSSWD", "")
const search_term="(obesity[MeSH Major Topic]) AND (\"2010\"[Date - Publication])"
const max_articles = 2
const verbose = false

dfs = DataFrame()

@testset "Search and Parse" begin
    println("-----------------------------------------")
    println("       Testing Search and Parse")

    dfs = pubmed_search_and_parse(email, search_term, max_articles, verbose)

    @test size(dfs["basic"])[1] == max_articles

end

@testset "UMLS DataFrames" begin
    println("-----------------------------------------")
    println("       Testing MESH2UMLS")
    m2u = map_mesh_to_umls(dfs["mesh_desc"], umls_user, umls_pswd)

    @test size(m2u)[1] > length(dfs["mesh_desc"])

    m2u = map_mesh_to_umls(dfs["mesh_desc"], umls_user, umls_pswd)

    @test size(m2u)[1] > length(dfs["mesh_desc"])

    println("-----------------------------------------")
    println("       Testing Occurences")

    umls_concept = "Disease or Syndrome"

    labels2ind, occur = umls_semantic_occurrences(dfs, m2u, umls_concept)

    @test length(keys(labels2ind)) > 0
    @test length(find(x->x=="Obesity", collect(keys(labels2ind)))) ==1

end
