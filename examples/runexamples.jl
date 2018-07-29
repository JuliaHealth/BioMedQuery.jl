all_examples = [
    ("literate_src/1_pubmed_search_and_save.jl",    " Running Example: Search and Save"),
    ("literate_src/2_umls_map_and_filter.jl",       " Running Example: MeSH/UMLS Map and Filter"),
    ("literate_src/4_pubmed_export_citations.jl",   " Running Example: Export Citations"),
    ("literate_src/5_load_medline.jl", " Running Example: Load MEDLINE")
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
