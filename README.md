<!--
@Author: isa
@Date:   2016-05-13T16:37:00-04:00
@Last modified by:   isa
@Last modified time: 2016-05-19T16:12:10-04:00
-->



# BioMedQuery


| Travis CI | Coverage | License | Documentation|
|-----------|----------|---------|--------------|
| [![Build&Test Status](https://travis-ci.org/bcbi/BioMedQuery.jl.svg?branch=master)](https://travis-ci.org/bcbi/BioMedQuery.jl)| [![codecov](https://codecov.io/gh/bcbi/BioMedQuery.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bcbi/BioMedQuery.jl)|[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/bcbi/BioMedQuery.jl/master/LICENSE.md) | [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://bcbi.github.io/BioMedQuery.jl/stable) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://bcbi.github.io/BioMedQuery.jl/latest)

Julia utilities to process and save results from BioMedical databases/APIs. 

[BioServices.jl](https://github.com/BioJulia/BioServices.jl) (part of BioJulia) provides the basic interface to some of the APIs, while BioMedQuery helps parse and save results into MySQL, SQLite, DataFrames etcs. 

Supported APIs include:

**National Library of Medicine (NLM)**

* Entrez Programming Utilities [(E-Utilities)](http://www.ncbi.nlm.nih.gov/books/NBK25501/)
* Unified Medical Language System [(UMLS)](https://uts.nlm.nih.gov//license.html)
* Clinical Trials [(clinicaltrials.gov)](https://clinicaltrials.gov/)


## Installation

BioMedQuery is a registered package. To install the latest **stable version**, use the package manager.

```julia
Pkg.add("BioMedQuery")
```

To checkout the current master (development) branch:

```julia
Pkg.checkout("BioMedQuery")
```

### Note:

This package has recently undergone significant changes. EUtils and UMLs APIs are now part of [BioServices.jl](https://github.com/BioJulia/BioServices.jl) (part of BioJulia) provides the basic interface to some of the APIs, while BioMedQuery helps parse and save results into MySQL, SQLite, DataFrames etcs. The old master is now tag v0.2.3-depracate. 
