#Database utilities for entrez query_unique_mesh
module DB
import SQLite
using DataStreams


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
    lastname TEXT,
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
    if tablename == "article"
        try
            SQLite.query(db, "INSERT INTO article VALUES  (@pmid, @title, @pubYear)", values)
            id_query = SQLite.query(db, "SELECT rowid, * FROM article WHERE pmid=? ", [values[:pmid]])
            id = get(id_query.data[1][1], -1)
            return id
        catch exception
            println("Row not inserted into table: article ")
            println("Msg: ", exception.msg)
            return -1
        end
    elseif tablename == "author"
        try
            SQLite.query(db, "INSERT INTO author VALUES  (@id, @forename, @lastname)", values)
            id_query = SQLite.query(db, "SELECT rowid, * FROM author WHERE forename=?1 AND lastname=?2 ", [values[:forename], values[:lastname]])
            id = get(id_query.data[1][1], -1)
            return id
        catch exception
            println("Row not inserted into table: author, value: ", values)
            # println("Msg: ", exception.msg)
            return -1
        end
    elseif tablename == "author2article"
        try
            SQLite.query(db, "INSERT INTO author2article VALUES  (@aid, @pmid)", values)
            id_query = SQLite.query(db, "SELECT rowid, * FROM author2article WHERE aid=?1 AND pmid=?2 ", [values[:aid], values[:pmid]])
            id = get(id_query.data[1][1], -1)
            return id
        catch exception
            println("Row not inserted into table: author2article")
            println("Msg: ", exception.msg)
            print(values)
            return -1
        end
    elseif tablename == "mesh_descriptor"
        try
            SQLite.query(db, "INSERT INTO mesh_descriptor VALUES  (@id, @name)", values)
            id_query = SQLite.query(db, "SELECT rowid, * FROM mesh_descriptor WHERE name=? ", [values[:name]])
            id = values[:id]
            return id
        catch exception
            println("Row not inserted into table: mesh_descriptor, value: ", values)
            println("Msg: ", exception.msg)
            return -1
        end
    elseif tablename == "mesh_qualifier"
        try
            SQLite.query(db, "INSERT INTO mesh_qualifier VALUES  (@id, @name)", values)
            id = values[:id]
            return id
        catch exception
            println("Row not inserted into table: mesh_qualifier, value: ", values)
            println("Msg: ", exception.msg)
            return -1
        end
    elseif tablename == "mesh_heading"
        try
            SQLite.query(db, "INSERT INTO mesh_heading VALUES  (@id, @pmid, @did, @qid, @dmjr, @qmjr)", values)
        catch exception
            println("Row not inserted into table: mesh_heading, value: ", values)
            println("Msg: ", exception.msg)
            return -1
        end
    end
    #TO DO: Is it safe to do this for all tables - do we have no rowid cases?
    lastid_query = SQLite.query(db, "SELECT last_insert_rowid()")
    #safely get the rowid -when null return -1
    id = get(lastid_query.data[1][1], -1)
    return id

end


#Get all PMIDS in article table of input database
function all_pmids(db)
    query = SQLite.Source(db,"SELECT pmid FROM article;")
    data_table = Data.stream!(query,Data.Table)
    return data_table.data[1]
end

#Get all mesh descriptors associated with give article
function get_article_mesh(db, pmid::Nullable{Int64})

    if pmid.isnull
        return NullableArray{ASCIIString}()
    else
        query  = SQLite.query(db, "SELECT mesh FROM mesh2article
        WHERE pmid = ?", [pmid.value])

        #return data array
        return query.data[1]
    end
end


end
