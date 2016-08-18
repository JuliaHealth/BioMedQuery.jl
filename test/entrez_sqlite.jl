using BioMedQuery.Entrez
using SQLite
using BioMedQuery.DBUtils


config = Dict(:db_path=>"./test_db.sqlite", :overwrite=>true)
db = Entrez.DB.init_database_sqlite(config)

#check collection of tables
tables_query = BioMedQuery.DBUtils.select_all_tables_sqlite(db)
tables = ["article","author","author2article","mesh_descriptor","mesh_heading","mesh_qualifier", "sqlite_sequence"]
@test sort(tables) == sort(tables_query)


#check minimum insert
BioMedQuery.DBUtils.insert_row_sqlite!(db, "article", Dict(:pmid => 1234,
:title=>"Test Article",
:pubYear=>nothing))

# insert_query = SQLite.query(db, "SELECT pmid FROM article")
#
# @test length(insert_query[1]) == 1
# @test insert_query[1][1].value == 1234

sel = BioMedQuery.DBUtils.select_sqlite(db, ["pmid"], "article", Dict(:title=>"Test Article", :pmid=>1234))

@test length(sel[1]) == 1
@test sel[1][1].value == 1234
