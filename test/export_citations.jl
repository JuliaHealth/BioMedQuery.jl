using BioMedQuery.Processes

#************************ LOCALS TO CONFIGURE!!!! **************************


email= ENV["NCBI_EMAIL"] #This is an enviroment variable that you need to setup
citation_type="endnote"
pmid = 11748933
output_file1="11748933.enw"

pmid_list = [24008025, 24170597]
output_file2 = "pmid_list.enw"

#***************************************************************************
export_citation(email, pmid, citation_type, output_file1)
export_citation(email, pmid_list, citation_type, output_file2)


@testset "Export Citations" begin
    println("-----------------------------------------")
    println("       Export Citations")
    #Read back the files and do minimal testing
    ref_lines=[]
    open("./11748933.enw") do f
       ref_lines = readlines(f)
    end


    @test ref_lines[1]== "%0 Journal Article\n"

    ref_lines=[]
    open("./pmid_list.enw") do f
       ref_lines = readlines(f)
    end

    @test ref_lines[1]== "%0 Journal Article\n"
    @test ref_lines[25]== "%0 Journal Article\n"
end


# remove temp files
if isfile(output_file1)
    rm(output_file1)
end
if isfile(output_file2)
    rm(output_file2)
end
