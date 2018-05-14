using SQLite

@testset "SQLite DBUtils" begin

    db_path = "test_db.sqlite"
    conn = SQLite.DB(db_path)
    PubMed.create_tables!(conn)

    #check collection of tables
    tables_query = DBUtils.select_all_tables(conn)
    tables = ["basic","author_ref","mesh_desc","mesh_heading","mesh_qual","pub_type","abstract_structured","abstract_full","file_meta", "sqlite_sequence"]
    @test sort(tables) == sort(tables_query)


    #check minimum insert
    DBUtils.insert_row!(conn, "basic", Dict(:pmid => 1234, :title=>"Test Article", :pub_year=>nothing))

    sel = DBUtils.db_select(conn, ["pmid"], "basic", Dict(:title=>"Test Article", :pmid=>1234))

    @test length(sel[1]) == 1
    @test sel[1][1] == 1234

    if isfile(db_path)
        rm(db_path)
    end
end
