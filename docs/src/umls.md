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

## Semantic Network Database

```@docs
populate_net_mysql(config; sn_version, mysql_version)
```

### Schema

The schema of the MySQL database of the semantic network is the following:

![Alt](/images/umls_sn_schema.png)


###Note:

The previous function uses the original scripts that are part of MetamorphoSys (part of the mmsys.zip
downloaded [here](https://www.nlm.nih.gov/research/umls/licensedcontent/umlsknowledgesources.html)), and the current Relational ASCII (CVS) files for the UMLS Semantic Network (obtained
[here](https://semanticnetwork.nlm.nih.gov))

For useful information on loading your Semantic Network files
into an Oracle or MySQL database, please consult the on-line
documentation at:

http://www.nlm.nih.gov/research/umls/implementation_resources/scripts/index.html
