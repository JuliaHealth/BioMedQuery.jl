Julia interface to [Entrez Utilities API](http://www.ncbi.nlm.nih.gov/books/NBK25501/).

For executables that use this package to search PubMed, see the sister package [PubMedMiner](https://github.com/bcbi/PubMedMiner.jl)

## Import Module
```
using BioMedQuery.Entrez
```

The following E-utils functions have been implemented:

- [ESearch](#esearch)
- [EFetch](#efetch)
- [ELink](#elink)
- [ESummary](#esummary)

The following utility functions are available to handle and store NCBI responses

- [EParse](#eparse) - Convert XML response to Julia Dict
- [Saving NCBI Responses to XML](@ref)
- [Saving EFetch to a SQLite database](@ref)
- [Saving EFetch to a MySQL database](@ref)

The following utility functions are available to query the database

- [All PMIDs](@ref)
- [All MESH descriptors for an article](@ref)


## ESearch

```@meta
CurrentModule = BioMedQuery.Entrez
```

```@docs
esearch(search_dic)
```

## EFetch

```@docs
efetch(fetch_dic, id_list)
```

## ELink
```@docs
elink(elink_dict)
```

## ESummary
```@docs
esummary(esummary_dict)
```

## EParse
```@docs
eparse(ncbi_response::String)
```

## Saving NCBI Responses to XML

You can save directly the XML String to file using the
[XMLconvert Package](https://github.com/bcbi/XMLconvert.jl)

### Example

```
    XMLconvert.xmlASCII2file(efetch_response, "./efetch.xml")
```

## Saving EFetch to a SQLite database

```@docs
save_efetch_sqlite(efetch_dict, db_config, verbose)
```
## Saving EFetch to a MySQL database

```@docs
save_efetch_mysql(efetch_dict, db_config, verbose)
```

The following schema has been used to store the results.
If you are interested in having this module store additional fields, feel free
to open an issue

![alt](https://github.com/bcbi/BioMedQuery.jl/blob/master/docs/src/images/save_efetch_schema.jpeg)

## All PMIDs

```@docs
all_pmids(db)
```

## All MESH descriptors for an article
```@docs
get_article_mesh(db, pmid::Integer)
```
