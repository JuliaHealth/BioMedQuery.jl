```@meta
EditURL = "https://github.com/TRAVIS_REPO_SLUG/blob/master/../../julia-local-packages/BioMedQuery/examples/literate_src/load_medline.jl"
```

# Load MEDLINE

The MEDLINE loader process in BioMedQuery saves the MEDLINE baseline files to a
MySQL database and saves the raw (xml.gz) and parsed (csv) files to a ```medline```
directory that will be created in the provided ```output_dir```.

**WARNING:** There are 900+ medline files each with approximately 30,000 articles.
This process will take hours to run for the full baseline load.

The baseline files can be found [here](ftp://ftp.ncbi.nlm.nih.gov/pubmed/baseline/).

### Set Up
The database and tables must already be created before loading the medline files.
This process is set up for parallel processing.  To take advantage of this, workers
can be added before loading the BioMedQuery package using the ```addprocs``` function.

```@example load_medline
using BioMedQuery.DBUtils
using BioMedQuery.PubMed
using BioMedQuery.Processes
```

BioMedQuery has utility functions to create the database and tables. *Note: creating
the tables using this function will drop any tables that already exist in the target
database.*

```@example load_medline
const conn = DBUtils.init_mysql_database("127.0.0.1","root","","test_db", true);
PubMed.create_tables!(conn);
```

### Load a Test File
As the full medline load is a large operation, it is recommended that a test run
be completed first.

```@example load_medline
@time Processes.load_medline(conn, pwd(), test=true)
```

Review the output of this run in MySQL to make sure that it ran as expected.
Additionally, the sample raw and parsed file should be in the new ```medline```
directory in the current directory.

### Performing a Full Load
To run a full load, use the same code as above, but do not pass the test variable.
It is also possible to break up the load by passing which files to start and stop at -
simply pass ```start_file=n``` and ```end_file=p```.

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

