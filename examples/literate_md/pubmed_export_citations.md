```@meta
EditURL = "https://github.com/TRAVIS_REPO_SLUG/blob/master/../../julia-local-packages/BioMedQuery/examples/literate_src/pubmed_export_citations.jl"
```

# Export PubMed Citations

BioMedQuery has functions to search PubMed for PMIDs and save the xml data
as either a BibTex or EndNote citation.

Here we export EndNote/BibTex citations from a PMID or a list of PMIDs. If you need
to search Entrez/PubMed and save the results as citations, refer to Examples / PubMed Search and Save.

### Set Up

```@example pubmed_export_citations
using BioMedQuery.Processes
```

The functions require a directory to save the citation files to

```@example pubmed_export_citations
results_dir = "./results";

if !isdir(results_dir)
     mkdir(results_dir)
end
```

For this example, the below PMIDs are searched and saved as citations

```@example pubmed_export_citations
pmid = 11748933;
pmid_list = [24008025, 24170597];
```

### Export as an EndNote library file

Saving one PMID's citaiton as an EndNote file

```@example pubmed_export_citations
enw_file = results_dir * "/11748933.enw";
export_citation(pmid, "endnote", enw_file);
```

Saving two PMIDs' citations as an EndNote file

```@example pubmed_export_citations
enw_file = results_dir * "/pmid_list.enw";
export_citation(pmid_list, "endnote", enw_file);
```

#### Explore one of the output files

```@example pubmed_export_citations
println(readstring(enw_file))
```

### Export as a Bibtex file

Saving one PMID's citation as a BibTex file

```@example pubmed_export_citations
bib_file = results_dir * "/11748933.bib";
export_citation(pmid, "bibtex", bib_file);
```

Saving two PMIDs' citations as a BibTex file

```@example pubmed_export_citations
bib_file = results_dir * "/pmid_list.bib";
export_citation(pmid_list, "bibtex", bib_file);
```

#### Explore one of the output files

```@example pubmed_export_citations
println(readstring(bib_file))
```

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

