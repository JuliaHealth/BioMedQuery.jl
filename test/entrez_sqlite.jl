using BioMedQuery.Entrez
using SQLite
using BioMedQuery.DBUtils

Entrez.DB.db_backend("SQLite")

config = Dict(:db_path=>"./test_db.sqlite", :overwrite=>true)
db = Entrez.DB.init_database(config)

#check collection of tables
tables_query = SQLite.query(db, "SELECT name FROM sqlite_master WHERE type='table'")
tables = ["article","author","author2article","mesh_descriptor","mesh_heading","mesh_qualifier", "sqlite_sequence"]
@test sort(tables) == sort(tables_query[1].values)

#check minimum insert
Entrez.DB.insert_row(db, "article", Dict(:pmid => 1234,
:title=>"Test Article",
:pubYear=>nothing))

insert_query = SQLite.query(db, "SELECT pmid FROM article")

@test length(insert_query[1]) == 1
@test insert_query[1][1].value == 1234
