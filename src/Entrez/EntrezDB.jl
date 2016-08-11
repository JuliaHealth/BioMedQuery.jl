#Database utilities for entrez query_unique_mesh
module DB
import SQLite
using DataStreams, DataFrames


"Wrapper around SQLite.Null"
const NULL = SQLite.NullType()

# Creates a database with all necessary tables to store
# Entrez related searches. All tables are empty at this point
# If a database existis at the given path - an error is ruturned an the user
# is asked whether he intended to clean the existing file
function init_database(path)

    println("Initializing Database")

    if isfile(path)
        println("Database found. Returning existing database.")
        return SQLite.DB(path)
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
    CONSTRAINT unq UNIQUE(forename,  lastname) ON CONFLICT IGNORE)")

    SQLite.query(db, "CREATE TABLE
    author2article(aid INTEGER, pmid INTEGER,
    FOREIGN KEY(aid) REFERENCES author(id),
    FOREIGN KEY(pmid) REFERENCES article(pmid),
    PRIMARY KEY(aid, pmid) ON CONFLICT IGNORE)")

    #--------------------------
    # MeshHeading Tables
    #--------------------------

    #Descriptor
    #The id corresponds to the DUI of mesh library
    #Adding a "D" at the beginning of the id, allows for
    #lookup in the mesh browerser
    # https://www.nlm.nih.gov/mesh/MBrowser.html
    SQLite.query(db, "CREATE TABLE
    mesh_descriptor(id INTEGER NOT NULL PRIMARY KEY ON CONFLICT IGNORE,
                    name TEXT UNIQUE ON CONFLICT IGNORE )")

    #Qualifier
    SQLite.query(db, "CREATE TABLE
    mesh_qualifier(id INTEGER NOT NULL PRIMARY KEY ON CONFLICT IGNORE,
                   name TEXT UNIQUE ON CONFLICT IGNORE )")

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

#Insert row into the sapecified table. User is responsible for providing all values
#This could possibly be done more general if # of tables becomes large
# Isa: Not sure about difference of symbols : @ $
function insert_row(db, tablename, values)
    id = -1
    if tablename == "article"
        try
            SQLite.query(db, "INSERT INTO article VALUES  (@pmid, @title, @pubYear)", values)
        catch exception
            println("Row not inserted into table: article ")
            println("Msg: ", exception.msg)
            return id
        end
        id_query = SQLite.query(db, "SELECT rowid, * FROM article WHERE pmid=? ", [values[:pmid]])
        id = get(id_query.columns[1][1], -1)
        return id
    elseif tablename == "author"
        try
            SQLite.query(db, "INSERT INTO author VALUES  (@id, @forename, @lastname)", values)
            #catch 22 - if forname is NULL, UNIQUE constraint of forename-lastname can't be violated
            #therefore the last insert row id maybe our best chance
            if values[:forename] == NULL
                lastid_query = SQLite.query(db, "SELECT last_insert_rowid()")
                id = get(lastid_query.columns[1][1], -1)
                println("Null forename, lastname: ", values[:lastname], " id: ", id )
                return id
            end
        catch exception
            println("Row not inserted into table: author, value: ", values)
            println("Msg: ", exception.msg)
            return id
        end
        id_query = SQLite.query(db, "SELECT rowid, * FROM author WHERE forename=?1 AND lastname=?2 ", [values[:forename], values[:lastname]])
        try
            id = get(id_query.columns[1][1], -1)
        catch
            error("Could not get id, table: author, query: ", id_query , "values: ", values )
        end
        return id
    elseif tablename == "author2article"
        try
            SQLite.query(db, "INSERT INTO author2article VALUES  (@aid, @pmid)", values)
        catch exception
            println("Row not inserted into table: author2article, values: ", values)
            println("Msg: ", exception.msg)
            return id
        end
        id_query = SQLite.query(db, "SELECT rowid, * FROM author2article WHERE aid=?1 AND pmid=?2 ", [values[:aid], values[:pmid]])
        id = get(id_query.columns[1][1], -1)
        return id
    elseif tablename == "mesh_descriptor"
        try
            SQLite.query(db, "INSERT INTO mesh_descriptor VALUES  (@id, @name)", values)
        catch exception
            println("Row not inserted into table: mesh_descriptor, value: ", values)
            println("Msg: ", exception.msg)
            return id
        end
        id_query = SQLite.query(db, "SELECT rowid, * FROM mesh_descriptor WHERE name=? ", [values[:name]])
        id = values[:id]
        return id
    elseif tablename == "mesh_qualifier"
        try
            SQLite.query(db, "INSERT INTO mesh_qualifier VALUES  (@id, @name)", values)
            id = values[:id]
            return id
        catch exception
            println("Row not inserted into table: mesh_qualifier, value: ", values)
            println("Msg: ", exception.msg)
            return id
        end
    elseif tablename == "mesh_heading"
        try
            SQLite.query(db, "INSERT INTO mesh_heading VALUES  (@id, @pmid, @did, @qid, @dmjr, @qmjr)", values)
        catch exception
            println("Row not inserted into table: mesh_heading, value: ", values)
            println("Msg: ", exception.msg)
            return id
        end
        if values[:qid] == NULL
            id_query = SQLite.query(db, "SELECT rowid, * FROM mesh_heading WHERE pmid=?1 AND did=?2 ", [values[:pmid], values[:did]])
            id = get(id_query.columns[1][1], -1)
        else
            id_query = SQLite.query(db, "SELECT rowid, * FROM mesh_heading WHERE pmid=?1 AND did=?2 AND qid=?3 ", [values[:pmid], values[:did], values[:qid]])
            id = get(id_query.columns[1][1], -1)
        end
        return id
    end
    error("Error: Unknown Database Table or condition")
    return id

end


#Get all PMIDS in article table of input database
function all_pmids(db)
    query = SQLite.Source(db,"SELECT pmid FROM article;")
    data_table = Data.stream!(query,DataFrame)
    return data_table.columns[1]
end

#Get the all mesh-descriptors associated with give article
function get_article_mesh(db, pmid::Nullable{Int64})

    if pmid.isnull
        return NullableArray{ASCIIString}()
    else
        query  = SQLite.query(db, "SELECT md.name
                                     FROM mesh_heading as mh,
                                          mesh_descriptor as md
                                    WHERE mh.did = md.id
                                      AND mh.pmid = ?", [pmid.value])
        #return data array
        return query.columns[1]
    end
end


end
