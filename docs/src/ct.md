Submit and save queries to [clinicaltrials.gov](https://clinicaltrials.gov/)

##Import
```
using NLM.CT
```

## Search and save

### Create a query:

```
query = Dict("term" => "acne", "age"=>Int(CT.child), "locn" => "New York, NY")
```
Note: The term can also indicate joint searches, e.g.

```
"term" => "aspirin OR ibuprofen"
```

### Submit and save:

```
fout= "./test_CT_search.zip"
status = NLM.CT.search_ct(query, fout;)
```
