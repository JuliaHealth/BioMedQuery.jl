Sample scripts of how to use BioMedQuery.Processes

## Running the scripts

All scripts can be called from the terminal:

`julia script_name.jl`.


## Configuring local variables

Local paths, database backends, and other variables need to be configured according
to you needs, sections containing this local variables are enclosed by the comment lines

```
#************************ LOCALS TO CONFIGURE!!!! **************************
#***************************************************************************
```


**User Credentials**

Email addresses, passwords or any other type of credentials are expected to be
stored in your system as environment variables.

From a Julia session, you can set an environment variable using

`ENV["MY_PSWD"] = "MyPsWd"`

However, for this variable to be permanently available, you need to add that line to
your `~/.juliarc.jl` file.


## Search&Save PubMed

It is common to search PubMed for a given number, or all articles associated with
a search term, and further store the results to a database, xml or exporting
to a citation-style document.

The script `pubmed_search_and_save.jl` can achieve all that.

The top of the script contains the configuration of the search term, the maximum number of
articles to fetch and the format for saving the results. Depending on the "exporting format",
there will be other local variables to configure. The results can be saved as:

* MySQL/SQLite database
* XML (raw NCBI response)
* Citations: EndNote, BibTEX

The main configuration looks as follows:

```
#************************ LOCALS TO CONFIGURE!!!! **************************
email= ENV["NCBI_EMAIL"] #This is an enviroment variable that you need to setup
search_term="(obesity[MeSH Major Topic]) AND (\"2010\"[Date - Publication] : \"2012\"[Date - Publication])"
max_articles = 20
overwrite=true
verbose = false

results_dir = "./results"


#Exporting format
using_sqlite=false
using_mysql=false
using_endnote=false
using_xml=false

#***************************************************************************
```

###Using MySQL

If for instance, one wished to save the results to a MySQL database, all we need to do
is to set

`using_mysql = true`

then, the following code would be executed:

```
#************************ LOCALS TO CONFIGURE!!!! **************************
host="localhost" #If want to hide - use enviroment variables instead
mysql_usr="root"
mysql_pswd=""
dbname="pubmed_obesity_2010_2012"
#***************************************************************************
config = Dict(:host=>host,
                 :dbname=>dbname,
                 :username=>mysql_usr,
                 :pswd=>mysql_pswd,
                 :overwrite=>overwrite)
 save_func = save_efetch_mysql

 db = pubmed_search_and_save(email, search_term, max_articles,
 save_func, config, verbose)
```


## Build MESH-UMLS map

All PubMed articles are associated with MESH descriptors. This script looks for all
mesh descriptors in a results database (as created in pubmed_search_and_save.jl)
and finds the UMLS concept associated with that descriptor.

All MESH-UMLS relations are saved in a new (unless set to append) database table
called MESH2UMLS.

The user is responsible for configuring the environment variables containing the
UMLS credentials:

```
user = ENV["UMLS_USER"]
psswd = ENV["UMLS_PSSWD"]
```

And specifying the type and name of the database used to get the
MESH and stored the MESH2UMLS.



## Occurrence Matrix

This script finds all MESH descriptors of a given UMLS semantic type and
builds the corresponding occurrance/data matrix as follows

Suppose we wish to find all MESH descriptors in all articles in our database associated with the
UMLS Semantic Type: "Disease or Syndrome"

Suppose we have a total of 4 articles and after filtering the MESH descriptors we have 3 descriptors. Further suppose that:

* The first article is associated with "diabetes mellitus, type 2" and "pediatric obesity"
* The second article is associated with "pediatric obesity"
* The third article is associate with "metabolic syndrome x"
* The fourth article is not associated with any "Disease or Syndrome"

Then the Data Matrix would corresponds to

MESH(down)/ARTICLE(right) | A1  | A2  | A3  | A4  
------------------------- | --- | --- | --- | ---
metabolic syndrome x      | 0   | 0   | 1   | 0
diabetes mellitus, type 2 | 1   | 0   | 0   | 0
pediatric obesity         | 1   | 1   | 0   | 0


###Output Files

This script will save two files two files to disk in the specified output directory:

* `occur_sp.jdl`: Binary file containing the sparse datamatrix in variable `occur`
* `labels2ind.jdl`: Binary file containing the row index to descriptor label dictionary inside variable `labels2ind`

To load back these variable into julia use JDL package. e.g,

```
using JDL
file  = jldopen("occur_sp.jdl", "r")
data_matrix = read(file, "occur")
```
