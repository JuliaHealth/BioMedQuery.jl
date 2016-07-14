Julia interface to [Entrez Utilities API](http://www.ncbi.nlm.nih.gov/books/NBK25501/).

For executables that use this package to search PubMed, see the sister package [PubMedMiner](https://github.com/bcbi/PubMedMiner.jl)

The following E-utils functions have been implemented:

- [ESearch](#esearch)
- [EFetch](#efetch)
- [ELink](#elink)
- [ESummary](#esummary)

In addition, the following utility functions are available to handle and store
NCBI responses

- [EParse](#eparse) : Convert XML response to Julia Dict
- [SaveEFetch](#databasesave) : Save response dictionary to a Database


##Import Module
```
using BioMedQuery.Entrez
```

## ESearch

```@meta
CurrentModule = BioMedQuery.Entrez
```

```@docs
esearch(search_dict)
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

##EParse
```@docs
eparse(ncbi_response::ASCIIString)
```

##Saving NCBI Responses to XML

You can save directly the XML String to file using the
[XMLconvert Package](https://github.com/bcbi/XMLconvert.jl)

###Example

```
    XMLconvert.xmlASCII2file(efetch_response, "./efetch.xml")
```

##SaveEFetch

```@docs
save_efetch(efetch_dict, db_path)
```

The following schema has been used to store the results.
If you are interested in having this module store additional fields, feel free
to open an issue

![Alt](/images/save_efetch_schema.001.jpeg)
