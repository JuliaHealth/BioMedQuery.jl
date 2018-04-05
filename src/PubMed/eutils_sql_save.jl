using ..DBUtils
using SQLite
using MySQL

"""
pubmed_save_efetch(efetch_dict, conn)

Save the results (dictionary) of an entrez-pubmed fetch to the input database.
"""
function save_efetch!(conn::Union{MySQL.Connection, SQLite.DB}, efetch_dict, verbose=false)

    #Decide type of article based on structrure of efetch
    articles = nothing
    if haskey(efetch_dict, "PubmedArticle")
        TypeArticle = PubMedArticle
        articles = efetch_dict["PubmedArticle"]
    else
        println(efetch_dict)
        error("Save efetch is only supported for PubMed searches")
    end

    println("Saving " , length(articles) ,  " articles to database")
    for xml_article in articles
        article = TypeArticle(xml_article)
        # println("=============Article=====================")
        # println(article)
        db_insert!(conn, article, verbose)

        #-------MeshHeadingList
        mesh_heading_list = MeshHeadingList(xml_article)
        db_insert!(conn, article.pmid.value, mesh_heading_list, verbose)
    end

    conn
end

"""
save_pmids!(conn, pmids::Vector{Int64}, verbose::Bool=false)

Save a list of PMIDS into input database.
###Arguments:

* `conn`: Database connection (MySQL or SQLite)
* `pmids`: Array of PMIDs
* `verbose`: Boolean to turn on extra print statements
"""
function save_pmids!(conn, pmids::Vector{Int64}, verbose::Bool=false)
       
    for pmid in pmids
        insert_row!(conn,
                    "article",
                    Dict(:pmid=> pmid),
                    verbose )
    end

end
