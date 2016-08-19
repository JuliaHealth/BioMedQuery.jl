module DB

using ...DBUtils
using SQLite
using DataStreams, DataFrames
using NullableArrays

export init_database_mysql,
       init_database_sqlite,
       get_value_mysql,
       get_value_sqlite

get_value_mysql(val) = val
get_value_sqlite(val) = get(val)
get_value_mysql{T}(val_array::Array{T}) = val_array
get_value_sqlite{T}(val_array::NullableArray{T, 1}) = val_array.values

function init_database_mysql(config)

    println("Initializing MySQL Database")

    #intput dictionary must have the following keys
    if haskey(config, :host) && haskey(config, :dbname) &&
       haskey(config, :username) && haskey(config, :pswd) &&
       haskey(config, :overwrite)

       mysql_code=nothing
       try
           filename = Pkg.dir() * "/BioMedQuery/src/Entrez/create_entrez_db.sql"
           println(filename)
           f = open(filename, "r")
           mysql_code = readall(f)
           close(f)
       catch
           error("Could not read create_entrez_db.sql")
       end

       db = DBUtils.init_mysql_database(host = config[:host], dbname =config[:dbname],
       username = config[:username], pswd= config[:pswd],
       overwrite = config[:overwrite], mysql_code = mysql_code)

       return db
   end
end

function init_database_sqlite(config)
    println("Initializing SQLite Database")
    if haskey(config, :db_path) && haskey(config, :overwrite)
        db = init_database_sqlite(config[:db_path], config[:overwrite])
    else
        println("Error with following configuration:")
        println(config)
        println("Must contain: db_path")
        error("Improper configuration for entrez_sqlite:init_database")
    end
end

# Creates a database with all necessary tables to store
# Entrez related searches. All tables are empty at this point
# If a database existis at the given path - an error is ruturned an the user
# is asked whether he intended to clean the existing file
function init_database_sqlite(path::ASCIIString, overwrite=false)


    if isfile(path)
        if overwrite
            rm(path)
        else
            println("Database found. Returning existing database.")
            return SQLite.DB(path)
        end
    end

    #Create database file
    db = SQLite.DB(path)

    #Create tables to store
    SQLite.query(db, "CREATE TABLE
    article(pmid INTEGER NOT NULL PRIMARY KEY,
    title TEXT,
    pubYear INTEGER)")


    SQLite.query(db, "CREATE TABLE
    author(id INTEGER PRIMARY KEY AUTOINCREMENT,
    forename TEXT,
    lastname TEXT NOT NULL,
    CONSTRAINT unq UNIQUE(forename,  lastname) )")

    SQLite.query(db, "CREATE TABLE
    author2article(aid INTEGER, pmid INTEGER,
    FOREIGN KEY(aid) REFERENCES author(id),
    FOREIGN KEY(pmid) REFERENCES article(pmid),
    PRIMARY KEY(aid, pmid) )")

    #--------------------------
    # MeshHeading Tables
    #--------------------------

    #Descriptor
    #The id corresponds to the DUI of mesh library
    #Adding a "D" at the beginning of the id, allows for
    #lookup in the mesh browerser
    # https://www.nlm.nih.gov/mesh/MBrowser.html
    SQLite.query(db, "CREATE TABLE
    mesh_descriptor(id INTEGER NOT NULL PRIMARY KEY ,
                    name TEXT UNIQUE )")

    #Qualifier
    SQLite.query(db, "CREATE TABLE
    mesh_qualifier(id INTEGER NOT NULL PRIMARY KEY ,
                   name TEXT UNIQUE )")

    #Heading
    SQLite.query(db, "CREATE TABLE
    mesh_heading(id INTEGER PRIMARY KEY AUTOINCREMENT,
                 pmid INTEGER, did INTEGER, qid INTEGER,
                 dmjr INTEGER, qmjr INTEGER,
                 FOREIGN KEY(pmid) REFERENCES article(pmid),
                 FOREIGN KEY(did) REFERENCES mesh_descriptor(id),
                 FOREIGN KEY(qid) REFERENCES mesh_qualifier(id),
                 CONSTRAINT unq UNIQUE(pmid, did, qid) )")

    return db

end

for f in [:mysql, :sqlite]
    all_pmis_func = Symbol(string("all_pmids_", f))
    get_article_mesh_func = Symbol(string("get_article_mesh_", f))
    get_value_func = Symbol(string("get_value_", f))
    query_func = Symbol(string("query_", f))
    #Get all PMIDS in article table of input database
    @eval begin
        function ($all_pmis_func)(db)
            query = ($query_func)(db, "SELECT pmid FROM article;")
            return ($get_value_func)(query[1])
        end

        #Get the all mesh-descriptors associated with give article
        function ($get_article_mesh_func)(db, pmid::Integer)

            query_string = "SELECT md.name
                              FROM mesh_heading as mh,
                                   mesh_descriptor as md
                             WHERE mh.did = md.id
                              AND mh.pmid = $pmid"
            query  = ($query_func)(db, query_string)
            #return data array
            return ($get_value_func)(query.columns[1])

        end
    end
end

end #module
