<!--
@Author: isa
@Date:   2016-05-13T16:37:00-04:00
@Last modified by:   isa
@Last modified time: 2016-05-19T16:12:10-04:00
-->



# NLM
## Utilities to interact with databases/APIs provided by the National Library of Medicine (NLM)
[![Build Status](https://travis-ci.org/bcbi/NLM.jl.svg?branch=master)](https://travis-ci.org/bcbi/NLM.jl)
Supported databases/APIS include:

- [Entrez Programming Utilities (E-utilities)](#entrez)
- [Unified Medical Language System (UMLS)](#umls)
- [Clinical Trials](#clinical-trials)

### Installation
```{Julia}
Pkg.clone("https://github.com/bcbi/NLM.jl.git")
```

###Entrez

API details at  http://www.ncbi.nlm.nih.gov/books/NBK25501/

#### ESearch
- Formulate a dictionary to search PubMed for 100 articles between 2000 and 2012
with obesity indicated as the major MeSH descriptor.


 `search_dic = Dict("db"=>"pubmed","term" => "obesity",
  "retstart" => 0, "retmax"=>100, "tool" =>"BioJulia",
  "email" => email, "mindate"=>"2000","maxdate"=>"2012" )`

- Use esearch

 ` esearch_response = esearch(search_dic)`

- Convert response-xml to dictionary

 `esearch_dict = eparse(esearch_response)`  

#### EFetch
- Retrieve the list of ID's returned by esearch

    if !haskey(esearch_dict, "IdList")
        error("Error: IdList not found")
    end

    ids = []
    for id_node in esearch_dict["IdList"][1]["Id"]
        push!(ids, id_node)
    end

- Define the fetch dictionary

 ```fetch_dic = Dict("db"=>"pubmed","tool" =>"BioJulia", "email" => email, "retmode" => "xml", "rettype"=>"null")
 efetch_response = efetch(fetch_dic, ids)```

- Convert response-xml to dictionary

 `efetch_dict = eparse(efetch_response)`

- Optional - save the results of an entrez fetch to a sqlite database

 `db = save_efetch(efetch_dict, db_path)`

###UMLS
Search Unified Medical Language System. For more details on the REST API see https://documentation.uts.nlm.nih.gov/rest/home.html

####Import
`using NLM.umls`

#### Search by term

Search UMLS using the Rest API. The user needs approved credentials and a query dictionary.

- To create credentials

```import NLM.umls:Credentials
credentials = Credentials(user, psswd)```

- To compose the query

`query = Dict("string"=>term, "searchType"=>"exact" )`

- To search all concepts associeted with the indicated term

`all_results= search_umls(credentials, query)`

#### Get best CUI

- To retrive the CUI for the rest match

`cui = best_match_cui(all_results, term)`

#### Get UMLS concepts associated with a CUI

`all_concepts = get_concepts(c, cui)`

###Clinical Trials

Submit and save queries to  https://clinicaltrials.gov/

#### Importing
`using NLM.CT`

#### Search and save

- Create a query, for instance:

`query = Dict("term" => "acne", "age"=>Int(CT.child), "locn" => "Providence, RI")`

Note: The term can also indicate joint searches, e.g.

 `"term" => "aspirin OR ibuprofen"`
 
- Submit query and save to a specified location

```fout= "./test_CT_search.zip"
status = NLM.CT.search_ct(query, fout;)```


