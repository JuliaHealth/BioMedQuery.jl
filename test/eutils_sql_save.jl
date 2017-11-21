using BioMedQuery.Entrez
using MySQL
using BioMedQuery.DBUtils

dbname="test"

config = Dict(:host=>"127.0.0.1", :dbname=>dbname, :username=>"root",
:pswd=>"", :overwrite=>true)

con = Entrez.DB.init_pubmed_db_mysql(config)
Entrez.DB.init_pubmed_db_mysql!(con, true)
Entrez.DB.init_pubmed_db_mysql!(con, false)

all_tables = select_all_tables(con)

pritntln(all_tables)
