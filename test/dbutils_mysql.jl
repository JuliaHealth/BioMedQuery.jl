using BioMedQuery.Entrez
using MySQL
using BioMedQuery.DBUtils

Entrez.DB.db_backend("MySQL")
config = Dict(:host=>"localhost", :dbname=>"test", :username=>"root",
:pswd=>"", :overwrite=>true)

con = Entrez.DB.init_database(config)

#check collection of tables
tables_query = BioMedQuery.DBUtils.select_all_tables_mysql(con)
tables = ["article","author","author2article","mesh_descriptor","mesh_heading","mesh_qualifier"]
@test sort(tables) == sort(tables_query)

#check minimum insert
BioMedQuery.DBUtils.insert_row_mysql!(con, "article", Dict(:pmid => 1234,
:title=>"Test Article",
:pubYear=>nothing))

sel = BioMedQuery.DBUtils.select_mysql(con, ["pmid"], "article", Dict(:title=>"Test Article"))

@test length(sel[1]) == 1
@test sel[1][1] == 1234
