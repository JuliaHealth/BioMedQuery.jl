# BioMedQuery

[![Latest Release](https://img.shields.io/github/release/bcbi/BioMedQuery.jl.svg?style=flat-square)](https://github.com/bcbi/BioMedQuery.jl/releases/latest)
[![MIT license](https://img.shields.io/badge/license-MIT-green.svg?style=flat-square)](https://github.com/bcbi/BioMedQuery.jl/blob/master/LICENSE)
![Lifecycle](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg?style=flat-square)
![Bors Enabled](https://bors.tech/images/badge_small.svg)

BioMedQuery is tested against Julia `1.X` on Linux, and OS X.

| Latest CI Build |
|:-----------:|
| [![Tests](https://badges.herokuapp.com/travis/bcbi/BioMedQuery.jl?branch=master&label=tests)](https://travis-ci.org/bcbi/BioMedQuery.jl) [![Code Coverage](https://codecov.io/gh/bcbi/BioMedQuery.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bcbi/BioMedQuery.jl)|


## Documentation

| Stable | Latest |  Examples |
|:-----------:|:-----------:|:-----------:|
|[![Stable documentation](https://img.shields.io/badge/docs-stable-blue.svg?style=flat-square)](https://bcbi.github.io/BioMedQuery.jl/stable)|[![Latest documentation](https://img.shields.io/badge/docs-latest-blue.svg?style=flat-square)](https://bcbi.github.io/BioMedQuery.jl/latest/)|[![nbviewer](https://img.shields.io/badge/jupyter_notebooks-nbviewer-orange.svg)](http://nbviewer.jupyter.org/github/bcbi/BioMedQuery.jl/tree/master/docs/src/notebooks/)|

## Description

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
using Pkg
Pkg.add("BioMedQuery")
```

To use the latest **development** version:


```julia
using Pkg
Pkg.add("BioMedQuery#master")
```

To checkout the latest **development** version:

```julia
using Pkg
Pkg.dev("BioMedQuery")
```
