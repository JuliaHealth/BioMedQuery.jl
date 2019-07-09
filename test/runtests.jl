#
# Correctness Tests
#
using Test

# Hack: force the loading of MbedTLS as otherwise it conflicts with the version in LibCURL
# Entropy() was chosen as a fairly quick exported function
using MbedTLS
MbedTLS.Entropy()

using XMLDict
using BioMedQuery.Processes
using BioMedQuery.PubMed
using BioMedQuery.DBUtils
using BioMedQuery
using MySQL
using SQLite
using DataStreams


#For now this corresponds to JULIACIBot... since we aren't testing anywhere else
global CI = get(ENV, "CI", "false")=="true"
global TRAVIS = get(ENV, "TRAVIS", "false")=="true"
println("CI = ", CI, ", TRAVIS = ", TRAVIS)
global CI_SKIP_MYSQL = false

if CI == true && TRAVIS == false
     CI_SKIP_MYSQL = true
     @warn("MySQL tests not running")
end

all_tests = [
            ("dbutils_sqlite.jl",   "       Testing: DBUtils SQLite"),
            ("pubmed.jl",           "       Testing: Eutils/PubMed"),
            ("export_citations.jl", "       Testing: Export Citations"),
            ("pubmed_parse.jl",     "       Testing: Entrez Parsing"),
            ("ct.jl",               "       Testing: CLINICAL TRIALS"),
            ("processes_sqlite.jl", "       Testing: Processes SQLite"),
            ("processes_df.jl",     "       Testing: Processes DataFrame")
            ]
if !CI_SKIP_MYSQL
    push!(all_tests, ("dbutils_mysql.jl",    "       Testing: DBUtils MySQL"))
    push!(all_tests, ("processes_mysql.jl",  "       Testing: Processes MySQL"))
end
println("Running tests:")

for (test, test_string) in all_tests
    println("-----------------------------------------")
    println("-----------------------------------------")
    println(test_string)
    println("-----------------------------------------")
    println("-----------------------------------------")

    include(test)
end
