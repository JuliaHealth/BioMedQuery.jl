using DataFrames
using MySQL
using BioServices.EUtils
using XMLDict
using LightXML
import Base.parse

#------------------ BioMedQuery -------------------
    @testset "Testing Eutils/PubMed" begin
    #testset "globals"
    narticles = 10
    ids = Array{Int64,1}()
    efetch_doc = ""
    dfs_efetch = Dict{String,DataFrame}()
    verbose = false
    articles = []

    @testset "Testing ESearch/EFetch PubMed" begin
        println("-----------------------------------------")
        println("       Testing ESearch/EFetch for PubMed     ")

        search_term="""(obstructive sleep apnea[MeSH Major Topic]) AND (journal article[Publication Type])"""

        esearch_response = esearch(db="pubmed", term = search_term,
        retstart = 0, retmax = narticles, tool ="BioJulia")

        #convert xml to dictionary
        esearch_dict = parse_xml(String(esearch_response.body))

        #examine how many ids were returned
        @test haskey(esearch_dict, "IdList")

        for id_node in esearch_dict["IdList"]["Id"]
            push!(ids, Base.parse(Int64, id_node))
        end

        @test length(ids)==narticles


        efetch_response = efetch(db = "pubmed", tool = "BioJulia", retmode = "xml", rettype = "null", id = ids)

        #convert xml to dictionary
        efetch_doc = root(parse_string(String(efetch_response.body)))
        dfs_efetch = PubMed.parse_articles(efetch_doc)

        @test name(efetch_doc) == "PubmedArticleSet"

        #articles should be an array of narticles
        @test narticles == length(collect(child_elements(efetch_doc)))

    end

    if !CI_SKIP_MYSQL

        @testset "Test Save PMID MySQL" begin
            println("-----------------------------------------")
            println("       Test Save PMID MySQL     ")
            dbname = "entrez_test"
            host = "127.0.0.1";
            user = "root"
            pwd = ""

            conn = DBUtils.init_mysql_database(host, user, pwd, dbname)
            PubMed.create_pmid_table!(conn)
            PubMed.save_pmids!(conn, ids)

            #query the article table and make sure the count is correct
            all_pmids = PubMed.all_pmids(conn)
            @test size(all_pmids)[1] == narticles

            #clean-up
            db_query(conn, "DROP DATABASE IF EXISTS $dbname;")

        end

        @testset "Testing MySQL Saving" begin
        println("-----------------------------------------")
        println("       Testing MySQL Saving")

        dbname = "efetch_test"
        host = "127.0.0.1";
        user = "root"
        pwd = ""

        conn = DBUtils.init_mysql_database(host, user, pwd, dbname)
        PubMed.create_tables!(conn)
        @time PubMed.save_efetch!(conn, efetch_doc, false, true)

        # query the df and db tables to make sure the count is correct
        for (table, df) in dfs_efetch
            query_res = db_query(conn, "select count(*) from $table")
            @test size(df)[1] == query_res[1][1]
        end

        #query the article table and make sure the count is correct
        all_pmids = PubMed.all_pmids(conn)
        @test length(all_pmids) == narticles

        #query the article table and make sure the count is correct
        all_abstracts = PubMed.abstracts(conn)
        @test size(all_abstracts)[1] >0 && size(all_abstracts)[1] <= narticles

        #check we can get the MESH descriptor for an article
        mesh = PubMed.get_article_mesh(conn, all_pmids[1])
        # println(mesh)
        @test length(mesh) > 0

        #check that reminder of tables are not empty
        tables = ["author_ref", "mesh_desc",
        "mesh_qual", "mesh_heading", "pub_type", "abstract_structured"]

        for t in tables
            q = MySQL.Query(conn, "SELECT count(*) FROM $t;") |> DataFrame
            count = q[1][1]
            @test count > 0
        end

        #clean-up
        db_query(conn, "DROP DATABASE IF EXISTS $dbname;")

    end

    end

    @testset "Testing Citations" begin
        println("-----------------------------------------")
        println("       Testing Citations      ")
        #parse 1st article
        # art = BioMedQuery.PubMed.MedlineArticle(articles[1])
        # println(art)
        citation = PubMed.CitationOutput("endnote", "./citations_temp.endnote", true)
        nsucceses = PubMed.save_efetch!(citation, efetch_doc, verbose)


        #test that citations are the same as the ones already stored
        lines=[]
        open("./citations_temp.endnote") do f
           lines = readlines(f)
        end

        nlines = 0
        for li=1:length(lines)
            if occursin("%0 Journal Article", lines[li])
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

        conn = SQLite.DB()
        PubMed.create_tables!(conn)
        PubMed.save_efetch!(conn, efetch_doc,false, true)

        # query the df and db tables to make sure the count is correct
        for (table, df) in dfs_efetch
            query_res = db_query(conn, "select count(*) from $table")
            @test size(df)[1] == query_res[1][1]
        end

        #query the article table and make sure the count is correct
        all_pmids = PubMed.all_pmids(conn)
        @test size(all_pmids)[1] == narticles

        #query the article table and make sure the count is correct
        all_abstracts = PubMed.abstracts(conn)
        @test size(all_abstracts)[1] >0 && size(all_abstracts)[1] <= narticles

        #check we can get the MESH descriptor for an article
        mesh = PubMed.get_article_mesh(conn, all_pmids[1])
        @test length(mesh) > 0

        #check that remainder of tables are not empty
        tables = ["author_ref", "mesh_desc",
        "mesh_qual", "mesh_heading", "pub_type", "abstract_structured"]

        for t in tables
            q = DataFrame(SQLite.Query(conn, "SELECT count(*) FROM "*t*";"))
            count = q[1][1]
            @test count > 0
        end
    end


    
    println("------------End Test Eutils/PubMed--------------")
    println("-----------------------------------------")

end
