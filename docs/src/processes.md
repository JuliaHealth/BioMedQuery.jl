This module provides common processes/workflows when using the BioMedQuery utilities. For instance,
searching PubMed, requires calling the NCBI e-utils in a particular order. After
the search, the results are often saved to the database. This module contains pre-assembled functions
performing all necessary steps. To see sample scripts that use this processes, refer to the following [section](examples.md)

##Import

```
using BioMedQuery.Processes
```

## Index

```@index
Modules = [BioMedQuery.Processes]
```

## Functions

```@autodocs
Modules = [BioMedQuery.Processes]
Order   = [:function, :type]
```
