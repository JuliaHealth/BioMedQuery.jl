
Submit and save queries to [clinicaltrials.gov](https://clinicaltrials.gov/)


##Import


```
using NLM.CT
```


<a id='Search-and-save-1'></a>

## Search and save


<a id='Create-a-query:-1'></a>

### Create a query:


```
query = Dict("term" => "acne", "age"=>Int(CT.child), "locn" => "New York, NY")
```


Note: The term can also indicate joint searches, e.g.


```
"term" => "aspirin OR ibuprofen"
```


<a id='Submit-and-save:-1'></a>

### Submit and save:


```
fout= "./test_CT_search.zip"
status = NLM.CT.search_ct(query, fout;)
```

