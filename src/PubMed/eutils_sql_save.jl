using ..DBUtils
using SQLite
using MySQL


# """
# save_efetch_sqlite(efetch_dict, db_config, verbose)

# Save the results (dictionary) of an entrez fetch to a SQLite database.

# ###Arguments:

# * `efetch_dict`: Response dictionary from efetch
# * `db_config::Dict{Symbol, T}`: Configuration dictionary for initialitizing SQLite
# database. Must contain symbols `:db_path` and `:overwrite`
# * `verbose`: Boolean to turn on extra print statements

# ###Example

# ```julia
# db_config =  Dict(:db_path=>"test_db.slqite", :overwrite=>true)
# db = save_efetch_sqlite(efetch_dict, db_config)
# ```

# """
# function save_efetch_sqlite{T}(efetch_dict, db_path::String; verbose=false)
    
#     if haskey(efetch_dict, "PubmedArticle")
#         db = init_pubmed_db(db_path)
#         return pubmed_save_efetch!(efetch_dict, db, verbose)
#     else
#         error("Unsupported efetch save. Responses must be searches to: PubMed")
#         return nothing
#     end
# end


# function save_efetch_sqlite{T}(efetch_dict, db; verbose=false)
    
#     if haskey(efetch_dict, "PubmedArticle")
#         db = init_pubmed_db(db_path)
#         return pubmed_save_efetch!(efetch_dict, db, verbose)
#     else
#         error("Unsupported efetch save. Responses must be searches to: PubMed")
#         return nothing
#     end
# end

# """
# save_efetch_mysql(efetch_dict, db_config, verbose)

# Save the results (dictionary) of an entrez fetch to a MySQL database.

# ###Arguments:

# * `efetch_dict`: Response dictionary from efetch
# * `db_config::Dict{Symbol, T}`: Configuration dictionary for initialitizing SQLite
# database. Must contain symbols `:host`, `:dbname`, `:username`. `pswd`,
# and `:overwrite`
# * `verbose`: Boolean to turn on extra print statements


# ###Example

# ```julia
# db_config =  Dict(:host=>"localhost", :dbname=>"test", :username=>"root",
# :pswd=>"", :overwrite=>true)
# db = save_efetch_mysql(efetch_dict, db_config)
# ```

# """
# function save_efetch_mysql{T}(efetch_dict, db_config::Dict{Symbol, T}, verbose=false)

#     if haskey(efetch_dict, "PubmedArticle")
#         db = init_pubmed_db(db_config[:host], db_config[:username], db_config[:pswd], db_config[:dbname])
#         # init_mysql_database(host = config[:host], dbname =config[:dbname],
#         #        username = config[:username], pswd= config[:pswd],
#         #        overwrite = config[:overwrite], mysql_code = mysql_code)
#         pubmed_save_efetch!(efetch_dict, db, verbose)
#         return db
#     else
#         error("Unsupported efetch save. Responses must be searches to: PubMed")
#         return nothing
#     end
# end


# """
#  save_efetch_mysql(efetch_dict, con::MySQL.MySQLHandle, clean_efetch_tables = false, verbose=false)

# Save the results (dictionary) of an entrez fetch to a MySQL database.

# ###Arguments:

# * `efetch_dict`: Response dictionary from efetch
# * `con::MySQL.MySQLHandle`: Connection to MySQL database
# * `clean_efetch_tables`: If true, all tables related to efetch results are dropped
# * `verbose`: Boolean to turn on extra print statements


# ###Example

# ```julia
# db_config =  Dict(:host=>"localhost", :dbname=>"test", :username=>"root",
# :pswd=>"", :overwrite=>true)
# db = save_efetch_mysql(efetch_dict, db_config)
#  ```

# """
# function save_efetch_mysql(efetch_dict, con::MySQL.MySQLHandle, clean_efetch_tables = false, verbose=false)

#      if !haskey(efetch_dict, "PubmedArticle")
#          warn("Unsupported efetch save. Responses must be searches to: PubMed")
#      end

#      if clean_efetch_tables
#          init_pubmed_db_mysql!(con, !clean_efetch_tables)
#       end

#      pubmed_save_efetch!(efetch_dict, con, verbose)

#  end



"""
pubmed_save_efetch(efetch_dict, conn)

Save the results (dictionary) of an entrez-pubmed fetch to the input database.
"""
function save_efetch!(efetch_dict, conn, verbose=false)

    #Decide type of article based on structrure of efetch
    articles = nothing
    if haskey(efetch_dict, "PubmedArticle")
        TypeArticle = PubMedArticle
        articles = efetch_dict["PubmedArticle"]
    else
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
save_pmid_mysql(pmids, db_config, verbose)

Save a list of PMIDS into input database.
###Arguments:

* `pmids`: Array of PMIDs
* `db_config::Dict{Symbol, T}`: Configuration dictionary for initialitizing SQLite
database. Must contain symbols `:host`, `:dbname`, `:username`. `pswd`,
and `:overwrite`
* `verbose`: Boolean to turn on extra print statements
"""
function save_pmids!(pmids::Vector{Int64}, conn, verbose::Bool=false)
       
    for pmid in pmids
        insert_row!(conn,
                    tablename,
                    Dict(:pmid=> pmid),
                    verbose )
    end

end
