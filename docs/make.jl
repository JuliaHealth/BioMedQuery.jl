using Documenter, BioMedQuery

makedocs()

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math", "mkdocs-material"),
    repo = "github.com/bcbi/BioMedQuery.jl.git",
    julia  = "0.4",
    osname = "osx"
)
