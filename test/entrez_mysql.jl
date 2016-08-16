using BioMedQuery.Entrez
using MySQL
using BioMedQuery.DBUtils

Entrez.DB.db_backend("MySQL")
config = Dict(:host=>"localhost", :dbname=>"test", :username=>"root",
:pswd=>"", :overwrite=>true)

db = Entrez.DB.init_database(config)

#check collection of tables
tables_query = mysql_execute(db.con, "SHOW TABLES;")
tables = ["article","author","author2article","mesh_descriptor","mesh_heading","mesh_qualifier"]
@test sort(tables) == sort(tables_query[1])

#check minimum insert
Entrez.DB.insert_row(db, "article", Dict(:pmid => 1234,
:title=>"Test Article",
:pubYear=>1964))

insert_query = mysql_execute(db.con, "SELECT pmid FROM article")

@test length(insert_query[1]) == 1
@test insert_query[1][1] == 1234
