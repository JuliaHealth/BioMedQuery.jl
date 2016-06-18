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
-------------------------

###Entrez

API details at  http://www.ncbi.nlm.nih.gov/books/NBK25501/

#### ESearch
- Formulate a dictionary to search PubMed for 100 articles between 2000 and 2012
with obesity indicated as the major MeSH descriptor.


 ```{Julia}
 search_dic = Dict("db"=>"pubmed","term" => "obesity",
  "retstart" => 0, "retmax"=>100, "tool" =>"BioJulia",
  "email" => email, "mindate"=>"2000","maxdate"=>"2012" )
  ```

- Use esearch

 ```{Julia}
 esearch_response = esearch(search_dic)
 ```

- Convert response-xml to dictionary

 ```{Julia}
 esearch_dict = eparse(esearch_response)
 ```
 
#### EFetch
- Retrieve the list of ID's returned by esearch
    
 ```{Julia}
  if !haskey(esearch_dict, "IdList")
      error("Error: IdList not found")
  end
  
  ids = []
  for id_node in esearch_dict["IdList"][1]["Id"]
      push!(ids, id_node)
  end
  ```

- Define the fetch dictionary

 ```{Julia}
 fetch_dic = Dict("db"=>"pubmed","tool" =>"BioJulia", "email" => email, "retmode" => "xml", "rettype"=>"null")
 efetch_response = efetch(fetch_dic, ids)
 ```

- Convert response-xml to dictionary

 ```{Julia}
 efetch_dict = eparse(efetch_response)
 ```

- Optional - save the results of an entrez fetch to a sqlite database

 ```{Julia}
 db = save_efetch(efetch_dict, db_path)
 ```
-------------------------

###UMLS
Search Unified Medical Language System. For more details on the REST API see https://documentation.uts.nlm.nih.gov/rest/home.html

####Import
```{Julia}
using NLM.umls
```

#### Search by term

Search UMLS using the Rest API. The user needs approved credentials and a query dictionary.
To sign up for credentials see https://uts.nlm.nih.gov//license.html

- To create credentials

 ```{Julia}
 import NLM.UMLS:Credentials
 credentials = Credentials(user, psswd)
 ```

- To compose the query

 ```{Julia}
 query = Dict("string"=>term, "searchType"=>"exact" )
 ```

- To search all concepts associeted with the indicated term

 ```{Julia}
 all_results= search_umls(credentials, query)
 ```

#### Get best CUI

- To retrive the CUI for the rest match

 ```{Julia}
 cui = best_match_cui(all_results, term)
```
#### Get UMLS concepts associated with a CUI

```{Julia}
all_concepts = get_concepts(c, cui)
```
-------------------------

###Clinical Trials

Submit and save queries to  https://clinicaltrials.gov/

#### Importing
```{Julia}
using NLM.CT
```

#### Search and save

- Create a query, for instance:

```{Julia}
query = Dict("term" => "acne", "age"=>Int(CT.child), "locn" => "New York, NY")
```
Note: The term can also indicate joint searches, e.g.

```{Julia}
"term" => "aspirin OR ibuprofen"
```
- Submit query and save to a specified location

 ```{Julia}
 fout= "./test_CT_search.zip"
 status = NLM.CT.search_ct(query, fout;)
 ```


