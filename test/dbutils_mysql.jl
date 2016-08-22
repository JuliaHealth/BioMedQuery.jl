using BioMedQuery.Entrez
using MySQL
using BioMedQuery.DBUtils

config = Dict(:host=>"localhost", :dbname=>"test", :username=>"root",
:pswd=>"", :overwrite=>true)

con = Entrez.DB.init_database_mysql(config)

#check collection of tables
tables_query = BioMedQuery.DBUtils.select_all_tables(con)
tables = ["article","author","author2article","mesh_descriptor","mesh_heading","mesh_qualifier"]
@test sort(tables) == sort(tables_query)

#check minimum insert
BioMedQuery.DBUtils.insert_row!(con, "article", Dict(:pmid => 1234,
:title=>"Test Article",
:pubYear=>nothing))

#check duplicate error insert
duplicate_caught = false
try
    BioMedQuery.DBUtils.insert_row!(con, "article", Dict(:pmid => 1234,
    :title=>"Test Article", :pubYear=>nothing))
catch
    duplicate_caught = true
end

@test duplicate_caught == true
sel = BioMedQuery.DBUtils.db_select(con, ["pmid"], "article", Dict(:title=>"Test Article"))

@test length(sel[1]) == 1
@test sel[1][1] == 1234
