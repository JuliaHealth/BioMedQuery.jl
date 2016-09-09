using BioMedQuery.Entrez


#convert to a dictionary
efetch_dict = eparse_from_file("efetch_sample.xml")

articles = []

# Decide type of article based on structrure of efetch
if haskey(efetch_dict, "PubmedArticle")
    articles = efetch_dict["PubmedArticle"]
else
    error("Not a PubMed search")
end


for (i, xml_article) in enumerate(articles)


    article = PubMedArticle(xml_article)
    #PMIDs should not be null
    @test !isnull(article.pmid)
    mesh_heading_list = MeshHeadingList(xml_article)

    for heading in mesh_heading_list
        @test !isnull(heading.descriptor_name)
    end

    if i==1
        @test article.title.value == "Five Tips to Building a Successful Sleep Practice."
        @test article.pmid.value == 27483622
        @test article.authors[1][:LastName].value == "Poss"
        @test mesh_heading_list[1].descriptor_name.value == "bruxism"
        @test length(mesh_heading_list)== 6
    end
end
