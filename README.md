<!--
@Author: isa
@Date:   2016-05-13T16:37:00-04:00
@Last modified by:   isa
@Last modified time: 2016-05-19T16:12:10-04:00
-->



# BioMedQuery

## Master branch has changed significantly! Old master is now tag v0.2.3-depracate. Documentation updates are ongoing


| Travis CI | Coverage | License | Documentation|
|-----------|----------|---------|--------------|
| [![Build&Test Status](https://travis-ci.org/bcbi/BioMedQuery.jl.svg?branch=master)](https://travis-ci.org/bcbi/BioMedQuery.jl)| [![codecov](https://codecov.io/gh/bcbi/BioMedQuery.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/bcbi/BioMedQuery.jl)|[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/bcbi/BioMedQuery.jl/master/LICENSE.md) | [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://bcbi.github.io/BioMedQuery.jl/stable) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://bcbi.github.io/BioMedQuery.jl/latest)

Julia utilities to interact with BioMedical Databases and APIs.
Supported databases/APIS include:

#### National Library of Medicine (NLM)
- Entrez Programming Utilities (E-utilities)
- Unified Medical Language System (UMLS)
- Clinical Trials

## Installation

Stable:

```{Julia}
Pkg.add("BioMedQuery")
```

Master (development) branch:

```{Julia}
Pkg.checkout("BioMedQuery")
```
