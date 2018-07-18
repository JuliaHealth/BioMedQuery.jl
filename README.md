<!--
@Author: isa
@Date:   2016-05-13T16:37:00-04:00
@Last modified by:   isa
@Last modified time: 2016-05-19T16:12:10-04:00
-->



# BioMedQuery


| Travis CI | Coverage | License | Documentation| Examples|
|:-----------:|:----------:|:---------:|:--------------:|:--------------:|
| [![](https://travis-ci.org/bcbi/BioMedQuery.jl.svg?branch=master)](https://travis-ci.org/bcbi/BioMedQuery.jl)[![](https://badges.herokuapp.com/travis/bcbi/BioMedQuery.jl?branch=master&env=GROUP=Test&label=Tests)](https://travis-ci.org/bcbi/BioMedQuery.jl)[![](https://badges.herokuapp.com/travis/bcbi/BioMedQuery.jl?branch=master&env=GROUP=Examples&label=Examples)](https://travis-ci.org/bcbi/BioMedQuery.jl)| [![codecov](https://codecov.io/gh/bcbi/BioMedQuery.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bcbi/BioMedQuery.jl)|[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/bcbi/BioMedQuery.jl/master/LICENSE.md) | [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://bcbi.github.io/BioMedQuery.jl/stable) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://bcbi.github.io/BioMedQuery.jl/latest) | [![nbviewer](https://img.shields.io/badge/jupyter_notebooks-nbviewer-orange.svg)](http://nbviewer.jupyter.org/github/bcbi/BioMedQuery.jl/tree/master/docs/src/notebooks/)


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

```julia
Pkg.add("BioMedQuery")
```

To checkout the current master (development) branch:

```julia
Pkg.checkout("BioMedQuery")
```

