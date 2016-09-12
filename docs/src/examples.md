Sample scripts of how to use BioMedQuery.Processes

## Running the scripts

From the terminal:

`julia script_name.jl`.


All scripts contain block of codes where local variables need to be configured,
these sections are enclosed by the comment lines

```
#************************ LOCALS TO CONFIGURE!!!! **************************
#***************************************************************************
```


**User Credentials**

Whenever and email address, passwords or any other type of credentials are required,
they are expected to be stored in your system as environment variables.

From a Julia session, you can set an environment variable using

`ENV["MY_VAR"] = ""`

However, for this variable to be permanently available, you need to add that line to
your `~/.juliarc.jl` file


## Searching PubMed and Save

It is common to search PubMed for a given number, or all articles associated with
a search term, and further storing the results to a database, xml or exporting
to a citation-style document.

The script `pubmed_search_and_save.jl` allows for all that.

The top of the script contains the configuration of the search term, maximum number of
articles to fetch and the format for saving the results. Depending on the "exporting format",
there will be other local variables to configure. Thus fur the results can be saved as:
* MySQL/SQLite database
* XML (raw NCBI response)
* Citations: EndNote, BibTEX

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
using_endnote=true
using_xml=false

#***************************************************************************

if using_mysql
    #************************ LOCALS TO CONFIGURE!!!! **************************
    host="localhost" #If want to hide - use enviroment variables instead
    mysql_usr="root"
    mysql_pswd=""
    dbname="pubmed_obesity_2010_2012"
    #***************************************************************************

elseif using_sqlite
    #************************ LOCALS TO CONFIGURE!!!! **************************
    db_path="results_dir/pubmed_obesity_2010_2012.db"
    #***************************************************************************

elseif using_endnote
    #************************ LOCALS TO CONFIGURE!!!! **************************
    citation_type="endnote"
    output_file="results_dir/pubmed_obesity_2010_2012.enw"
    #***************************************************************************

elseif using_xml
    #************************ LOCALS TO CONFIGURE!!!! **************************
    output_file="results_dir/pubmed_obesity_2010_2012.xml"
    #***************************************************************************
else
end
```

## Build MESH-UMLS map

All PubMed articles are associated with MESH descriptors. This script looks for all
mesh descriptors in a results database (as created in pubmed_search_and_save.jl)
and finds the UMLS concept associated with that descriptor.

All MESH-UMLS relations are saved in a new (unless set to append) database table
called MESH2UMLS.

The user is responsible for configuring the environment variables containing the
UMLS credentials and specifying the type and name of the database used to get the
MESH and stored the MESH2UMLS.

```
#************************ LOCALS TO CONFIGURE!!!! **************************
user = ENV["UMLS_USER"]
psswd = ENV["UMLS_PSSWD"]


#Database backend
using_sqlite=false
using_mysql=true
#***************************************************************************

if using_sqlite
    #************************ LOCALS TO CONFIGURE!!!! **************************
    db_path="./pubmed_obesity_2010_2012.db"
    #***************************************************************************
elseif using_mysql
    #************************ LOCALS TO CONFIGURE!!!! **************************
    host="localhost" #If want to hide - use enviroment variables instead
    mysql_usr="root"
    mysql_pswd=""
    dbname="pubmed_obesity_2010_2012"
    #***************************************************************************
else
end

```

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
