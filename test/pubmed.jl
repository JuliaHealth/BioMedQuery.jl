using DataFrames
using MySQL
using BioServices.EUtils
using XMLDict

#------------------ BioMedQuery -------------------
    @testset "Testing Eutils/PubMed" begin
    #testset "globals"
    narticles = 10
    ids = Array{Int64,1}()
    efetch_dict = Dict()
    verbose = false
    articles = []

    @testset "Testing ESearch/EFetch PubMed" begin
        println("-----------------------------------------")
        println("       Testing ESearch/EFetch for PubMed     ")

        search_term="obstructive sleep apnea[MeSH Major Topic]"

        esearch_response = esearch(db="pubmed", term = search_term,
        retstart = 0, retmax = narticles, tool ="BioJulia")

        #convert xml to dictionary
        esearch_dict = parse_xml(String(esearch_response.data))

        #examine how many ids were returned
        @test haskey(esearch_dict, "IdList")

        for id_node in esearch_dict["IdList"]["Id"]
            push!(ids, parse(Int64, id_node))
        end

        @test length(ids)==narticles


        efetch_response = efetch(db = "pubmed", tool = "BioJulia", retmode = "xml", rettype = "null", id = ids)

        #convert xml to dictionary
        efetch_dict = parse_xml(String(efetch_response.data))

        @test haskey(efetch_dict, "PubmedArticle")

        articles = efetch_dict["PubmedArticle"]

        # println("----------Efetch Dict---------------")
        # println(efetch_dict)
        # println("--------------------------")
        
        #articles should be an array of narticles
        @test length(articles) == narticles

    end

    @testset "Test Save PMID MySQL" begin
        println("-----------------------------------------")
        println("       Test Save PMID MySQL     ")
        dbname = "entrez_test"
        config = Dict(:host=>"127.0.0.1", :dbname=>dbname, :username=>"root",
        :pswd=>"", :overwrite=>true)
        con = PubMed.save_pmid_mysql(ids, config, false)

        #query the article table and make sure the count is correct
        all_pmids = BioMedQuery.PubMed.all_pmids(con)
        @test length(all_pmids) == narticles

    end

    @testset "Testing Citations" begin
        println("-----------------------------------------")
        println("       Testing Citations      ")
        #parse 1st article
        # art = BioMedQuery.PubMed.MedlineArticle(articles[1])
        # println(art)
        config = Dict(:type => "endnote", :output_file => "./citations_temp.endnote", :overwrite=>true)
        nsucceses = BioMedQuery.PubMed.save_article_citations(efetch_dict, config, verbose)


        #test that citations are the same as the ones already stored
        lines=[]
        open("./citations_temp.endnote") do f
           lines = readlines(f)
        end

        nlines = 0
        for li=1:length(lines)
            if contains(lines[li], "%0 Journal Article")
              nlines+=1
            end
        end

        @test nlines == nsucceses
        rm("./citations_temp.endnote")
    end

    # save the results of an entrez fetch to a sqlite database
    @testset "Testing SQLite Saving" begin
        println("-----------------------------------------")
        println("       Testing SQLite Saving")

        db_path = "./test_db.db"

        config = Dict(:db_path=> db_path, :overwrite=>true)
        db = BioMedQuery.PubMed.save_efetch_sqlite(efetch_dict, config, verbose)

        #query the article table and make sure the count is correct
        all_pmids = BioMedQuery.PubMed.all_pmids(db)
        @test length(all_pmids) == narticles

        #query the article table and make sure the count is correct
        all_abstracts = BioMedQuery.PubMed.abstracts(db)
        @test size(all_abstracts)[1] == narticles

        #check we can get the MESH descriptor for an article
        mesh = BioMedQuery.PubMed.get_article_mesh(db, all_pmids[1])
        @test length(mesh) > 0

        #check that reminder of tables are not empty
        tables = ["author", "author2article", "mesh_descriptor",
        "mesh_qualifier", "mesh_heading"]

        for t in tables
            query_str = "SELECT count(*) FROM "*t*";"
            q = BioMedQuery.DBUtils.db_query(db, query_str)
            count = get(q[1][1])
            @test count > 0
        end

        # remove temp files
        if isfile(db_path)
            rm(db_path)
        end
    end


    @testset "Testing MySQL Saving" begin
        println("-----------------------------------------")
        println("       Testing MySQL Saving")

        dbname = "entrez_test"
        config = Dict(:host=>"127.0.0.1", :dbname=>dbname, :username=>"root",
        :pswd=>"", :overwrite=>true)
        @time db = BioMedQuery.PubMed.save_efetch_mysql(efetch_dict, config, verbose)

        #query the article table and make sure the count is correct
        all_pmids = BioMedQuery.PubMed.all_pmids(db)
        @test length(all_pmids) == narticles

        #query the article table and make sure the count is correct
        all_abstracts = BioMedQuery.PubMed.abstracts(db)
        @test size(all_abstracts)[1] == narticles

        #check we can get the MESH descriptor for an article
        mesh = BioMedQuery.PubMed.get_article_mesh(db, all_pmids[1])
        # println(mesh)
        @test length(mesh) > 0

        #check that reminder of tables are not empty
        tables = ["author", "author2article", "mesh_descriptor",
        "mesh_qualifier", "mesh_heading"]

        for t in tables
            query_str = "SELECT count(*) FROM "*t*";"
            q = BioMedQuery.DBUtils.db_query(db, query_str)
            # println(q)
            # println(q[1])
            # println(q[1][1])
            count = q[1][1]
            @test count > 0
        end

        #clean-up
        db_query(db, "DROP DATABASE IF EXISTS $dbname;")

    end

    println("------------End Test Eutils/PubMed--------------")
    println("-----------------------------------------")

end
