
# Pkg.add("NBInclude")

using NBInclude

all_notebooks = [
    ("pubmed_export_citations.ipynb",   " Running Notebook: Export Citations"),
    ("pubmed_search_and_save.ipynb",    " Running Notebook: Search and Save"),
    ("pubmed_mesh_to_umls_map.ipynb",   " Running Notebook: MeSH/UMLS Map"),
    ("umls_semantic_occurrences.ipynb", " Running Notebook: Semantic Filtering")
    ]

println("Running notebooks:")

for (notebook, str) in all_notebooks
    println("-----------------------------------------")
    println("-----------------------------------------")
    println(str)
    println("-----------------------------------------")
    println("-----------------------------------------")

    nbinclude(notebook)
end