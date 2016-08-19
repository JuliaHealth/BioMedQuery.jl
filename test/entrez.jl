
using DataFrames
using MySQL

#------------------ BioMedQuery -------------------
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
        println("-----------------------------------------")
        println("       Testing ESearch     ")

        search_term="obstructive sleep apnea[MeSH Major Topic]"
        search_dic = Dict("db"=>"pubmed","term" => search_term,
        "retstart" => 0, "retmax"=>narticles, "tool" =>"BioJulia",
        "email" => email)

        esearch_response = BioMedQuery.Entrez.esearch(search_dic)

        #convert xml to dictionary
        esearch_dict = BioMedQuery.Entrez.eparse(esearch_response)

        #examine how many ids were returned
        @test haskey(esearch_dict, "IdList")

        for id_node in esearch_dict["IdList"][1]["Id"]
            push!(ids, id_node)
        end

        @test length(ids)==narticles

    end

    @testset "Testing EFetch"    begin
        println("-----------------------------------------")
        println("       Testing EFetch      ")

        fetch_dic = Dict("db"=>"pubmed","tool" =>"BioJulia", "email" => email,
                         "retmode" => "xml", "rettype"=>"null")
        efetch_response = BioMedQuery.Entrez.efetch(fetch_dic, ids)
        efetch_dict = BioMedQuery.Entrez.eparse(efetch_response)


        @test haskey(efetch_dict, "PubmedArticle")

        articles = efetch_dict["PubmedArticle"]

        #articles should be an array of lenght narticles
        @test isa(articles, Array{Any, 1})
        @test length(articles) == narticles
    end

    # save the results of an entrez fetch to a sqlite database
    @testset "Testing SQLite Saving" begin
        println("-----------------------------------------")
        println("       Testing SQLite Saving")

        config = Dict(:db_path=> db_path, :overwrite=>true)
        db = BioMedQuery.Entrez.save_efetch_sqlite(efetch_dict, config)

        #query the article table and make sure the count is correct
        all_pmids = BioMedQuery.Entrez.DB.all_pmids_sqlite(db)
        @test length(all_pmids) == narticles

        #check we can get the MESH descriptor for an article
        mesh = BioMedQuery.Entrez.DB.get_article_mesh_sqlite(db, all_pmids[1])
        @test length(mesh) > 0
        
        #check that reminder of tables are not empty
        tables = ["author", "author2article", "mesh_descriptor",
        "mesh_qualifier", "mesh_heading"]

        for t in tables
            query_str = "SELECT count(*) FROM "*t*";"
            q = BioMedQuery.DBUtils.query_sqlite(db, query_str)
            count = get(q[1][1])
            @test count > 0
        end
    end


    @testset "Testing MySQL Saving" begin
        println("-----------------------------------------")
        println("       Testing MySQL Saving")

        config = Dict(:host=>"localhost", :dbname=>"test", :username=>"root",
        :pswd=>"", :overwrite=>true)
        db = BioMedQuery.Entrez.save_efetch_mysql(efetch_dict, config)

        #query the article table and make sure the count is correct
        all_pmids = BioMedQuery.Entrez.DB.all_pmids_mysql(db)
        @test length(all_pmids) == narticles

        #check we can get the MESH descriptor for an article
        mesh = BioMedQuery.Entrez.DB.get_article_mesh_mysql(db, all_pmids[1])
        @test length(mesh) > 0

        #check that reminder of tables are not empty
        tables = ["author", "author2article", "mesh_descriptor",
        "mesh_qualifier", "mesh_heading"]

        for t in tables
            query_str = "SELECT count(*) FROM "*t*";"
            q = BioMedQuery.DBUtils.query_mysql(db, query_str)
            count = q[1][1]
            @test count > 0
        end
    end

    @testset "Testing ELink" begin
        println("-----------------------------------------")
        println("       Testing ELink")

        pmid = "19304878"
        elink_dict = Dict("dbfrom" =>"pubmed", "id" => pmid,
                          "linkname" => "pubmed_pubmed", "email"=>email)
        elink_response = BioMedQuery.Entrez.elink(elink_dict)

        elink_response_dict = BioMedQuery.Entrez.eparse(elink_response)

        @test haskey( elink_response_dict, "LinkSet")
    end

    @testset "Testing ESummary" begin
        println("-----------------------------------------")
        println("       Testing ESummary")


        pmid = "30367"
        esummary_dict = Dict("db" =>"pubmed", "id" => pmid, "email"=>email)
        esummary_response = BioMedQuery.Entrez.esummary(esummary_dict)

        esummary_response_dict = BioMedQuery.Entrez.eparse(esummary_response)

        @test haskey( esummary_response_dict, "DocSum")
    end

    # remove temp files
    if isfile(db_path)
        rm(db_path)
    end
    println("------------End Test Entrez--------------")
    println("-----------------------------------------")

end
