# BioMedQuery Julia Package

Julia utilities to interact with BioMedical databases/APIs. Supported
databases/APIS include:

**National Library of Medicine (NLM)**

* Entrez Programming Utilities [(E-Utilities)](http://www.ncbi.nlm.nih.gov/books/NBK25501/)
* Unified Medical Language System [(UMLS)](https://uts.nlm.nih.gov//license.html)
* Clinical Trials [(clinicaltrials.gov)](https://clinicaltrials.gov/)


## Installation
```
Pkg.clone("https://github.com/bcbi/BioMedQuery.jl.git")
```


## Dependencies

###Registered Packages - automatically installed

- ArgParse
- SQLite
- Gumbo
- Requests
- DataStreams
- LightXML
- Requests
- HttpCommon
- BaseTestNext

### Unregistered Packages - need to be installed manually

####XMLconvert
```
Pkg.clone("https://github.com/bcbi/XMLconvert.jl.git")
```

## Sister Packages

- [PubMedMiner](https://github.com/bcbi/PubMedMiner.jl) - Executables to search PubMed, link Mesh Descriptors to to UMLS concepts and visualize results.
- [XMLConvert](https://github.com/bcbi/XMLconvert.jl) - Utilities to convert, flatten and explore XML file. Useful to investigate server responses.
