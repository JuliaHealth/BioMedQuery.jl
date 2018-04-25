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
        host = "127.0.0.1";
        user = "root"
        pwd = ""

        const conn = DBUtils.init_mysql_database(host, user, pwd, dbname)
        PubMed.create_pmid_table!(conn)
        PubMed.save_pmids!(conn, ids)

        #query the article table and make sure the count is correct
        all_pmids = BioMedQuery.PubMed.all_pmids(conn)
        @test length(all_pmids) == narticles

         #clean-up
         db_query(conn, "DROP DATABASE IF EXISTS $dbname;")

    end

    @testset "Testing Citations" begin
        println("-----------------------------------------")
        println("       Testing Citations      ")
        #parse 1st article
        # art = BioMedQuery.PubMed.MedlineArticle(articles[1])
        # println(art)
        citation = PubMed.CitationOutput("endnote", "./citations_temp.endnote", true)
        nsucceses = PubMed.save_efetch!(citation, efetch_dict, verbose)


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

    @testset "Test Save Article DataFrames" begin
        println("-----------------------------------------")
        println("       Test Save Article DataFrames     ")

        raw_articles = efetch_dict["PubmedArticle"]

        parsed_articles = map(x -> PubmedArticle(x), raw_articles)

        dfs = DBUtils.toDataFrames(parsed_articles)
        println(dfs)

        @test length(dfs["pubmedarticle"]) == narticles

    end

    # save the results of an entrez fetch to a sqlite database
    @testset "Testing SQLite Saving" begin
        println("-----------------------------------------")
        println("       Testing SQLite Saving")

        db_path = "./test_db.db"

        const conn = SQLite.DB(db_path)
        PubMed.create_tables!(conn)
        PubMed.save_efetch!(conn, efetch_dict)

        #query the article table and make sure the count is correct
        all_pmids = PubMed.all_pmids(conn)
        @test length(all_pmids) == narticles

        #query the article table and make sure the count is correct
        all_abstracts = PubMed.abstracts(conn)
        @test size(all_abstracts)[1] == narticles

        #check we can get the MESH descriptor for an article
        mesh = PubMed.get_article_mesh(conn, all_pmids[1])
        @test length(mesh) > 0

        #check that reminder of tables are not empty
        tables = ["author", "author2article", "mesh_descriptor",
        "mesh_qualifier", "mesh_heading"]

        for t in tables
            q = SQLite.query(conn, "SELECT count(*) FROM "*t*";")
            count = q[1][1]
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

        dbname = "efetch_test"
        host = "127.0.0.1";
        user = "root"
        pwd = ""

        const conn = DBUtils.init_mysql_database(host, user, pwd, dbname)
        PubMed.create_tables!(conn)
        @time PubMed.save_efetch!(conn, efetch_dict)

        #query the article table and make sure the count is correct
        all_pmids = PubMed.all_pmids(conn)
        @test length(all_pmids) == narticles

        #query the article table and make sure the count is correct
        all_abstracts = PubMed.abstracts(conn)
        @test size(all_abstracts)[1] == narticles

        #check we can get the MESH descriptor for an article
        mesh = PubMed.get_article_mesh(conn, all_pmids[1])
        # println(mesh)
        @test length(mesh) > 0

        #check that reminder of tables are not empty
        tables = ["author", "author2article", "mesh_descriptor",
        "mesh_qualifier", "mesh_heading"]

        for t in tables
            q = MySQL.query(conn, "SELECT count(*) FROM "*t*";")
            count = q[1][1]
            @test count > 0
        end

        #clean-up
        db_query(conn, "DROP DATABASE IF EXISTS $dbname;")

    end

    println("------------End Test Eutils/PubMed--------------")
    println("-----------------------------------------")

end
