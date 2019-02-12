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

# make assets dir if doesn't exist
assets_dir = joinpath(@__DIR__,"src","assets")
if !isdir(assets_dir)
    mkdir(assets_dir)
end

base_url = "https://raw.githubusercontent.com/bcbi/code_style_guide/master/assets/"

# get/replace favicon
favicon_url = base_url*"favicon.ico"
favicon_path = joinpath(assets_dir,"favicon.ico")
run(`curl -g -L -f -o $favicon_path $favicon_url`)

# get/replace css
css_url = base_url*"bcbi.css"
css_path = joinpath(assets_dir,"bcbi.css")
run(`curl -g -L -f -o $css_path $css_url`)

# get/replace logo
logo_url = base_url*"bcbi-white-v.png"
logo_path = joinpath(assets_dir,"logo.png")
run(`curl -g -L -f -o $logo_path $logo_url`)

makedocs(
    modules = [ BioMedQuery],
    assets = [
        "assets/favicon.ico",
        "assets/bcbi.css",
        "assets/logo.png"
        ],
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
