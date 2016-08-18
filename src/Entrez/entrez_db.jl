module DB

using ...DBUtils
using SQLite
using DataStreams, DataFrames

export init_database_mysql, init_database_sqlite

function init_database_mysql(config)

    println("------Initializing MySQL Database---------")

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
    println("------Initializing SQLite Database---------")
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

    println("Initializing Database")

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

end #module

# function init_database(config)
#
#     if Entrez._db_backend[1] == :MySQL
#
#         println("------Initializing MySQL Database---------")
#
#         #intput dictionary must have the following keys
#         if haskey(config, :host) && haskey(config, :dbname) &&
#            haskey(config, :username) && haskey(config, :pswd) &&
#            haskey(config, :overwrite)
#
#            mysql_code=nothing
#            try
#                filename = Pkg.dir() * "/BioMedQuery/src/Entrez/create_entrez_db.sql"
#                println(filename)
#                f = open(filename, "r")
#                mysql_code = readall(f)
#                close(f)
#            catch
#                error("Could not read create_entrez_db.sql")
#            end
#
#            db = init_mysql_database(host = config[:host], dbname =config[:dbname],
#            username = config[:username], pswd= config[:pswd],
#            overwrite = config[:overwrite], mysql_code = mysql_code)
#
#            return db
#
#        else
#             println("Error with following configuration:")
#             println(config)
#             println("Must contain: host, dbname, username, pswd")
#             error("Improper configuration for entrez_mysql:init_database")
#         end
#
#     elseif Entrez._db_backend[1] == :SQLite
#
#         println("------Initializing SQLite Database---------")
#         if haskey(config, :db_path) && haskey(config, :overwrite)
#             db = init_sqlite_database(config[:db_path], config[:overwrite])
#         else
#             println("Error with following configuration:")
#             println(config)
#             println("Must contain: db_path")
#             error("Improper configuration for entrez_sqlite:init_database")
#         end
#
#
#     else
#         error("init_database - Unsupported Database Backend: ", Entrez._db_backend[1])
#     end
#
# end
#
# function insert_row(db, tablename, values)
#     if Entrez._db_backend[1] == :MySQL
#         last_id = insert_row_mysql!(db, tablename, values, true)
#     elseif Entrez._db_backend[1] == :SQLite
#         last_id = insert_row_sqlite!(db, tablename, values)
#     end
#
# end


# """
#     select(db, ["colname"], "tblname", Dict{:title=>"Article title"})
#
# SELECT columns indicated in colnames, from "table", matching the criteria given
# in the input dictionary
#
# ### Output
# * `selection::DataFrames.DataFrame` : DataFrame containing the results
#
# ### Example
# ```jldoctest
#
# using BioMedQuery.Entrez
# Entrez.DB.db_backend("MySQL")
# config = Dict(:host=>"localhost", :dbname=>"test", :username=>"root",
# :pswd=>"", :overwrite=>true)
# con = Entrez.DB.init_database(config)
# Entrez.DB.insert_row(con, "article", Dict(:pmid => 1234,
# :title=>"Test Article",
# :pubYear=>nothing))
# sel = BEntrez.DB.select(con, ["pmid"], "article", Dict(:title=>"Test Article"))
# pmid = sel[1][1]
# pmid
#
# #output
#
# 1234
# ```
#
# """
# function select{T}(db, colnames, table, data_values::Dict{Symbol, T})
#     if Entrez._db_backend[1] == :MySQL
#         selection = select(db, tablename, values, true)
#     elseif Entrez._db_backend[1] == :SQLite
#         selection = select(db, tablename, values, true)
#     end
# end
