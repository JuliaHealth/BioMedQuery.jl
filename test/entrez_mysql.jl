using BioMedQuery.Entrez
using MySQL
using BioMedQuery.DBUtils

Entrez.DB.db_backend("MySQL")
config = Dict(:host=>"localhost", :dbname=>"test", :username=>"root",
:pswd=>"", :overwrite=>true)

con = Entrez.DB.init_database(config)

#check collection of tables
tables_query = mysql_execute(con, "SHOW TABLES;")
tables = ["article","author","author2article","mesh_descriptor","mesh_heading","mesh_qualifier"]
@test sort(tables) == sort(tables_query[1])

#check minimum insert
Entrez.DB.insert_row(con, "article", Dict(:pmid => 1234,
:title=>"Test Article",
:pubYear=>nothing))

insert_query = mysql_execute(con, "SELECT pmid FROM article")

@test length(insert_query[1]) == 1
@test insert_query[1][1] == 1234


q = BioMedQuery.DBUtils.select(con, ["pmid"], "article", Dict(:title=>"Test Article"))
