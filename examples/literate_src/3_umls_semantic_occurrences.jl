# # Unified Medical Language (UMLS) Filtering

#md [![nbviewer](https://img.shields.io/badge/jupyter_notebook-nbviewer-orange.svg)](http://nbviewer.jupyter.org/github/bcbi/BioMedQuery.jl/tree/master/docs/src/notebooks/umls_semantic_occurrences.ipynb)

# This example demonstrates how to obtain an occurrence matrix associated with a
# UMLS concept in a previously obtained pubmed/medline search.
#
# **Note:** This example uses the database created and updated by:
# * Examples / Pubmed Search and Save
# * Exmaples / MeSH/UMLS Map
#
# The following backends are supported for retieving the prior information:
# * MySQL
# * SQLite

# ### Set Up
using BioMedQuery.Processes
using BioMedQuery.PubMed
using MySQL
using SQLite

results_dir = ".";
umls_concept = "Disease or Syndrome";

# ### MySQL backend

# Connecting to MySQL database that was created in pubmed_search_and_save example
host = "127.0.0.1";
mysql_usr = "root";
mysql_pswd = "";
dbname = "pubmed_obesity_2010_2012";

db_mysql = MySQL.connect(host, mysql_usr, mysql_pswd, db=dbname);

# Getting the descriptor to index dictionary and the occurence matrix
@time labels2ind, occur = umls_semantic_occurrences(db_mysql, umls_concept);

# Descriptor to Index Dictionary
labels2ind

# Output Data Matrix
full(occur)

MySQL.disconnect(db_mysql) #src

# ### SQLite backend

# Connecting to SQLite database that was created in pubmed_search_and_save example
db_path = "$(results_dir)/pubmed_obesity_2010_2012.db";
db_sqlite = SQLite.DB(db_path);

# Getting the descriptor to index dictionary and occurence matrix
@time labels2ind, occur = umls_semantic_occurrences(db_sqlite, umls_concept);

# Descriptor to Index Dictionary
labels2ind

# Output Data Matrix
full(occur)
