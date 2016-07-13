Julia interface to [Entrez Utilities API](http://www.ncbi.nlm.nih.gov/books/NBK25501/).
For executables to search PubMed, see the sister package [PubMedMiner](https://github.com/bcbi/PubMedMiner.jl) 

The following functions have been implemented:

- [ESearch](#esearch)
- [EFetch](#efetch)
-------------------------
##Import
```
using NLM.Entrez
```

## ESearch

`Entrez.esearch` - Function

###Arguments

- `search_dic::Dict` - Dictionary specifying search criteria

###Results

- `::ASCIIString` - XML response from NCBI

###Usage Example

```
search_term = "obstructive sleep apnea[MeSH Major Topic]"
search_dic = Dict("db"=>"pubmed", "term" => search_term,
"retstart" => 0, "retmax"=>10000, "tool" =>"BioJulia",
"email" => "email")
esearch_response = esearch(search_dic)
```

####Note:
- email must be a valid email address (otherwise pubmed will block you)
- the search term corresponds to the string to submit to PubMed. It may contain one or more filtering criteria using AND/OR.
For instance:

    `(asthma[MeSH Terms]) AND ("2001/01/29"[Date - Publication] : "2010"[Date - Publication])`.
    See [NCBI-search](http://www.ncbi.nlm.nih.gov/pubmed/advanced)



### XML to dictionary
It may be useful to convert the XML string to a dictionary using [Entrez.eparse](#eparse)


## EFetch

`Entrez.efetch` - Function

Retrieves the list of ID's returned by esearch

###Arguments

- `fetch_dic::Dict` - Dictionary specifying fetch criteria
- `id_list::Array` - List of ids embedded in response from esearch

###Results

- `::ASCIIString` - XML response from NCBI

###Usage Example

####Get the list of ids

```
if !haskey(esearch_dict, "IdList")
  error("Error: IdList not found")
end

ids = []

for id_node in esearch_dict["IdList"][1]["Id"]
  push!(ids, id_node)
end
```

####Define the fetch dictionary

```
fetch_dic = Dict("db"=>"pubmed","tool" =>"BioJulia",
"email" => email, "retmode" => "xml", "rettype"=>"null")
```

####Fetch
`efetch_response = efetch(fetch_dic, ids)`

###Convert response-xml to dictionary

Use [Entrez.eparse](#eparse)

```
efetch_dict = eparse(efetch_response)
```

###Save the results to a sqlite database

Use [Entrez.save_efetch](#SaveEFetch)



##EParse
```
esearch_dict = eparse(esearch_response)
```

##SaveEFetch

`Entrez.save_efetch` - Function

###Arguments

- `efetch_dict::Dict` - Dictionary corresponding to an EFetch response
- `db_path:ASCIIString` - Path to database file. If it doesn't exist it will create one. The user is responsible for cleanning.

###Response

- `::SQLite.DB` - sqlite database, where the results have been stored

The following schema has been used to store the results. If you are interested in having this module store additional fields, feel free to open an issue

![Alt](/images/save_efetch_schema.001.jpeg)

### Usage Example
```
db = save_efetch(efetch_dict, db_path)
```
