
@testset "PubMed Parse" begin
    #convert to an xml doc
    efetch_sample = read("efetch_sample.xml", String)
    efetch_doc = parse_string(efetch_sample)

    articles = root(efetch_doc)

    # Decide type of article based on structrure of efetch
    if name(articles) != "PubmedArticleSet"
        error("Not a PubMed search")
    end


    parsed = PubMed.parse_articles(articles)

    @test !ismissing(parsed["basic"][1,:pmid])

    for heading in parsed["mesh_heading"][:desc_uid]
        @test !ismissing(parsed["mesh_desc"][findall(parsed["mesh_desc"][:uid] .== heading),:name][1])
    end

    @test parsed["basic"][1,:title] == "Five Tips to Building a Successful Sleep Practice."
    @test parsed["basic"][1,:pmid] == 27483622
    @test parsed["author_ref"][1,:last_name] == "Poss"
    @test parsed["mesh_desc"][findall(parsed["mesh_heading"][1,:desc_uid] .== parsed["mesh_desc"][:uid]), :name][1] == "Bruxism"
    @test size(parsed["mesh_heading"][findall(parsed["mesh_heading"][:pmid] .== parsed["basic"][1,:pmid]), :])[1]== 6
end
