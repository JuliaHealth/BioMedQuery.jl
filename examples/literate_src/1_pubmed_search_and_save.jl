# # Search PubMed and Save Results

#md # [![nbviewer](https://img.shields.io/badge/jupyter_notebook-nbviewer-orange.svg)](http://nbviewer.jupyter.org/github/bcbi/BioMedQuery.jl/tree/master/docs/src/notebooks/1_pubmed_search_and_save.ipynb)

# This example demonstrates the typical workflow to query pubmed and store
# the results. The following backends are supported for storing the results:
# * MySQL
# * SQLite
# * Citation (endnote/bibtex)
# * DataFrames

# ### Set Up

using BioMedQuery.DBUtils
using BioMedQuery.PubMed
using BioMedQuery.Processes
using DataFrames
using MySQL
using SQLite

# Variables used to search PubMed
email = ""; # Only needed if you want to contact NCBI with inqueries
search_term = """(obesity[MeSH Major Topic]) AND ("2010"[Date - Publication] : "2012"[Date - Publication])""";
max_articles = 5;
results_dir = ".";
verbose = true;

# ### MySQL backend

# Initialize database, if it exists it connects to it, otherwise it creates it
const mysql_conn = DBUtils.init_mysql_database("127.0.0.1", "root", "", "pubmed_obesity_2010_2012");

# Creates (and deletes if they already exist) all tables needed to save a pubmed search
PubMed.create_tables!(mysql_conn);

# Search pubmed and save results to database
Processes.pubmed_search_and_save!(email, search_term, max_articles, mysql_conn, verbose)
sleep(1) # hide

# #### Access all PMIDs
all_pmids(mysql_conn)

# #### Explore tables
# You may use the MySQL command directly. If you want the return type to be a DataFrame, you need to explicitly request so.
tables = ["author_ref", "mesh_desc", "mesh_qual", "mesh_heading"]
for t in tables
    query_str = "SELECT * FROM $t LIMIT 5;"
    q = MySQL.Query(mysql_conn, query_str) |> DataFrame
    println(q)
end

#-
MySQL.disconnect(mysql_conn);

# ### SQLite backend

const db_path = "$(results_dir)/pubmed_obesity_2010_2012.db";

# Overwrite the database if it already exists
if isfile(db_path)
    rm(db_path)
end

# Connect to the database
const conn_sqlite = SQLite.DB(db_path);

# Creates (and deletes if they already exist) all tables needed to save a pubmed search
PubMed.create_tables!(conn_sqlite);

# Search PubMed and save the results
Processes.pubmed_search_and_save!(email, search_term, max_articles, conn_sqlite, verbose)
sleep(1) # hide

# #### Access all PMIDs
all_pmids(conn_sqlite)

# #### Explore the tables
# You may use the SQLite commands directly. The return type is a DataFrame.
tables = ["author_ref", "mesh_desc", "mesh_qual", "mesh_heading"]
for t in tables
    query_str = "SELECT * FROM $t LIMIT 5;"
    q = SQLite.query(conn_sqlite, query_str)
    println(q)
end

# ### Citations
# Citation type can be "endnote" or "bibtex"

enw_file = "$(results_dir)/pubmed_obesity_2010_2012.enw"
endnote_citation = PubMed.CitationOutput("endnote", enw_file, true)
Processes.pubmed_search_and_save!(email, search_term, max_articles, endnote_citation, verbose);
sleep(1) # hide
println(read(enw_file, String))

# ### DataFrames
# Returns a dictionary of dataframes which match the content and structure of the database tables.
dfs = Processes.pubmed_search_and_parse(email, search_term, max_articles, verbose)
sleep(1) # hide
