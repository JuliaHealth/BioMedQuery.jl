```@meta
CurrentModule = BioMedQuery.UMLS
```

Search the Unified Medical Language System (UMLS), for more details visit the [REST API](https://documentation.uts.nlm.nih.gov/rest/home.html).

Searching the UMLS requires approved credentials.
You can sign up [here]](https://uts.nlm.nih.gov//license.html)

##Import
```
using BioMedQuery.UMLS
```

## Credentials

```@docs
Credentials
```

## Search the UMLS

```@docs
search_umls(c::Credentials, query)
```

## Best match CUI

```@docs
 best_match_cui(all_results)
```

## Semantic types of a CUI

```@docs
get_semantic_type(c::Credentials, cui)
```
