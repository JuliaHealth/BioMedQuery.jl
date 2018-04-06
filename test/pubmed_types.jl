#convert to a dictionary
efetch_sample = readstring("efetch_sample.xml")
efetch_dict = parse_xml(efetch_sample)

articles = []

# Decide type of article based on structrure of efetch
if haskey(efetch_dict, "PubmedArticle")
    articles = efetch_dict["PubmedArticle"]
else
    error("Not a PubMed search")
end


for (i, xml_article) in enumerate(articles)

    article = PubMedArticle(xml_article)
    @test !ismissing(article.pmid)
    mesh_heading_list = MeshHeadingList(xml_article)

    for heading in mesh_heading_list
        @test !ismissing(heading.descriptor_name)
    end

    if i==1
        @test article.title == "Five Tips to Building a Successful Sleep Practice."
        @test article.pmid == 27483622
        @test article.authors[1][:LastName] == "Poss"
        @test mesh_heading_list[1].descriptor_name == "Bruxism"
        @test length(mesh_heading_list)== 6
    end
end
