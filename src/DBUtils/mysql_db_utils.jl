using MySQL
# using DataStreams
using DataFrames

"""
    init_mysql_database(;host = "127.0.0.1", dbname="test",
    username="root", pswd="", mysql_code=nothing, overwrite=false, opts=Dict())

Create a MySQL database using the code inside mysql_code

### Arguments

* `host`, `dbname`, `user`, `pswd`
* `mysql_code::String`: String with MySQL code that crates all default tables
* `overwrite::Bool` : Flag, if true and dbname exists, drops all database and re-creates it
* `opts::Dict` : Dictionary containing MySQL connection options

### Output

* `con`: Database connection and table-column names map

"""
function init_mysql_database(host="127.0.0.1",
    user="root", pswd="", dbname="test"; overwrite=false, opts = Dict())

    opts[MySQL.API.MYSQL_SET_CHARSET_NAME] = "utf8mb4"

    con = MySQL.connect(host, user, pswd, opts=opts)

    init_mysql_database(con, dbname, overwrite)
end

function init_mysql_database(con::MySQL.Connection, dbname="test", overwrite=false)

    q = MySQL.Query(con, "SHOW DATABASES LIKE '$dbname'; ") |> DataFrame
    if size(q)[1] > 0
        if overwrite
            println("Set to overwrite MySQL database $dbname")
            MySQL.execute!(con, "DROP DATABASE IF EXISTS $dbname;")
            MySQL.execute!(con, "CREATE DATABASE $dbname
                CHARACTER SET utf8mb4;")
        end
    else
        MySQL.execute!(con, "CREATE DATABASE $dbname
            CHARACTER SET utf8mb4;")
    end


    MySQL.execute!(con, "USE $dbname;")

    return con
end


"""
    select_columns_mysql(con, table)

For a MySQL database, return an array of all columns in the given table
"""
function select_columns(con::MySQL.MySQLHandle, table)
    cols_query = MySQL.Query(con, "SHOW COLUMNS FROM $table;") |> DataFrame
    cols_query[1]
end

"""
    select_all_tables_mysql(con)

Return an array of all tables in a given MySQL database
"""
function select_all_tables(con::MySQL.MySQLHandle)
    tables_query = MySQL.Query(con, "SHOW TABLES;") |> DataFrame
    tables_query[1]
end

function print_error(con::MySQL.MySQLHandle)
    Base.showerror(stdout, MySQL.MySQLInternalError(con))
    println("\n")
end

"""
    query_mysql(con, query_code)

Execute a mysql command
"""
function db_query(con::MySQLHandle, query_code)
    try
        sel = MySQL.Query(con, query_code) |> DataFrame
        return sel
    catch
        #error("There was an error with MySQL")
        throw(MySQL.MySQLInternalError(con))
    end
end

function insert_row!(con::MySQL.MySQLHandle, tablename, data_values::Dict{Symbol, T},
    colname_dict::Dict{String, Array{String, 1}}, verbose = false) where T

    table_cols = colname_dict[symbol(tablename)]
    table_cols_backticks = [string("`", x, "`") for x in table_cols]
    cols_string = join(table_cols_backticks, ", ")
    vals_string = assemble_vals(data_values, table_cols)
    lastid = -1

    try
        MySQL.execute!(con, "INSERT INTO `$tablename` ($cols_string) values $vals_string;")
        lastid = MySQL.insertid(con)
    catch e
        # Base.showerror(STDOUT, MySQLInternalError(con))
        @warn "Warning: Row with values $vals_string not inserted into the table: $tablename"
        # throw(MySQLInternalError(con))
    end

    return lastid
end


"""
    insert_row!(db, tablename, values)
Insert a row of values into the specified table for a given a MySQL database handle

### Arguments:

* `db::MySQLDB`: Database object (connection and map)
* `data_values::Dict{String, Any}`: Array of (string) values
* `verbose`: Print debugging info
"""
function insert_row!(con::MySQL.MySQLHandle, tablename, data_values::Dict{Symbol, T},
    verbose = false) where T

    cols_string, vals_string = assemble_cols_and_vals(data_values)
    lastid = -1
    try
        MySQL.execute!(con, "INSERT INTO `$tablename` ($cols_string) values $vals_string;")
        lastid = MySQL.insertid(con)
    catch
        if verbose
            println("Warning! Row with values $vals_string not inserted into the table: $tablename")
            Base.showerror(stdout, MySQL.MySQLInternalError(con))
            println("\n")
        end
        # throw(MySQLInternalError(con))
    end
    return lastid
end

function create_server(con::MySQL.MySQLHandle, dbname; linkname = "fedlink", user="root", psswd="", host="127.0.0.1", port=3306)

    query_str = "CREATE SERVER $linkname
                 FOREIGN DATA WRAPPER mysql
                 OPTIONS (USER '$user', PASSWORD '$psswd', HOST '$host', PORT $port, DATABASE '$dbname');"

    MySQL.Query(con, query_str) |> DataFrame
end

"""
    disable_foreign_checks(con::MySQL.MySQLHandle)
Disables foreign checks for MySQL database
"""
function disable_foreign_checks(conn::MySQL.MySQLHandle)
    MySQL.execute!(conn, "SET FOREIGN_KEY_CHECKS = 0")
    return nothing
end

"""
    enable_foreign_checks(con::MySQL.MySQLHandle)
Enables foreign checks for MySQL database
"""
function enable_foreign_checks(conn::MySQL.MySQLHandle)
    MySQL.execute!(conn, "SET FOREIGN_KEY_CHECKS = 1")
    return nothing
end

"""
    set_innodb_checks(conn, autocommit = 1, foreign_keys = 1, unique = 1)
"""
function set_innodb_checks!(conn::MySQL.Connection, autocommit::Int = 1, foreign_keys::Int = 1, unique::Int = 1)
    MySQL.execute!(conn, "SET FOREIGN_KEY_CHECKS = $foreign_keys")
    MySQL.execute!(conn, "SET AUTOCOMMIT = $autocommit")
    MySQL.execute!(conn, "SET UNIQUE_CHECKS = $unique")
    return nothing
end
