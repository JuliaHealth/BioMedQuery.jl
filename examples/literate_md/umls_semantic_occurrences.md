```@meta
EditURL = "https://github.com/TRAVIS_REPO_SLUG/blob/master/../../julia-local-packages/BioMedQuery/examples/literate_src/umls_semantic_occurrences.jl"
```

# Unified Medical Language (UMLS) Filtering
This example demonstrates how to obtain an occurrence matrix associated with a
UMLS concept in a previously obtained pubmed/medline search.

**Note:** This example uses the database created and updated by:
* Examples / Pubmed Search and Save
* Exmaples / MeSH/UMLS Map

The following backends are supported for retieving the prior information:
* MySQL
* SQLite

### Set Up

```@example umls_semantic_occurrences
using BioMedQuery.Processes
using BioMedQuery.PubMed
using MySQL
using SQLite

results_dir = "./results";
umls_concept = "Disease or Syndrome";
```

### MySQL backend

Connecting to MySQL database that was created in pubmed_search_and_save example

```@example umls_semantic_occurrences
host = "127.0.0.1";
mysql_usr = "root";
mysql_pswd = "";
dbname = "pubmed_obesity_2010_2012";

db_mysql = MySQL.connect(host, mysql_usr, mysql_pswd, db=dbname);
```

Getting the descriptor to index dictionary and the occurence matrix

```@example umls_semantic_occurrences
@time labels2ind, occur = umls_semantic_occurrences(db_mysql, umls_concept);
```

Descriptor to Index Dictionary

```@example umls_semantic_occurrences
labels2ind
```

Output Data Matrix

```@example umls_semantic_occurrences
full(occur)
```

### SQLite backend

Connecting to SQLite database that was created in pubmed_search_and_save example

```@example umls_semantic_occurrences
db_path = "$(results_dir)/pubmed_obesity_2010_2012.db";
db_sqlite = SQLite.DB(db_path);
```

Getting the descriptor to index dictionary and occurence matrix

```@example umls_semantic_occurrences
@time labels2ind, occur = umls_semantic_occurrences(db_sqlite, umls_concept);
```

Descriptor to Index Dictionary

```@example umls_semantic_occurrences
labels2ind
```

Output Data Matrix

```@example umls_semantic_occurrences
full(occur)
```

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

