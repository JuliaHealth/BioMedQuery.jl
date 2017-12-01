The repository contains an [examples folder](https://github.com/bcbi/BioMedQuery.jl/tree/master/examples)
with jupyter notebooks demonstrating how to use BioMedQuery's pre-assembled high-level processes and workflows.

**Note: ** When working with the notebooks, a corresponding julia script is generated automatically on every save. For this feature to work properly, make sure you have `nbconvert` installed.

The following examples are available:

| Example                                 | Description                   |
| :-------                                | :----------                   |
| [Search and Save PubMed Queries](./example1.md) | Search pubmed, parse results and store using MySQL or SQLite backend, or export to a  citation library|
| [Build MESH-UMLS map](./example2.md) | For all MeSH descriptors in a given database, build a table to match them to their UMLS concept|
| [Occurrence Matrix](./example3.md) | Build a occurrence matrix indicating papers associated with MeSH descriptors of a given UMLS concept |
| [Exporting Citations](./example4.md) | Export the citation for one or more PMIDs to a Endnote/Bibtex file|

