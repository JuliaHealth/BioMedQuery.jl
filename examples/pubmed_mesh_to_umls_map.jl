
using SQLite
using MySQL
using BioMedQuery.Processes
using BioServices.UMLS

# credentials are environment variables (e.g set in your .juliarc)
umls_user = ENV["UMLS_USER"];
umls_pswd = ENV["UMLS_PSSWD"];

host="localhost" 
mysql_usr="root"
mysql_pswd=""
dbname="pubmed_obesity_2010_2012"

db = mysql_connect(host, mysql_usr, mysql_pswd, dbname)
@time map_mesh_to_umls_async!(db, umls_user, umls_pswd; append_results=false)

BioMedQuery.DBUtils.db_query(db, "SELECT * FROM mesh2umls;")

db_path="./pubmed_obesity_2010_2012.db"
db = SQLite.DB(db_path)
@time map_mesh_to_umls_async!(db, umls_user, umls_pswd; append_results=false)
