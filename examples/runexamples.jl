all_examples = [
    ("pubmed_export_citations.jl",   " Running Example: Export Citations"),
    ("pubmed_search_and_save.jl",    " Running Example: Search and Save"),
    ("pubmed_mesh_to_umls_map.jl",   " Running Example: MeSH/UMLS Map"),
    ("umls_semantic_occurrences.jl", " Running Example: Semantic Filtering")
    ]

println("Running examples:")

for (example, str) in all_examples
    println("-----------------------------------------")
    println("-----------------------------------------")
    println(str)
    println("-----------------------------------------")
    println("-----------------------------------------")

    include(example)
end
