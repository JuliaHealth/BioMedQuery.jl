#
# Correctness Tests
#
if VERSION >= v"0.5.0-"
    using Base.Test
else
    using BaseTestNext
    const Test = BaseTestNext
end

using XMLconvert
using BioMedQuery
using SQLite
using DataStreams

my_tests = ["entrez_sqlite.jl",
            "entrez_mysql.jl",
            "entrez.jl",
            "ct.jl",
            "umls.jl"]

println("Running tests:")

for my_test in my_tests
    @printf " * %s\n" my_test
    include(my_test)
end
