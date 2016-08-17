
module DB

include("entrez_sqlite.jl")

using ..Entrez
using ...DBUtils

"Wrapper around SQLite.Null and MySQL_NULL"
const NULL = Dict(:MySQL=>nothing, :SQLite=>SQLite.NULL)

function init_database(config)

    if Entrez._db_backend[1] == :MySQL

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

           db = init_mysql_database(host = config[:host], dbname =config[:dbname],
           username = config[:username], pswd= config[:pswd],
           overwrite = config[:overwrite], mysql_code = mysql_code)

           return db

       else
            println("Error with following configuration:")
            println(config)
            println("Must contain: host, dbname, username, pswd")
            error("Improper configuration for entrez_mysql:init_database")
        end

    elseif Entrez._db_backend[1] == :SQLite

        println("------Initializing SQLite Database---------")
        if haskey(config, :db_path) && haskey(config, :overwrite)
            db = init_sqlite_database(config[:db_path], config[:overwrite])
        else
            println("Error with following configuration:")
            println(config)
            println("Must contain: db_path")
            error("Improper configuration for entrez_sqlite:init_database")
        end


    else
        error("init_database - Unsupported Database Backend: ", Entrez._db_backend[1])
    end

end

function insert_row(db, tablename, values)
    if Entrez._db_backend[1] == :MySQL
        last_id = insert_row_mysql!(db, tablename, values, true)
    elseif Entrez._db_backend[1] == :SQLite
        last_id = insert_row_sqlite!(db, tablename, values)
    end

end

end #module
