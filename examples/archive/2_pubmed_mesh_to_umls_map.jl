# # Map Medical Subject Headings (MeSH) to UMLS

#md # [![nbviewer](https://img.shields.io/badge/jupyter_notebook-nbviewer-orange.svg)](http://nbviewer.jupyter.org/github/bcbi/BioMedQuery.jl/tree/master/docs/src/notebooks/2_pubmed_mesh_to_umls_map.ipynb)

# This example demonstrates the typical workflow to populate a MESH2UMLS database
# table relating all concepts associated with all MeSH terms in the input database.
#
# The following backends are supported for storing the results:
# * MySQL
# * SQLite
# * DataFrame

# ### Set Up
using SQLite
using MySQL
using BioMedQuery.DBUtils
using BioMedQuery.Processes
using BioServices.UMLS
using BioMedQuery.PubMed # hide

# Credentials are environment variables (e.g set in your .juliarc.jl)
umls_user = ENV["UMLS_USER"];
umls_pswd = ENV["UMLS_PSSWD"];
email = ""; # Only needed if you want to contact NCBI with inqueries
search_term = """(obesity[MeSH Major Topic]) AND ("2010"[Date - Publication] : "2012"[Date - Publication])""";
max_articles = 5;
results_dir = ".";
verbose = true;

results_dir = ".";

# ### Using MySQL as a backend

# *Note: this example reuses the MySQL DB from the PubMed Search and Save example.*
#
# Create MySQL DB connection
host = "127.0.0.1";
mysql_usr = "root";
mysql_pswd = "";
dbname = "pubmed_obesity_2010_2012";

db_mysql = MySQL.connect(host, mysql_usr, mysql_pswd, db = dbname);

# Map MeSH to UMLS
@time map_mesh_to_umls_async!(db_mysql, umls_user, umls_pswd; append_results=false, timeout=3);

# #### Explore the output table

db_query(db_mysql, "SELECT * FROM mesh2umls")

MySQL.disconnect(db_mysql) #src

# ### Using SQLite as a backend

# *Note: this example reuses the MySQL DB from the PubMed Search and Save example.*
#
# Create SQLite DB connection
db_path = "$(results_dir)/pubmed_obesity_2010_2012.db";
db_sqlite = SQLite.DB(db_path);

if isfile(db_path) # hide
    rm(db_path) # hide
end # hide
db_sqlite = SQLite.DB(db_path); # hide
PubMed.create_tables!(db_sqlite); # hide
Processes.pubmed_search_and_save!(email, search_term, max_articles, db_sqlite, verbose) # hide

# Map MeSH to UMLS
@time map_mesh_to_umls_async!(db_sqlite, umls_user, umls_pswd; append_results=false, timeout=3);

# #### Explore the output table
db_query(db_sqlite, "SELECT * FROM mesh2umls;")

# ### Using DataFrames as a backend

# Get the articles (same as example in PubMed Search and Parse)
dfs = Processes.pubmed_search_and_parse(email, search_term, max_articles, verbose)

# Map MeSH to UMLS and explore the output table
@time res = map_mesh_to_umls_async(dfs["mesh_desc"], umls_user, umls_pswd)
