#!/usr/bin/env julia

try
    if Pkg.installed("XMLconvert") == nothing
        Pkg.clone("https://github.com/bcbi/XMLconvert.jl.git")
    end
catch
    Pkg.clone("https://github.com/bcbi/XMLconvert.jl.git")
end

using XMLconvert
using NLM
using Base.Test

Pkg.add("ZipFile")
using ZipFile

#------------------Clinical Trials -------------------
query = Dict("term" => "acne", "age"=>0)
fout= "./test_CT_search.zip"
status = NLM.CT.search_ct(query, fout;)

#minimal test - http response succeded
@test status == 200

#test all files are .xml
not_xml = false
r = ZipFile.Reader(fout);
for f in r.files
    if Base.search(f.name, ".xml") == 0:-1
      not_xml = true
      break
    end
end

@test not_xml == false

#remove test file
if isfile(fout)
    rm(fout)
end

#------------------ NLM -------------------

cred_file = "../credentials.txt"
println(readdir("./"))
println(readdir("../"))
if isfile(cred_file)
    cred = open(cred_file)
    lines = readlines(cred)
    println(lines[1])
else
    println("NLM tests require credentials file:")
    println("NLM/credentials.txt")
    println("Line 1: email")
    println("Line 2: umls-user")
    println("Line 2: umls-passwd")
    @test 1==2
end
