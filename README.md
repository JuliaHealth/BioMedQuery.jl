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
- [UML REST API](#uml) - https://documentation.uts.nlm.nih.gov/rest/home.html
- Clinical Trials - https://clinicaltrials.gov/

### Installation
```{Julia}
Pkg.clone("https://github.com/bcbi/NLM.jl.git")
```

#Entrez

API details at  http://www.ncbi.nlm.nih.gov/books/NBK25501/

#### ESearch
Formulate a dictionary to search PubMed for 100 articles between 2000 and 2012
with obesity indicated as the major MeSH descriptor.


`search_dic = Dict("db"=>"pubmed","term" => "obesity",
 "retstart" => 0, "retmax"=>100, "tool" =>"BioJulia",
 "email" => email, "mindate"=>"2000","maxdate"=>"2012" )`

Use esearch

` esearch_response = esearch(search_dic)`

Convert response-xml to dictionary

`esearch_dict = eparse(esearch_response)`  

#### EFetch
Retrieve the list of ID's returned by esearch

    if !haskey(esearch_dict, "IdList")
        error("Error: IdList not found")
    end

    ids = []
    for id_node in esearch_dict["IdList"][1]["Id"]
        push!(ids, id_node)
    end

Define the fetch dictionary

```fetch_dic = Dict("db"=>"pubmed","tool" =>"BioJulia", "email" => email, "retmode" => "xml", "rettype"=>"null")
efetch_response = efetch(fetch_dic, ids)```

Convert response-xml to dictionary

`efetch_dict = eparse(efetch_response)`

Optional - save the results of an entrez fetch to a sqlite database

`db = save_efetch(efetch_dict, db_path)`

#uml
