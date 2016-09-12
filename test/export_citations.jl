using BioMedQuery.Processes


email= ENV["NCBI_EMAIL"] #This is an enviroment variable that you need to setup
pmid = 11748933
pmid_list = [24008025, 24170597]


@testset "Export EndNote Citations" begin

    println("-----------------------------------------")
    println("       Export EndNote Citations")

    citation_type="endnote"
    output_file1="11748933.enw"
    output_file2 = "pmid_list.enw"

    export_citation(email, pmid, citation_type, output_file1)
    export_citation(email, pmid_list, citation_type, output_file2)

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

    # remove temp files
    if isfile(output_file1)
        rm(output_file1)
    end
    if isfile(output_file2)
        rm(output_file2)
    end
end

@testset "Export BibTEX Citation" begin
    println("-----------------------------------------")
    println("       Export BibTEX Citations")
    citation_type="bibtex"
    output_file1="11748933.bibtex"
    output_file2 = "pmid_list.bibtex"

    export_citation(email, pmid, citation_type, output_file1)
    export_citation(email, pmid_list, citation_type, output_file2)

    #Read back the files and do minimal testing
    ref_lines=[]
    open("./11748933.bibtex") do f
       ref_lines = readlines(f)
    end


    @test ref_lines[1]== "@article {PMID:11748933,\n"

    ref_lines=[]
    open("./pmid_list.bibtex") do f
       ref_lines = readlines(f)
    end

    @test ref_lines[1]== "@article {PMID:24008025,\n"
    @test ref_lines[13]== "@article {PMID:24170597,\n"

    # remove temp files
    if isfile(output_file1)
        rm(output_file1)
    end
    if isfile(output_file2)
        rm(output_file2)
    end
end
