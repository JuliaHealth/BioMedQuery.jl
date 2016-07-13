using Documenter, BioMedQuery

makedocs()

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math"),
    repo = "github.com/bcbi/BioMedQuery.jl.git",
    julia  = "0.4",
    osname = "osx"
)
