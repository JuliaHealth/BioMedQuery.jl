include("entrez_db.jl")
using .DB
using ..DBUtils
using SQLite
using MySQL


"""
save_efetch_sqlite(efetch_dict, db_config, verbose)

Save the results (dictionary) of an entrez fetch to a SQLite database.

###Arguments:

* `efetch_dict`: Response dictionary from efetch
* `db_config::Dict{Symbol, T}`: Configuration dictionary for initialitizing SQLite
database. Must contain symbols `:db_path` and `:overwrite`
* `verbose`: Boolean to turn on extra print statements

###Example

```julia
db_config =  Dict(:db_path=>"test_db.slqite", :overwrite=>true)
db = save_efetch_sqlite(efetch_dict, db_config)
```

"""
function save_efetch_sqlite{T}(efetch_dict, db_config::Dict{Symbol, T}, verbose=false)
    if haskey(efetch_dict, "PubmedArticle")
        db = init_pubmed_db_sqlite(db_config)
        return pubmed_save_efetch!(efetch_dict, db, verbose)
    else
        error("Unsupported efetch save. Responses must be searches to: PubMed")
        return nothing
    end
end


"""
save_efetch_mysql(efetch_dict, db_config, verbose)

Save the results (dictionary) of an entrez fetch to a MySQL database.

###Arguments:

* `efetch_dict`: Response dictionary from efetch
* `db_config::Dict{Symbol, T}`: Configuration dictionary for initialitizing SQLite
database. Must contain symbols `:host`, `:dbname`, `:username`. `pswd`,
and `:overwrite`
* `verbose`: Boolean to turn on extra print statements


###Example

```julia
db_config =  Dict(:host=>"localhost", :dbname=>"test", :username=>"root",
:pswd=>"", :overwrite=>true)
db = save_efetch_mysql(efetch_dict, db_config)
```

"""
function save_efetch_mysql{T}(efetch_dict, db_config::Dict{Symbol, T}, verbose=false)

    if !haskey(efetch_dict, "PubmedArticle")
        warn("Unsupported efetch save. Responses must be searches to: PubMed")
    end

    db = init_pubmed_db_mysql(db_config)
    pubmed_save_efetch!(efetch_dict, db, verbose)

    return db
end

"""
save_efetch_mysqlefetch_dict, con::MySQL.MySQLHandle, clean_efetch_tables = false, verbose=false)

Save the results (dictionary) of an entrez fetch to a MySQL database.

###Arguments:

* `efetch_dict`: Response dictionary from efetch
* `con::MySQL.MySQLHandle`: Connection to MySQL database
* `clean_efetch_tables`: If true, all tables related to efetch results are dropped
* `verbose`: Boolean to turn on extra print statements


###Example

```julia
db_config =  Dict(:host=>"localhost", :dbname=>"test", :username=>"root",
:pswd=>"", :overwrite=>true)
db = save_efetch_mysql(efetch_dict, db_config)
```

"""
function save_efetch_mysql(efetch_dict, con::MySQL.MySQLHandle, clean_efetch_tables = false, verbose=false)

    if !haskey(efetch_dict, "PubmedArticle")
        warn("Unsupported efetch save. Responses must be searches to: PubMed")
    end

    if clean_efetch_tables
        init_pubmed_db_mysql!(con, !clean_efetch_tables)
    end

    pubmed_save_efetch!(efetch_dict, con, verbose)

end


"""
pubmed_save_efetch(efetch_dict, db_path)

Save the results (dictionary) of an entrez-pubmed fetch to the input database.
"""
function pubmed_save_efetch!(efetch_dict, db, verbose=false)

    #Decide type of article based on structrure of efetch
    all_pmids = Array{Int64}(0)
    if haskey(efetch_dict, "PubmedArticle")
        articles = efetch_dict["PubmedArticle"]
        println("Saving " , length(articles) ,  " articles to database")
        all_pmids = Array{Int64}(length(articles))
        for (idx, xml_article) in enumerate(articles)

            article = PubMedArticle(xml_article)

            # println("=============Article=====================")
            # println(article)
            db_insert!(db, article, verbose)

            #-------MeshHeadingList
            mesh_heading_list = MeshHeadingList(xml_article)
            db_insert!(db, article.pmid.value, mesh_heading_list, verbose)
            all_pmids[idx] = article.pmid.value
        end
    end

    all_pmids
end
