using MySQL

function db_init()
   
    const conn = MySQL.connect("127.0.0.1", "root", "", db="deleteme")

    # MySQL.execute!(conn, "DROP DATABASE deleteme" )
    # MySQL.execute!(conn, "CREATE DATABASE deleteme
    # CHARACTER SET utf8 COLLATE utf8_unicode_ci;")

    # MySQL.execute!(conn, "use deleteme;")

    MySQL.execute!(conn, "CREATE TABLE IF NOT EXISTS temp(
        dummy INTEGER NOT NULL PRIMARY KEY,
        title TEXT
        );")        
    return conn
end


function multi_statement(conn)
    MySQL.execute!(conn, "show tables")
end

const conn = db_init()


multi_statement(conn);
multi_statement(conn);

MySQL.disconnect(conn);


# test "show tables"
using MySQL
pwd = ""
const conn = MySQL.connect("127.0.0.1", "root", pwd; port=3306)
MySQL.execute!(conn, "DROP DATABASE if exists mysqltest")


MySQL.execute!(conn, "CREATE DATABASE mysqltest; use mysqltest;")

MySQL.execute!(conn, "use mysqltest")

MySQL.execute!(conn, """CREATE TABLE Employee
                    (
                        ID INT NOT NULL AUTO_INCREMENT,
                        Name VARCHAR(255),
                        Salary FLOAT(7,2),
                        JoinDate DATE,
                        LastLogin DATETIME,
                        LunchTime TIME,
                        OfficeNo TINYINT,
                        JobType ENUM('HR', 'Management', 'Accounts'),
                        Senior BIT(1),
                        empno SMALLINT,
                        PRIMARY KEY (ID)
                    );""")

MySQL.execute!(conn, """source "test.sql" """)
#using execute! leads to Inexact Error
q = MySQL.query(conn, "show tables")

query_str = "
SET FOREIGN_KEY_CHECKS=0;
DROP TABLE IF EXISTS article;
DROP TABLE IF EXISTS author;
DROP TABLE IF EXISTS author2article;
DROP TABLE IF EXISTS mesh_descriptor;
DROP TABLE IF EXISTS mesh_qualifier;
DROP TABLE IF EXISTS mesh_heading;
SET FOREIGN_KEY_CHECKS=1;"

query_str = "SET FOREIGN_KEY_CHECKS=0;"
query_str = "DROP TABLE IF EXISTS article;"
query_str = "SET FOREIGN_KEY_CHECKS=1;"
query_str = ""
query_str = ""



q = MySQL.query(conn, query_str)


# test common slite/mysql interface


# Creates a database with all necessary tables to store
# Entrez related searches. All tables are empty at this point
# If a database existis at the given path - an error is ruturned an the user
# is asked whether he intended to clean the existing file
function init_pubmed_db(db; sql_engine = MySQL, overwrite=false)
    
         #Create tables to store
         sql_engine.execute!(db, "CREATE TABLE
         article(pmid INTEGER NOT NULL PRIMARY KEY,
         title TEXT,
         pubYear INTEGER,
         abstract TEXT)")
     
     
         # sql_engine.query(db, "CREATE TABLE
         # author(id INTEGER PRIMARY KEY AUTOINCREMENT,
         # forename TEXT,
         # lastname TEXT NOT NULL,
         # CONSTRAINT unq UNIQUE(forename,  lastname) )")
     
         # sql_engine.query(db, "CREATE TABLE
         # author2article(aid INTEGER, pmid INTEGER,
         # FOREIGN KEY(aid) REFERENCES author(id),
         # FOREIGN KEY(pmid) REFERENCES article(pmid),
         # PRIMARY KEY(aid, pmid) )")
     
         # #--------------------------
         # # MeshHeading Tables
         # #--------------------------
     
         # #Descriptor
         # #The id corresponds to the DUI of mesh library
         # #Adding a "D" at the beginning of the id, allows for
         # #lookup in the mesh browerser
         # # https://www.nlm.nih.gov/mesh/MBrowser.html
         # sql_engine.query(db, "CREATE TABLE
         # mesh_descriptor(id INTEGER NOT NULL PRIMARY KEY ,
         #                 name TEXT UNIQUE )")
     
         # #Qualifier
         # sql_engine.query(db, "CREATE TABLE
         # mesh_qualifier(id INTEGER NOT NULL PRIMARY KEY ,
         #                name TEXT UNIQUE )")
     
         # #Heading
         # sql_engine.query(db, "CREATE TABLE
         # mesh_heading(id INTEGER PRIMARY KEY AUTOINCREMENT,
         #              pmid INTEGER, did INTEGER, qid INTEGER,
         #              dmjr TEXT, qmjr TEXT,
         #              FOREIGN KEY(pmid) REFERENCES article(pmid),
         #              FOREIGN KEY(did) REFERENCES mesh_descriptor(id),
         #              FOREIGN KEY(qid) REFERENCES mesh_qualifier(id),
         #              CONSTRAINT unq UNIQUE(pmid, did, qid) )")
     
         return db
     
     end


using BioMedQuery
using MySQL
     
dbname="pubmed_test"

conn = BioMedQuery.PubMed.init_pubmed_db("127.0.0.1", "root", "", dbname)
     
AUTOINCREMENT = "AUTO_INCREMENT"
MySQL.execute!(conn, "CREATE TABLE IF NOT EXISTS author(
                        id INTEGER PRIMARY KEY $AUTOINCREMENT,
                        forename VARCHAR(255),
                        lastname VARCHAR(255) NOT NULL,
                        CONSTRAINT unq UNIQUE(forename,  lastname)
                        );"
                    )

MySQL.disconnect(conn)

MySQL.query(conn, "show tables")