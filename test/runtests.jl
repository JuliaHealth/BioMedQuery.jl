#
# Correctness Tests
#
using Base.Test

using XMLDict
using BioMedQuery.Processes
using BioMedQuery.PubMed
using BioMedQuery.DBUtils
using MySQL
using SQLite
using DataStreams

my_tests = [
            # ("dbutils_sqlite.jl",   "       Testing: DBUtils SQLite"),
            # ("dbutils_mysql.jl",    "       Testing: DBUtils MySQL"),
            ("pubmed.jl",           "       Testing: Eutils/PubMed")
            # ("pubmed_types.jl",     "       Testing: Entrez Types"),
            # ("ct.jl",               "       Testing: CLINICAL TRIALS"),
            # ("processes_mysql.jl",  "       Testing: Processes MySQL"),
            # ("processes_sqlite.jl", "       Testing: Processes SQLite"),
            # ("export_citations.jl", "       Testing: Export Citations")
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
