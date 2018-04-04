using ..DBUtils
using SQLite
using MySQL
using DataStreams, DataFrames
using NullableArrays

get_value{T}(val::Nullable{T}) = get(val)
get_value(val)= val
get_value{T}(val_array::Array{T}) = val_array
get_value{T}(val_array::NullableArray{T, 1}) = val_array.values


# """
#     init_pubmed_db(host::String, user::String, pwd::String, dbname::String)

# Create and initialize tables to save results from an Entrez/PubMed search.
# Caution, all related tables are dropped if they exist
# This function connection settings to a MySQL database 
# """
# function init_pubmed_db(host::String, user::String, pwd::String, dbname::String)
    
#     println("Initializing MySQL PubMed Database")
    
#     #Connect and populate
#     const conn = DBUtils.init_mysql_database(host, user, pwd, dbname)
#     init_pubmed_db!(conn)
    
#     return conn
# end

# """
#     init_pubmed_db(dp_path::String; overwrite::Bool = False )

# Create and initialize tables to save results from an Entrez/PubMed search.
# Caution, all related tables are dropped if they exist
# This function takes a path as input and therefore uses SQLite engine 
# """
# function init_pubmed_db(dp_path::String)
    
#     println("Initializing SQLite PubMed Database")
#     #Connect and populate
#     conn = SQLite.DB(dp_path)
#     init_pubmed_db!(conn)
#     return conn
# end

"""
    init_pubmed_db(db; sql_engine = MySQL)
Creates a database, using either MySQL of SQLite, with all necessary tables to store
Entrez related searches. All tables are empty at this point
"""
function create_tables!(conn)

    # Determine engine
    sql_engine = (typeof(conn)== MySQL.Connection) ? MySQL : SQLite 
    AUTOINCREMENT = (sql_engine == MySQL) ? "AUTO_INCREMENT" : "AUTOINCREMENT" 

    #purge related tables
    DBUtils.disable_foreing_checks(conn)
    sql_engine.execute!(conn, "DROP TABLE IF EXISTS article")
    sql_engine.execute!(conn, "DROP TABLE IF EXISTS author")
    sql_engine.execute!(conn, "DROP TABLE IF EXISTS author2article")
    sql_engine.execute!(conn, "DROP TABLE IF EXISTS mesh_descriptor")
    sql_engine.execute!(conn, "DROP TABLE IF EXISTS mesh_qualifier")
    sql_engine.execute!(conn, "DROP TABLE IF EXISTS mesh_heading")
    DBUtils.enable_foreing_checks(conn)
    

    #Create tables to store
    sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS article(
                            pmid INTEGER NOT NULL PRIMARY KEY,
                            title TEXT,
                            pubYear INTEGER,
                            abstract TEXT
                            );"
                        )

    sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS author(
                            id INTEGER PRIMARY KEY $AUTOINCREMENT,
                            forename VARCHAR(255),
                            lastname VARCHAR(255) NOT NULL,
                            CONSTRAINT unq UNIQUE(forename,  lastname)
                            );"
                        )
                        
    sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS author2article(
                            aid INTEGER,
                            pmid INTEGER,
                            FOREIGN KEY(aid) REFERENCES author(id),
                            FOREIGN KEY(pmid) REFERENCES article(pmid),
                            PRIMARY KEY(aid, pmid)
                            );"
                        )
                        
    # # --------------------------
    # #  MeshHeading Tables
    # # --------------------------
    # # --
    # # Descriptor
    # # The id corresponds to the DUI of mesh library
    # # Adding a "D" at the beginning of the id, allows for
    # # lookup in the mesh browerser
    # #  https://www.nlm.nih.gov/mesh/MBrowser.html
                        
    sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS mesh_descriptor(
                            id INTEGER NOT NULL PRIMARY KEY,
                            name VARCHAR(255) UNIQUE
                            );"
                        )
                        
    # Qualifier
    sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS mesh_qualifier(
                            id INTEGER NOT NULL PRIMARY KEY,
                            name VARCHAR(255) UNIQUE
                            );"
                        )
                        
    # Heading
    sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS mesh_heading(
                            id INTEGER PRIMARY KEY $AUTOINCREMENT,
                            pmid INTEGER, did INTEGER, qid INTEGER,
                            dmjr VARCHAR(1), qmjr VARCHAR(1),
                            FOREIGN KEY(pmid) REFERENCES article(pmid),
                            FOREIGN KEY(did) REFERENCES mesh_descriptor(id),
                            FOREIGN KEY(qid) REFERENCES mesh_qualifier(id),
                            CONSTRAINT unq UNIQUE(pmid, did, qid)
                            );"
                        )
    
end



# """
#     init_pubmed_db(host::String, user::String, pwd::String, dbname::String)

# Create and initialize tables to save results from an Entrez/PubMed search.
# Caution, all related tables are dropped if they exist
# This function connection settings to a MySQL database 
# """
# function init_pmid_db(host::String, user::String, pwd::String, dbname::String)
    
#     println("Initializing MySQL pmid Database")
    
#     #Connect and populate
#     const conn = DBUtils.init_mysql_database(host, user, pwd, dbname)
#     init_pmid_db!(conn)
    
#     return conn
# end

# """
#     init_pmid_db(dp_path::String; overwrite::Bool = False )

# Create and initialize tables to save results from an Entrez/pmid search.
# Caution, all related tables are dropped if they exist
# This function takes a path as input and therefore uses SQLite engine 
# """
# function init_pmid_db(dp_path::String)
    
#     println("Initializing SQLite pmid Database")
#     #Connect and populate
#     conn = SQLite.DB(dp_path)
#     init_pmid_db!(conn)
#     return conn
# end

"""
    init_pmid_db!(conn; tablename="article")
Creates a database, using either MySQL of SQLite, with all necessary tables to store
Entrez related searches. All tables are empty at this point
"""
function create_pmid_table!(conn; tablename="article")

    # Determine engine
    sql_engine = (typeof(conn)== MySQL.Connection) ? MySQL : SQLite 

    #purge related tables
    # sql_engine.execute!(conn, "DROP TABLE IF EXISTS $tablename")
    
    #Create tables to store
    sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS $tablename(
                                pmid INTEGER NOT NULL PRIMARY KEY
                                );"
                        )
end


"""
    all_pmids(db)
Return all PMIDs stored in the *article* table of the input database
"""
function all_pmids(conn)
    sql_engine = (typeof(conn)== MySQL.Connection) ? MySQL : SQLite 
    query = sql_engine.query(conn, "SELECT pmid FROM article;")
    return query[1]
end

"""
    all_mesh(db)
Return all PMIDs stored in the *article* table of the input database
"""
function all_mesh(db)
    sel = db_query(db, "SELECT name FROM mesh_descriptor;")
    return get_value(sel[1])
end

"""
abstracts_by_year(db, pub_year; local_medline=false)

Return all abstracts of article published in the given year.
If local_medline flag is set to true, it is assumed that db contains *article*
table with only PMIDs and all other info is available in a (same host) medline database
"""
function abstracts_by_year(db, pub_year; local_medline=false, uid_str = "pmid")

    #get all abstracts UNIQUE pairs
    query_code = ""
    if local_medline
    query_code = "SELECT article.$uid_str as $uid_str,
                         medline.basic.abstract as abstract_text
                    FROM article
              INNER JOIN medline.basic ON medline.basic.pmid = article.pmid
                   WHERE medline.basic.pubYear = '$pub_year' "
    else
        query_code = "SELECT ar.$uid_str as $uid_str,
                             ar.abstract as abstract_text
                        FROM article as ar
                       WHERE ar.pubYear = '$pub_year' "
    end

    sel = db_query(db, query_code)
    num_abstracts = size(sel)[1]
    println("Retrieved: ", num_abstracts, " abstracts")
    return sel
end

"""
abstracts(db; local_medline=false)

Return all abstracts related to PMIDs in the database.
If local_medline flag is set to true, it is assumed that db contains *article*
table with only PMIDs and all other info is available in a (same host) medline database
"""
function abstracts(db; local_medline=false)

    #get all abstracts UNIQUE pairs
    query_code = ""
    if local_medline
        query_code = "SELECT article.pmid as pmid,
                             medline.basic.abstract as abstract_text
                        FROM article
                  INNER JOIN medline.basic ON medline.basic.pmid = article.pmid"
    else
        query_code = "SELECT ar.pmid as pmid,
                             ar.abstract as abstract_text
                        FROM article as ar "
    end

    sel = db_query(db, query_code)
    num_abstracts = size(sel)[1]
    println("Retrieved: ", num_abstracts, " abstracts")
    return sel
end

"""
    get_article_mesh(db, pmid)
Get the all mesh-descriptors associated with a give article
"""
function get_article_mesh(db, pmid::Integer)

    query_string = "SELECT md.name
                      FROM mesh_heading as mh,
                           mesh_descriptor as md
                     WHERE mh.did = md.id
                      AND mh.pmid = $pmid"
    query  = db_query(db, query_string)
    #return data array
    return get_value(query.columns[1])

end

"""
    get_article_mesh_by_concept(db, pmid, umls_concepts...; local_medline)
Get the all mesh-descriptors associated with a give article
## Argumets:
* query_string: "" - assumes full set of results were saved by BioMedQuery directly from XML
"""
function get_article_mesh_by_concept(db, pmid::Integer, umls_concepts...; query_string="")

    concept_set_str = """( "$(umls_concepts[1])" """

    for i=2:length(umls_concepts)
        concept_set_str = """$(concept_set_str), "$(umls_concepts[i])" """
    end
    
    concept_set_str = "$(concept_set_str))"   

    if query_string == ""
        query_string = "SELECT DISTINCT(md.name), m2u.umls
                        FROM mesh_descriptor AS md
                        JOIN mesh_heading AS mh ON mh.did = md.id
                        JOIN mesh2umls AS m2u ON m2u.mesh = md.name
                        WHERE mh.pmid = $pmid
                        AND m2u.umls IN  $(concept_set_str)"
    end

    query  = db_query(db, query_string)
    #return data array
    return get_value(query.columns[1])

end

function db_insert!(db, article::PubMedArticle, verbose=false)
    #------- PMID - TITLE - YEAR
    isnull(article.pmid) && error("NULL PMID")

    # Save article data
    insert_row!(db, "article",
                Dict(:pmid =>article.pmid.value,
                     :title=>get(article.title, ""),
                     :pubYear=>get(article.year, 0),
                     :abstract=>get(article.abstract_text, "")),
                verbose)

    #------- AUTHORS
    for au in article.authors
        if isnull(au[:LastName])
           println("Skipping author, null field: ", au)
           continue
        end

        author_id = insert_row!(db, "author",
        Dict(:id => nothing,
             :forename => get(au[:ForeName], "Unknown"),
             :lastname => get(au[:LastName], nothing)), verbose)

        if author_id < 0
            sel = db_select(db, ["id"], "author",
            Dict(:forename => get(au[:ForeName], "Unknown"),
                 :lastname => au[:LastName].value))
            if length(sel[1]) > 0
                author_id = get_value(sel[1][1])
                if verbose
                    println("Author already in db: ", au)
                end
                insert_row!(db, "author2article",
                Dict(:aid =>author_id, :pmid => article.pmid.value), verbose)
            else
                error("Can't save nor find Author: ", au)
            end
        else
          insert_row!(db, "author2article",
          Dict(:aid =>author_id, :pmid => article.pmid.value), verbose)
        end
    end
end

function db_insert!(db, pmid::Int64, mesh_heading_list::MeshHeadingList, verbose=false)
    
    for heading in mesh_heading_list
        did_int = heading.descriptor_id.value
        descriptor_name = heading.descriptor_name.value
        dmjr = get(heading.descriptor_mjr, nothing)


        #Save Descriptor
        insert_row!(db, "mesh_descriptor",
        Dict(:id=>did_int,
             :name=>descriptor_name),
             verbose)

        if isempty(heading.qualifier_id)
            #Save Headings
            insert_row!(db, "mesh_heading",
            Dict(:id=>nothing,
                 :pmid=> pmid,
                 :did=>did_int,
                 :qid=>nothing,
                 :dmjr=>nothing, :qmjr=>nothing), verbose )
        else

            for i=1:length(heading.qualifier_id)
                qid_int = get(heading.qualifier_id[i], -1)
                qualifier_name = get(heading.qualifier_name[i], nothing)
                qmjr = get(heading.qualifier_mjr[i], nothing)

                #Save Qualifiers`
                insert_row!(db, "mesh_qualifier",
                Dict(:id=>qid_int,
                     :name=>qualifier_name),
                     verbose )

                #Save Headings
                insert_row!(db, "mesh_heading",
                Dict(:id=>nothing,
                     :pmid=> pmid,
                     :did=>did_int,
                     :qid=>qid_int,
                     :dmjr=>dmjr, :qmjr=>qmjr), verbose )
            end
        end

    end
end
