# BioMedQuery Julia Package

Julia utilities to process and save results from BioMedical databases/APIs.

[BioServices.jl](https://github.com/BioJulia/BioServices.jl) (part of BioJulia) provides the basic interface to some of the APIs, while BioMedQuery helps parse and save results into MySQL, SQLite, DataFrames, CSV etc.

Supported APIs include:

**National Library of Medicine (NLM)**

* Entrez Programming Utilities [(E-Utilities)](http://www.ncbi.nlm.nih.gov/books/NBK25501/)
* Unified Medical Language System [(UMLS)](https://uts.nlm.nih.gov//license.html)
* Clinical Trials [(clinicaltrials.gov)](https://clinicaltrials.gov/)
* MEDLINE [(PubMed MEDLINE)](https://www.nlm.nih.gov/databases/download/pubmed_medline.html)


## Installation

BioMedQuery is a registered package. To install the latest **stable version**, use the package manager.

```{Julia}
using Pkg
Pkg.add("BioMedQuery")
```

To use the latest **development** version:


```{Julia}
using Pkg
Pkg.add("BioMedQuery#master")
```

To checkout the latest **development** version:

```{Julia}
using Pkg
Pkg.dev("BioMedQuery")
```

## Related Packages

| Function                                | Description                   |
| :-------                                | :----------                   |
|[BioServices.jl](https://github.com/BioJulia/BioServices.jl)| Interface to EUtils and UMLS APIs|
|[PubMedMiner.jl](https://github.com/bcbi/PubMedMiner.jl) | Examples of comorbidity studies using PubMed articles|
