# Examples
The repository contains an [examples folder](https://github.com/bcbi/BioMedQuery.jl/tree/master/examples)
with scripts demonstrating how to use BioMedQuery's pre-assembled high-level processes and workflows.

The following examples are available:

| Example                                 | Description                   |
| :-------                                | :----------                   |
| [Search and Save PubMed Queries](./examples/1_pubmed_search_and_save.md) | Search PubMed, parse results, store them using a MySQL or SQLite backend, or export to a  citation library|
| [UMLS-MeSH Mapping and Filtering](./examples/2_umls_map_and_filter.md) | For all MeSH descriptors in a given data disease_occurances, build a table to match them to their UMLS concept, and filter them by UMLS concepts|
| [Exporting Citations](./examples/4_pubmed_export_citations.md) | Export the citation for one or more PMIDs to an Endnote/Bibtex file|
| [Loading MEDLINE](./examples/5_load_medline.md) | Load the MEDLINE baseline files|
