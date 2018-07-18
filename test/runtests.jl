#
# Correctness Tests
#
using Base.Test

using XMLDict
using BioMedQuery.Processes
using BioMedQuery.PubMed
using BioMedQuery.DBUtils
using BioMedQuery
using MySQL
using SQLite
using DataStreams


my_tests = [
            ("dbutils_sqlite.jl",   "       Testing: DBUtils SQLite"),
            ("dbutils_mysql.jl",    "       Testing: DBUtils MySQL"),
            ("pubmed.jl",           "       Testing: Eutils/PubMed"),
            ("export_citations.jl", "       Testing: Export Citations"),
            ("pubmed_parse.jl",     "       Testing: Entrez Parsing"),
            ("ct.jl",               "       Testing: CLINICAL TRIALS"),
            ("processes_mysql.jl",  "       Testing: Processes MySQL"),
            ("processes_sqlite.jl", "       Testing: Processes SQLite")
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
