using Documenter, BioMedQuery
using Literate

# compile all examples in BioMedQuery/examples/literate_src into markdown and jupyter notebooks for documentation
for (root, dirs, files) in walkdir("examples/literate_src")
    for file in files
        Literate.notebook(joinpath(root,file), joinpath(@__DIR__, "src", "notebooks"))
    end
end

for (root, dirs, files) in walkdir("examples/literate_src")
    for file in files
        Literate.markdown(joinpath(root,file), joinpath(@__DIR__, "src", "examples"))
    end
end

makedocs()

deploydocs(
    deps   = Deps.pip("mkdocs==1.0.2", "mkdocs-material==3.0.3"),
    repo = "github.com/bcbi/BioMedQuery.jl.git",
    julia  = "0.7",
    osname = "linux"
)
