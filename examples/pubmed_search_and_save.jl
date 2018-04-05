
using MySQL
using BioMedQuery.DBUtils
using BioMedQuery.PubMed
using BioMedQuery.Processes
using DataFrames

const email= "" #Only needed if you want to contact NCBI with inqueries
const search_term="(obesity[MeSH Major Topic]) AND (\"2010\"[Date - Publication] : \"2012\"[Date - Publication])"
const max_articles = 5
const results_dir = "./results"
const verbose = false;

# Initialize database, if it exists it connects to it, otherwise it creates it
const mysql_conn = DBUtils.init_mysql_database("127.0.0.1", "root", "", "pubmed_obesity_2010_2012")

# Creates (and deletes if they already exist) all tables needed to save a pubmed search
PubMed.create_tables!(mysql_conn)

# Search pubmed and save results to database
Processes.pubmed_search_and_save!(email, search_term, max_articles, mysql_conn, verbose)

display(all_pmids(mysql_conn))

tables = ["author", "author2article", "mesh_descriptor",
"mesh_qualifier", "mesh_heading"]

for t in tables
    query_str = "SELECT * FROM "*t*" LIMIT 5;"
    q = MySQL.query(mysql_conn, query_str, DataFrame)
    println(q)
end

MySQL.disconnect(mysql_conn)

const db_path = "$(results_dir)/pubmed_obesity_2010_2012.db"

#overwrite
if isfile(db_path)
    rm(db_path)
end 

#connect
const conn_sqlite = SQLite.DB(db_path)

# Creates (and deletes if they already exist) all tables needed to save a pubmed search
PubMed.create_tables!(conn_sqlite)  
Processes.pubmed_search_and_save!(email, search_term, max_articles, conn_sqlite, verbose)

display(PubMed.all_pmids(conn_sqlite))

tables = ["author", "author2article", "mesh_descriptor",
"mesh_qualifier", "mesh_heading"]

for t in tables
    query_str = "SELECT * FROM "*t*" LIMIT 5;"
    q = SQLite.query(conn_sqlite, query_str)
    println(q)
end

enw_file = "$(results_dir)/pubmed_obesity_2010_2012.enw"
endnote_citation = PubMed.CitationOuput("endnote", enw_file, true)
Processes.pubmed_search_and_save!(email, search_term, max_articles, endnote_citation, verbose);

println(readstring(enw_file))
