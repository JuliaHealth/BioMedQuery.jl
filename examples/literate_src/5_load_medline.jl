# # Load MEDLINE

#md # [![nbviewer](https://img.shields.io/badge/jupyter_notebook-nbviewer-orange.svg)](http://nbviewer.jupyter.org/github/bcbi/BioMedQuery.jl/tree/master/docs/src/notebooks/5_load_medline.ipynb)

# The MEDLINE loader process in BioMedQuery saves the MEDLINE baseline files to a
# MySQL database and saves the raw (xml.gz) and parsed (csv) files to a `medline`
# directory that will be created in the provided `output_dir`.
#
# **WARNING:** There are 900+ medline files each with approximately 30,000 articles.
# This process will take hours to run for the full baseline load.
#
# The baseline files can be found [here](ftp://ftp.ncbi.nlm.nih.gov/pubmed/baseline/).

# ### Set Up
# The database and tables must already be created before loading the medline files.
# This process is set up for parallel processing.  To take advantage of this, workers
# can be added before loading the BioMedQuery package using the `addprocs` function.

using BioMedQuery

# BioMedQuery has utility functions to create the database and tables. *Note: creating
# the tables using this function will drop any tables that already exist in the target
# database.*

const conn = BioMedQuery.DBUtils.init_mysql_database("127.0.0.1","root","","test_db", overwrite=true);
BioMedQuery.PubMed.create_tables!(conn);

# ### Load a Test File
# As the full medline load is a large operation, it is recommended that a test run
# be completed first.

@time BioMedQuery.Processes.load_medline!(conn, pwd(), test=true)

# Review the output of this run in MySQL to make sure that it ran as expected.
# Additionally, the sample raw and parsed file should be in the new `medline`
# directory in the current directory.

# ### Performing a Full Load
# To run a full load, use the same code as above, but do not pass the test variable.
# It is also possible to break up the load by passing which files to start and stop at -
# simply pass `start_file=n and `end_file=p`. Currently the default end_file reflects the
# last file of the 2019 baseline.
#
# After loading, it is recommended you add indexes to the tables, the `add_mysql_keys!`
# function can be used to add a standard set of indexes.

BioMedQuery.PubMed.add_mysql_keys!(conn)
