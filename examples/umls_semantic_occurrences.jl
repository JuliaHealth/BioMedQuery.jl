
using BioMedQuery.Processes
using BioMedQuery.PubMed
using MySQL
using SQLite

results_dir = "./results"
umls_concept = "Disease or Syndrome";

host="127.0.0.1" 
mysql_usr="root"
mysql_pswd=""
dbname="pubmed_obesity_2010_2012"

db_mysql = MySQL.connect(host, mysql_usr, mysql_pswd, db=dbname)

@time labels2ind, occur = umls_semantic_occurrences(db_mysql, umls_concept)


println("-------------------------------------------------------------")
println("Descriptor to Index Dictionary")
println(labels2ind)
println("-------------------------------------------------------------")

println("-------------------------------------------------------------")
println("Output Data Matrix")
println(full(occur))
println("-------------------------------------------------------------")

db_path="$(results_dir)/pubmed_obesity_2010_2012.db"
db_sqlite = SQLite.DB(db_path)
@time labels2ind, occur = umls_semantic_occurrences(db_sqlite, umls_concept)

println("-------------------------------------------------------------")
println("Descriptor to Index Dictionary")
println(labels2ind)
println("-------------------------------------------------------------")

println("-------------------------------------------------------------")
println("Output Data Matrix")
println(full(occur))
println("-------------------------------------------------------------")
