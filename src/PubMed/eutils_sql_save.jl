using ..DBUtils
using SQLite
using MySQL
using LightXML
using DataFrames

"""
     pubmed_save_efetch(efetch_dict, conn)

Save the results (dictionary) of an entrez-pubmed fetch to the input database.
"""
function save_efetch!(conn::Union{MySQL.Connection, SQLite.DB}, articles::LightXML.XMLElement, verbose=false, drop_csv=true)

    #Decide type of article based on structrure of efetch

    if name(articles) != "PubmedArticleSet"
        println(articles)
        error("Save efetch is only supported for PubMed searches")
    end

    println("Saving " , length(collect(child_elements(articles))) ,  " articles to database")

    parsed = PubMed.parse_articles(articles)

    db_insert!(conn, parsed, drop_csv=drop_csv)

end

"""
     save_pmids!(conn, pmids::Vector{Int64}, verbose::Bool=false)

Save a list of PMIDS into input database.
## Arguments:
* `conn`: Database connection (MySQL or SQLite)
* `pmids`: Array of PMIDs
* `verbose`: Boolean to turn on extra print statements
"""
function save_pmids!(conn, pmids::Vector{Int64}, verbose::Bool=false)

    for pmid in pmids
        insert_row!(conn,
                    "basic",
                    Dict(:pmid=> pmid),
                    verbose )
    end

end
