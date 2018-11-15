using Documenter
using Literate
using BioMedQuery

# compile all examples in BioMedQuery/examples/literate_src into markdown and jupyter notebooks for documentation
for (root, dirs, files) in walkdir("examples/literate_src")
    for file in files
        Literate.notebook(joinpath(root,file), joinpath(@__DIR__, "src", "notebooks"), execute=false, documenter=true)
    end
end

for (root, dirs, files) in walkdir("examples/literate_src")
    for file in files
        Literate.markdown(joinpath(root,file), joinpath(@__DIR__, "src", "examples"), documenter=true)
    end
end

makedocs(
    modules = [ BioMedQuery],
    sitename = "BioMedQuery.jl",
    debug = true,
    pages = [
        "Home" => "index.md",
        "Examples" => Any[
            "Overview" => "examples.md",
            "Pubmed Search and Save" => "examples/1_pubmed_search_and_save.md",
            "MeSH/UMLS Map and Filtering" => "examples/2_umls_map_and_filter.md",
            "Export to Citations" => "examples/4_pubmed_export_citations.md",
            "Load MEDLINE" => "examples/5_load_medline.md",
        ],
        "Manual" => Any[
            "Processes/Workflows" => "processes.md",
            "PubMed" => "pubmed.md",
            "Clinical Trials" => "ct.md",
            "Database Utilities" => "dbutils.md",
            "Library" => "library.md"
            ]
        ]
    )

deploydocs(
    repo = "github.com/bcbi/BioMedQuery.jl.git",
)
