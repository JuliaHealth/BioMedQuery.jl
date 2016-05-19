using XMLconvert
using Base.Test


### CT
using NLM.CT
using ZipFile

query = Dict("term" => "acne", "age"=>0)
fout= "./test_CT_search.zip"
status = CT.search_ct(query, fout;)

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
