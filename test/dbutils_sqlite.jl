using SQLite

@testset "SQLite BDUtils" begin
    db_path = "./test_db.sqlite"

    config = Dict(:db_path=>db_path, :overwrite=>true)
    db = BioMedQuery.PubMed.init_pubmed_db_sqlite(config)

    #check collection of tables
    tables_query = BioMedQuery.DBUtils.select_all_tables(db)
    tables = ["article","author","author2article","mesh_descriptor","mesh_heading","mesh_qualifier", "sqlite_sequence"]
    @test sort(tables) == sort(tables_query)


    #check minimum insert
    BioMedQuery.DBUtils.insert_row!(db, "article", Dict(:pmid => 1234,
    :title=>"Test Article",
    :pubYear=>nothing))

    sel = BioMedQuery.DBUtils.db_select(db, ["pmid"], "article", Dict(:title=>"Test Article", :pmid=>1234))

    @test length(sel[1]) == 1
    @test sel[1][1] == 1234

    if isfile(db_path)
        rm(db_path)
    end
end
