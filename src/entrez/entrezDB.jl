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

    if isfile(path)
        println("Database found. Returning existing database.")
        return SQLite.DB(path)
    end

    #Create database file
    db = SQLite.DB(path)

    #Create tables to store
    SQLite.query(db, "CREATE TABLE
    article (pmid INTEGER NOT NULL PRIMARY KEY,
    title TEXT,
    pubYear TEXT )")


    SQLite.query(db, "CREATE TABLE
    author (id INTEGER PRIMARY KEY AUTOINCREMENT,
    forename TEXT,
    lastname TEXT,
    CONSTRAINT unq UNIQUE(forename,  lastname) )")

    SQLite.query(db, "CREATE TABLE
    author2article ( aid INTEGER, pmid INTEGER,
    FOREIGN KEY(aid) REFERENCES author(id),
    FOREIGN KEY(pmid) REFERENCES article(pmid),
    PRIMARY KEY(aid, pmid) )")

    SQLite.query(db, "CREATE TABLE
    mesh (name TEXT PRIMARY KEY )")

    SQLite.query(db, "CREATE TABLE
    mesh2article (mesh TEXT, pmid INTEGER,
    FOREIGN KEY(mesh) REFERENCES mesh(name),
    FOREIGN KEY(pmid) REFERENCES article(pmid),
    PRIMARY KEY(mesh, pmid) )")

    return db

end

#Insert row into the sapecified table. User is responsible for providing all values
#This could possibly be done more general if # of tables becomes large
# Isa: Not sure about difference of symbols : @ $
function insert_row(db, tablename, values)
    if tablename == "article"
        try
            SQLite.query(db, "INSERT INTO article VALUES  (@pmid, @title, @pubYear)", values)
        catch
            println("Row not inserted into table: article ")
            return -1
        end
    elseif tablename == "author"
        try
            SQLite.query(db, "INSERT INTO author VALUES  (@id, @forename, @lastname)", values)
        catch
            # println("Row not inserted into table: author")
            return -1
        end
    elseif tablename == "author2article"
        try
            SQLite.query(db, "INSERT INTO author2article VALUES  (@aid, @pmid)", values)
        catch
            # println("Row not inserted into table: author2article")
            return -1
        end
    elseif tablename == "mesh"
        try
            SQLite.query(db, "INSERT INTO mesh VALUES  (@name)", values)
        catch
            # println("Row not inserted into table: mesh")
            # println(values)
            return -1
        end
    elseif tablename == "mesh2article"
        try
            SQLite.query(db, "INSERT INTO mesh2article VALUES  (@mesh, @pmid)", values)
        catch
            println("Row not inserted into table: mesh2article")
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
