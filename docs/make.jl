using Documenter, BioMedQuery
using Literate

# compile all examples in BioMedQuery/examples/literate_src into markdown for docs using Literate
for (root, dirs, files) in walkdir("../examples/literate_src")
    for file in files
        Literate.markdown(joinpath(root,file), joinpath(@__DIR__, "src", "examples"))
    end
end

makedocs()

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math", "mkdocs-material"),
    repo = "github.com/bcbi/BioMedQuery.jl.git",
    julia  = "0.6",
    osname = "linux"
)
