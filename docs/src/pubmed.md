Utility functions to parse and store responses from [BioServices.EUtils](http://biojulia.net/BioServices.jl/latest/man/eutils)

## Import Module

```
using BioMedQuery.PubMed
```

This module provides tility functions to parse NCBI responses obtained via [BioServices.EUtils](http://biojulia.net/BioServices.jl/latest/man/eutils), and finally store them to a database, or export them as citations. For many purposes you may interact with the higher level pipelines in [BioMedQuery.Processes]. Here, some of the lower level functions are discussed in case you need to assemble different pipelines.


## Handling XML responses

Many APIs return responses in XML form. 

To parse an XML to a Julia dictionary we can use the XMLDict package

```
    using XMLDict
    dict = parse_xml(String(response.data))  
```

You can save directly the XML String to file using LightXML

```
    xdoc = parse_string(esearch)
    save_file(xdoc, "./file.xml")
```
---

## Save EFetch Responses to a database

### MySQL 

```@docs
save_efetch_mysql(efetch_dict, db_config, verbose)
```

## SQLite

```@docs
save_efetch_sqlite(efetch_dict, db_config, verbose)
```

----

## Export EFetch Dictionary as citations

```@docs
save_article_citations(efetch_dict, config, verbose)
```

---
## Index

```@index
Modules = [BioMedQuery.PubMed]
```

## Structs and Functions

```@autodocs
Modules = [BioMedQuery.PubMed]
Order   = [:struct, :function]
```