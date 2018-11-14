```@meta
EditURL = "https://github.com/TRAVIS_REPO_SLUG/blob/master/"
```

# Export PubMed Citations

[![nbviewer](https://img.shields.io/badge/jupyter_notebook-nbviewer-orange.svg)](http://nbviewer.jupyter.org/github/bcbi/BioMedQuery.jl/tree/master/docs/src/notebooks/4_pubmed_export_citations.ipynb)
BioMedQuery has functions to search PubMed for PMIDs and save the xml data
as either a BibTex or EndNote citation.

Here we export EndNote/BibTex citations from a PMID or a list of PMIDs. If you need
to search Entrez/PubMed and save the results as citations, refer to Examples / PubMed Search and Save.

### Set Up

```@example 4_pubmed_export_citations
using BioMedQuery.Processes
```

The functions require a directory to save the citation files to

```@example 4_pubmed_export_citations
results_dir = ".";

if !isdir(results_dir)
     mkdir(results_dir)
end
```

For this example, the below PMIDs are searched and saved as citations

```@example 4_pubmed_export_citations
pmid = 11748933;
pmid_list = [24008025, 24170597];
```

### Export as an EndNote library file

Saving one PMID's citaiton as an EndNote file

```@example 4_pubmed_export_citations
enw_file = results_dir * "/11748933.enw";
export_citation(pmid, "endnote", enw_file);
```

Saving two PMIDs' citations as an EndNote file

```@example 4_pubmed_export_citations
enw_file = results_dir * "/pmid_list.enw";
export_citation(pmid_list, "endnote", enw_file);
```

#### Explore one of the output files

```@example 4_pubmed_export_citations
println(read(enw_file, String))
```

### Export as a Bibtex file

Saving one PMID's citation as a BibTex file

```@example 4_pubmed_export_citations
bib_file = results_dir * "/11748933.bib";
export_citation(pmid, "bibtex", bib_file);
```

Saving two PMIDs' citations as a BibTex file

```@example 4_pubmed_export_citations
bib_file = results_dir * "/pmid_list.bib";
export_citation(pmid_list, "bibtex", bib_file);
```

#### Explore one of the output files

```@example 4_pubmed_export_citations
println(read(bib_file, String))
```

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

