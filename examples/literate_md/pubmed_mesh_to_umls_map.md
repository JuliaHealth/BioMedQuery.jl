```@meta
EditURL = "https://github.com/TRAVIS_REPO_SLUG/blob/master/../../julia-local-packages/BioMedQuery/examples/literate_src/pubmed_mesh_to_umls_map.jl"
```

# Map Medical Subject Headings (MeSH) to UMLS

This example demonstrates the typical workflow to populate a MESH2UMLS database
table relating all concepts associated with all MeSH terms in the input database.

The following backends are supported for storing the results:
* MySQL
* SQLite

### Set Up

```@example pubmed_mesh_to_umls_map
using SQLite
using MySQL
using BioMedQuery.DBUtils
using BioMedQuery.Processes
using BioServices.UMLS
```

Credentials are environment variables (e.g set in your .juliarc.jl)

```@example pubmed_mesh_to_umls_map
umls_user = ENV["UMLS_USER"];
umls_pswd = ENV["UMLS_PSSWD"];

results_dir = "./results";
```

### Using MySQL as a backend

*Note: this example reuses the MySQL DB from the PubMed Search and Save example.*

Create MySQL DB connection

```@example pubmed_mesh_to_umls_map
host = "127.0.0.1";
mysql_usr = "root";
mysql_pswd = "";
dbname = "pubmed_obesity_2010_2012";

db_mysql = MySQL.connect(host, mysql_usr, mysql_pswd, db = dbname);
```

Map MeSH to UMLS

```@example pubmed_mesh_to_umls_map
@time map_mesh_to_umls_async!(db_mysql, umls_user, umls_pswd; append_results=false, timeout=3);
```

#### Explore the output table

```@example pubmed_mesh_to_umls_map
db_query(db_mysql, "SELECT * FROM mesh2umls")
```

### Using SQLite as a backend

*Note: this example reuses the MySQL DB from the PubMed Search and Save example.*

Create SQLite DB connection

```@example pubmed_mesh_to_umls_map
db_path = "$(results_dir)/pubmed_obesity_2010_2012.db";
db_sqlite = SQLite.DB(db_path);
```

Map MeSH to UMLS

```@example pubmed_mesh_to_umls_map
@time map_mesh_to_umls_async!(db_sqlite, umls_user, umls_pswd; append_results=false, timeout=3);
```

#### Explore the output table

```@example pubmed_mesh_to_umls_map
db_query(db_sqlite, "SELECT * FROM mesh2umls;")
```

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

