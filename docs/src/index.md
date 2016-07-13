# NLM Julia Package

Julia langauge utilities to interact with databases/APIs provided by the National Library of Medicine (NLM)

Supported databases/APIS include:

- [Entrez Programming Utilities (E-utilities)](#entrez)
- [Unified Medical Language System (UMLS)](#umls)
- [Clinical Trials](#clinical-trials)
-------------------------

### Installation
```
Pkg.clone("https://github.com/bcbi/BioMedQuery.jl.git")
```

### Sister Packages

- [PubMedMiner](https://github.com/bcbi/PubMedMiner.jl) - Executables to search PubMed, link Mesh Descriptors to to UMLS concepts and visualize results.
- [XMLConvert](https://github.com/bcbi/XMLconvert.jl) - Utilities to convert, flatten and explore XML file. Useful to investigate server responses.
