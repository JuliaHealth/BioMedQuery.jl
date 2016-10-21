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
using BioMedQuery.Processes
using BioMedQuery.Entrez
using BioMedQuery.Entrez.DB
using BioMedQuery.DBUtils
using BioMedQuery.UMLS
using MySQL
using SQLite
using DataStreams

my_tests = [
            ("dbutils_sqlite.jl",   "       Testing: DBUtils SQLite"),
            ("dbutils_mysql.jl",    "       Testing: DBUtils MySQL"),
            ("entrez.jl",           "       Testing: ENTREZ"),
            ("entrez_types.jl",      "       Testing: Entrez Types"),
            ("ct.jl",               "       Testing: CLINICAL TRIALS"),
            ("umls.jl",             "       Testing: UMLS"),
            ("processes_mysql.jl",  "       Testing: Processes MySQL"),
            ("processes_sqlite.jl", "       Testing: Processes SQLite"),
            ("export_citations.jl", "       Testing: Export Citations")
            ]

println("Running tests:")

for (my_test, test_string) in my_tests
    println("-----------------------------------------")
    println("-----------------------------------------")
    println(test_string)
    println("-----------------------------------------")
    println("-----------------------------------------")

    include(my_test)
end
