

#------------------ NLM -------------------
@testset "Testing Entrez" begin

    #testset "globals"
    narticles = 10
    email=""
    ids = []
    efetch_dict = Dict()
    db_path = "./test_db.db"

    try
        email = ENV["NCBI_EMAIL"]
    catch
        println("Entrez tests require the following enviroment variables:")
        println("NCBI_EMAIL")
    end

    @testset "Testing ESearch" begin
        search_term="obstructive sleep apnea[MeSH Major Topic]"
        search_dic = Dict("db"=>"pubmed","term" => search_term,
        "retstart" => 0, "retmax"=>narticles, "tool" =>"BioJulia",
        "email" => email)

        esearch_response = NLM.Entrez.esearch(search_dic)

        #convert xml to dictionary
        esearch_dict = NLM.Entrez.eparse(esearch_response)

        #examine how many ids were returned
        @test haskey(esearch_dict, "IdList")

        for id_node in esearch_dict["IdList"][1]["Id"]
            push!(ids, id_node)
        end

        @test length(ids)==narticles

    end

    @testset "Testing EFetch"    begin
        fetch_dic = Dict("db"=>"pubmed","tool" =>"BioJulia", "email" => email,
                         "retmode" => "xml", "rettype"=>"null")
        efetch_response = NLM.Entrez.efetch(fetch_dic, ids)
        efetch_dict = NLM.Entrez.eparse(efetch_response)


        @test haskey(efetch_dict, "PubmedArticle")

        articles = efetch_dict["PubmedArticle"]

        #articles should be an array of lenght narticles
        @test isa(articles, Array{Any, 1})
        @test length(articles) == narticles
    end

    # save the results of an entrez fetch to a sqlite database
    @testset "Testing SQLite Saving" begin
        db = NLM.Entrez.save_efetch(efetch_dict, db_path)

        #query the article table and make sure the count is correct
        so = SQLite.Source(db,"SELECT pmid FROM article;")
        ds = DataStreams.Data.stream!(so, DataStreams.Data.Table)

        #get the array of terms - is there a better way?
        all_pmids =ds.data[1]
        @test length(all_pmids) == narticles

        #check that reminder of tables are not empty
        tables = ["author", "author2article", "mesh_descriptor",
        "mesh_qualifier", "mesh_heading"]

        for t in tables
            query_str = "SELECT count(*) FROM "*t*";"
            so = SQLite.Source(db, query_str)
            ds = DataStreams.Data.stream!(so, DataStreams.Data.Table)
            count = get(ds.data[1][1])
            @test count > 0
        end
    end

    @testset "Testing ELink" begin
        pmid = "19304878"
        elink_dict = Dict("dbfrom" =>"pubmed", "id" => pmid,
                          "linkname" => "pubmed_pubmed", "email"=>email)
        elink_response = NLM.Entrez.elink(elink_dict)

        elink_response_dict = NLM.Entrez.eparse(elink_response)

        @test haskey( elink_response_dict, "LinkSet")
    end

    @testset "Testing ESummary" begin
        pmid = "30367"
        esummary_dict = Dict("db" =>"pubmed", "id" => pmid, "email"=>email)
        esummary_response = NLM.Entrez.esummary(esummary_dict)

        esummary_response_dict = NLM.Entrez.eparse(esummary_response)

        @test haskey( esummary_response_dict, "DocSum")
    end

    #remove temp files
    if isfile(db_path)
        rm(db_path)
    end

end
