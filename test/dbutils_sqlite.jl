using SQLite

@testset "SQLite BDUtils" begin

    db_path = "test_db.sqlite"
    conn = SQLite.DB(db_path)
    PubMed.create_tables!(conn)

    #check collection of tables
    tables_query = DBUtils.select_all_tables(conn)
    tables = ["article","author","author2article","mesh_descriptor","mesh_heading","mesh_qualifier", "sqlite_sequence"]
    @test sort(tables) == sort(tables_query)


    #check minimum insert
    DBUtils.insert_row!(conn, "article", Dict(:pmid => 1234, :title=>"Test Article", :pubYear=>nothing))

    sel = DBUtils.db_select(conn, ["pmid"], "article", Dict(:title=>"Test Article", :pmid=>1234))

    @test length(sel[1]) == 1
    @test sel[1][1] == 1234

    if isfile(db_path)
        rm(db_path)
    end
end
