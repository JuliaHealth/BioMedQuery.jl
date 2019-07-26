using BioMedQuery
using MySQL

@testset "MySQL BDUtils" begin

    dbname="pubmed_test"

    conn = DBUtils.init_mysql_database(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, dbname)
    PubMed.create_tables!(conn)

    println(conn)

    #check collection of tables
    tables_query = DBUtils.select_all_tables(conn)
    tables = ["basic","author_ref","mesh_desc","mesh_heading","mesh_qual","pub_type","abstract_structured","abstract_full","file_meta"]
    @test sort(tables) == sort(tables_query)

    #check minimum insert
    DBUtils.insert_row!(conn, "basic", Dict(:pmid => 1234, :title=>"Test Article", :pub_year=>nothing))

    #check duplicate error insert
    duplicate_id = DBUtils.insert_row!(conn, "basic", Dict(:pmid => 1234,
        :title=>"Test Article", :pub_year=>nothing))


    @test duplicate_id < 1
    sel = DBUtils.db_select(conn, ["pmid"], "basic", Dict(:title=>"Test Article"))

    @test length(sel[1]) == 1
    @test sel[1][1] == 1234

    # #clean up
    MySQL.execute!(conn, "DROP DATABASE IF EXISTS $dbname;")
end
