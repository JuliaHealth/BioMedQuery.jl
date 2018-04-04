@testset "MySQL BDUtils" begin
    
    using BioMedQuery
    using MySQL

    dbname="pubmed_test"

    const conn = DBUtils.init_mysql_database("127.0.0.1", "root", "", dbname)
    PubMed.create_tables!(conn)

    println(conn)

    #check collection of tables
    tables_query = DBUtils.select_all_tables(conn)
    tables = ["article","author","author2article","mesh_descriptor","mesh_heading","mesh_qualifier"]
    @test sort(tables) == sort(tables_query)

    #check minimum insert
    DBUtils.insert_row!(conn, "article", Dict(:pmid => 1234, :title=>"Test Article", :pubYear=>nothing))

    #check duplicate error insert
    duplicate_id = DBUtils.insert_row!(conn, "article", Dict(:pmid => 1234,
        :title=>"Test Article", :pubYear=>nothing))


    @test duplicate_id < 1
    sel = DBUtils.db_select(conn, ["pmid"], "article", Dict(:title=>"Test Article"))

    @test length(sel[1]) == 1
    @test sel[1][1] == 1234

    # #clean up
    MySQL.execute!(conn, "DROP DATABASE IF EXISTS $dbname;")
end
