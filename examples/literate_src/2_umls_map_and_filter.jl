# # Using UMLS Concepts with MeSH

#md # [![nbviewer](https://img.shields.io/badge/jupyter_notebook-nbviewer-orange.svg)](http://nbviewer.jupyter.org/github/bcbi/BioMedQuery.jl/tree/master/docs/src/notebooks/2_umls_map_and_filter.ipynb)

# The Medical Subject Headings (MeSH) terms returned from a PubMed search can be further analyzed
# by mapping them to Unified Medical Language System (UMLS) concepts, as well as
# filtering the MeSH Terms by concepts.

# For both mapping MeSH to UMLS Concepts and filtering MeSH by concept, the following backends are supported:
# * MySQL
# * SQLite
# * DataFrames


# ### Set Up
using SQLite
using MySQL
using BioMedQuery.DBUtils
using BioMedQuery.Processes
using BioServices.UMLS
using BioMedQuery.PubMed
using DataFrames

# Credentials are environment variables (e.g set in your .juliarc.jl)
umls_user = ENV["UMLS_USER"];
umls_pswd = ENV["UMLS_PSSWD"];
email = ""; # Only needed if you want to contact NCBI with inqueries
search_term = """(obesity[MeSH Major Topic]) AND ("2010"[Date - Publication] : "2012"[Date - Publication])""";
umls_concept = "Disease or Syndrome";
max_articles = 5;
results_dir = ".";
verbose = true;

results_dir = ".";

# ## MySQL

# ### Map Medical Subject Headings (MeSH) to UMLS

# This example demonstrates the typical workflow to populate a MESH2UMLS database
# table relating all concepts associated with all MeSH terms in the input database.

# *Note: this example reuses the MySQL DB from the PubMed Search and Save example.*
#
# Create MySQL DB connection
host = "127.0.0.1";
mysql_usr = "root";
mysql_pswd = "";
dbname = "pubmed_obesity_2010_2012";

const mysql_conn = DBUtils.init_mysql_database(host, mysql_usr, mysql_pswd, dbname) # hide
PubMed.create_tables!(mysql_conn) # hide
Processes.pubmed_search_and_save!(email, search_term, max_articles, mysql_conn, verbose) # hide
sleep(1) # hide
MySQL.disconnect(mysql_conn) #hide

db_mysql = MySQL.connect(host, mysql_usr, mysql_pswd, db = dbname);

# Map MeSH to UMLS
@time map_mesh_to_umls_async!(db_mysql, umls_user, umls_pswd; append_results=false, timeout=3);

# #### Explore the output table

db_query(db_mysql, "SELECT * FROM mesh2umls")

# ### Filtering MeSH terms by UMLS concept

# Getting the descriptor to index dictionary and the occurence matrix
@time labels2ind, occur = umls_semantic_occurrences(db_mysql, umls_concept);

# Descriptor to Index Dictionary
labels2ind

# Output Data Matrix
Matrix(occur)

MySQL.disconnect(db_mysql) #src

# ## SQLite

# This example demonstrates the typical workflow to populate a MESH2UMLS database
# table relating all concepts associated with all MeSH terms in the input database.

# *Note: this example reuses the SQLite DB from the PubMed Search and Save example.*
#
# Create SQLite DB connection
db_path = "$(results_dir)/pubmed_obesity_2010_2012.db";
db_sqlite = SQLite.DB(db_path);

if isfile(db_path) # hide
    rm(db_path) # hide
end # hide
db_sqlite = SQLite.DB(db_path); # hide
PubMed.create_tables!(db_sqlite); # hide
Processes.pubmed_search_and_save!(email, search_term, max_articles, db_sqlite, false) # hide
sleep(1) # hide

# ### Map MeSH to UMLS
@time map_mesh_to_umls_async!(db_sqlite, umls_user, umls_pswd; append_results=false, timeout=3);

# Explore the output table
db_query(db_sqlite, "SELECT * FROM mesh2umls;")

# ### Filtering MeSH terms by UMLS concept

# Getting the descriptor to index dictionary and occurence matrix
@time labels2ind, occur = umls_semantic_occurrences(db_sqlite, umls_concept);

# Descriptor to Index Dictionary
labels2ind

# Output Data Matrix
Matrix(occur)

# ## DataFrames

# This example demonstrates the typical workflow to create a MeSH to UMLS map as a DataFrame
# relating all concepts associated with all MeSH terms in the input dataframe.

# Get the articles (same as example in PubMed Search and Parse)
dfs = Processes.pubmed_search_and_parse(email, search_term, max_articles, verbose)

# Map MeSH to UMLS and explore the output table
@time res = map_mesh_to_umls_async(dfs["mesh_desc"], umls_user, umls_pswd)

# Getting the descriptor to index dictionary and occurence matrix
@time labels2ind, occur = umls_semantic_occurrences(dfs, res, umls_concept);

# Descriptor to Index Dictionary
labels2ind

# Output Data Matrix
Matrix(occur)
