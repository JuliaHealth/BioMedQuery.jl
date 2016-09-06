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

# my_tests = [("dbutils_sqlite.jl", "       Testing: DBUtils SQLite"),
#             ("dbutils_mysql.jl",  "       Testing: DBUtils MySQL"),
#             ("entrez.jl",         "       Testing: ENTREZ"),
#             ("ct.jl",             "       Testing: CLINICAL TRIALS"),
#             ("umls.jl",           "       Testing: UMLS")]
my_tests = [("entrez.jl",         "       Testing: ENTREZ")]

println("Running tests:")

for (my_test, test_string) in my_tests
    println("-----------------------------------------")
    println("-----------------------------------------")
    println(test_string)
    println("-----------------------------------------")
    println("-----------------------------------------")

    include(my_test)
end
