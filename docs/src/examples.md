# Examples
The repository contains an [examples folder](https://github.com/bcbi/BioMedQuery.jl/tree/master/examples)
with scripts demonstrating how to use BioMedQuery's pre-assembled high-level processes and workflows.

The following examples are available:

| Example                                 | Description                   |
| :-------                                | :----------                   |
| [Search and Save PubMed Queries](./examples/1_pubmed_search_and_save.md) | Search PubMed, parse results, store them using a MySQL or SQLite backend, or export to a  citation library|
| [Build MeSH-UMLS map](/examples/2_pubmed_mesh_to_umls_map.md) | For all MeSH descriptors in a given database, build a table to match them to their UMLS concept|
| [Occurrence Matrix](./examples/3_umls_semantic_occurrences.md) | Build an occurrence matrix indicating articles associated with MeSH descriptors of a given UMLS concept |
| [Exporting Citations](./examples/4_pubmed_export_citations.md) | Export the citation for one or more PMIDs to an Endnote/Bibtex file|
| [Loading MEDLINE](./examples/5_load_medline.md) | Load the MEDLINE baseline files|
