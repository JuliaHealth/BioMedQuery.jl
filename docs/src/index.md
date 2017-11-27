# BioMedQuery Julia Package

Julia utilities to process and save results from BioMedical databases/APIs. 

[BioServices.jl](https://github.com/BioJulia/BioServices.jl) (part of BioJulia) provides the basic interface to the APIs, while BioMedQuery helps parse and save results into MySQL, SQLite, DataFrames etcs. 

Supported databases/APIS include:

**National Library of Medicine (NLM)**

* Entrez Programming Utilities [(E-Utilities)](http://www.ncbi.nlm.nih.gov/books/NBK25501/)
* Unified Medical Language System [(UMLS)](https://uts.nlm.nih.gov//license.html)
* Clinical Trials [(clinicaltrials.gov)](https://clinicaltrials.gov/)


## Installation

BioMedQuery is a registered package. To install the latest stable version, use the package manager.

```
Pkg.add("BioMedQuery")
```

## Sister Packages

- [PubMedMiner](https://github.com/bcbi/PubMedMiner.jl) - Examples of comorbidity studies using PubMed artciles

