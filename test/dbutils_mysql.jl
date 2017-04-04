using BioMedQuery.Entrez
using MySQL
using BioMedQuery.DBUtils

dbname="test"

config = Dict(:host=>"127.0.0.1", :dbname=>dbname, :username=>"root",
:pswd=>"", :overwrite=>true)

con = Entrez.DB.init_pubmed_db_mysql(config)
Entrez.DB.init_pubmed_db_mysql!(con, true)
Entrez.DB.init_pubmed_db_mysql!(con, false)

#check collection of tables
tables_query = BioMedQuery.DBUtils.select_all_tables(con)
tables = ["article","author","author2article","mesh_descriptor","mesh_heading","mesh_qualifier"]
@test sort(tables) == sort(tables_query)

#check minimum insert
BioMedQuery.DBUtils.insert_row!(con, "article", Dict(:pmid => 1234,
:title=>"Test Article",
:pubYear=>nothing))

#check duplicate error insert
duplicate_id = BioMedQuery.DBUtils.insert_row!(con, "article", Dict(:pmid => 1234,
    :title=>"Test Article", :pubYear=>nothing))


@test duplicate_id < 1
sel = BioMedQuery.DBUtils.db_select(con, ["pmid"], "article", Dict(:title=>"Test Article"))

@test length(sel[1]) == 1
@test sel[1][1] == 1234

#clean up
db_query(con, "DROP DATABASE IF EXISTS $dbname;")
