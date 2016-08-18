using MySQL

"""     MySQLDB

Type to hold a MySQL database connection and a dictionary mapping tables with
their corresponding colums. It is a responsability of the user to keep them
synchronized.That is if new tables or columns are added the dictionary needs
to be updated. One can do so using the function  colname_dict(con)
"""
type MySQLDB
    con #connection
    colname_dict::Dict{Symbol, Array{Symbol, 1}}
end

"""
    init_mysql_database(;host = "localhost", dbname="test",
    username="root", pswd="", mysql_code=nothing, overwrite=false)

Create a MySQL database using the code inside mysql_code

###Arguments
* `host`, `dbname`, `user`, `pswd`
* `mysql_code::ASCIIString`: String with MySQL code that crates all default tables
* `overwrite::Bool` : Flag, if true and dbname exists, it deletes it

###Output
* `con`: Database connection and table-column names map

"""
function init_mysql_database(;host = "localhost", dbname="test",
    username="root", pswd="", mysql_code=nothing, overwrite=false)

    # call shell to ensure the MySQL server is running
    run(`mysql.server start`)

    # Connecting to MySQL, but not to a specific DB,
    # we then create DB we want
    con = mysql_connect(host, username, pswd)

    if overwrite
        mysql_execute(con, "DROP DATABASE IF EXISTS $dbname;")
    end

    mysql_execute(con, "CREATE DATABASE $dbname;")
    con = mysql_connect(host, username, pswd, dbname)

    if mysql_code != nothing
        mysql_execute(con, mysql_code)
        println("Database $dbname created and initialized")
    else
        println("Empty Database Created")
    end

    return con
end


# This function takes a single quote and replaces it with
# two single quotes. This is what MySQL requires
clean_string(str) = replace(str, "'", "''")

"""
    assemble_vals(data_values, column_names)

Given a Dict of values and the column names, return a single string properly
formatted for a MySQL insert. E.g MySQL requires CHAR or
other non-numeric values be passed with single quotes around them.

"""
function assemble_vals{T}(data_values::Dict{Symbol, T}, column_names::Array{Symbol, 1})
    vals_single_quotes = Array{Any, 1}(0)        # put values in Array to be joined

    for k in column_names
        if typeof(data_values[k]) <: Number
            push!(vals_single_quotes, data_values[k])
        elseif data_values[k] == nothing
            push!(vals_single_quotes, "NULL")
        elseif isa(data_values[k], Date)
            push!(vals_single_quotes, string("'", data_values[k], "'"))
        else
            push!(vals_single_quotes, string("'", clean_string(data_values[k]), "'"))
        end
    end
    value_string = string("(", join(vals_single_quotes, ", "), ")")
    return value_string
end



# """
#     colname_dict(con)
# Return a dictionary maping tables and their columns for a given MySQL connection
# """
# function colname_dict(con)
#
#     tables_query = select_all_tables_mysql(con)
#     colname_dict = Dict{Symbol, Array{Symbol, 1}}()
#
#     for table in tables_query.columns[1]
#         cols_query = select_columns_mysql(con, table)
#         cols = [symbol(c) for c in cols_query.columns[1]]
#         colname_dict[symbol(table)] = cols
#     end
#
#     return colname_dict
# end

function select_columns_mysql(con, table)
    cols_query = mysql_execute(con, "SHOW COLUMNS FROM $table;")
    cols_query[1]
end

function select_all_tables_mysql(con)
    tables_query = mysql_execute(con, "SHOW TABLES;")
    tables_query[1]
end

function print_error_mysql(con)
    Base.showerror(STDOUT, MySQLInternalError(con))
    println("\n")
end

function query_mysql(con, query_code)
    try
        sel = mysql_execute(con, query_code)
        return sel
    catch
        print_error_mysql(con)
        error("Failed to perform SELECT")
    end
end

"""
    insert_row_sqlite!(db, tablename, values)
Insert a row of values into the specified table for a given a database handle

###Arguments:
* `db::MySQLDB`: Database object (connection and map)
* `data_values::Dict{ASCIIString, Any}`: Array of (string) values
* `verbose`: Print debugginh info
"""
function insert_row_mysql!{T}(con, tablename, data_values::Dict{Symbol, T},
    colname_dict::Dict{ASCIIString, Array{ASCIIString, 1}}, verbose = true)

    table_cols = colname_dict[symbol(tablename)]
    table_cols_backticks = [string("`", x, "`") for x in table_cols]
    cols_string = join(table_cols_backticks, ", ")
    vals_string = assemble_vals(data_values, table_cols)
    lastid = -1

    try
        lastid = mysql_execute(con, "INSERT INTO `$tablename` ($cols_string) values $vals_string;
         SELECT LAST_INSERT_ID();")[2][1,1]
    catch
        Base.showerror(STDOUT, MySQLInternalError(con))
        println("\n")
        error("Row not inserted into the table: $tablename")
    end
    if verbose
        println("Row successfully inserted into table: $tablename")
    end
    return lastid
end


"""
    insert_row_sqlite!(db, tablename, values)
Insert a row of values into the specified table for a given a database handle

###Arguments:
* `db::MySQLDB`: Database object (connection and map)
* `data_values::Dict{ASCIIString, Any}`: Array of (string) values
* `verbose`: Print debugginh info
"""
function insert_row_mysql!{T}(con, tablename, data_values::Dict{Symbol, T},
    verbose = true)

    cols_string, vals_string = assemble_cols_and_vals(data_values)
    lastid = -1
    q = query_mysql(con, "INSERT INTO `$tablename` ($cols_string) values $vals_string;
     SELECT LAST_INSERT_ID();")
    lastid = q[2][1,1]
    if verbose
        println("Row successfully inserted into table: $tablename")
    end
    return lastid
end


function find_duplicate_id_mysql{T}(con, colnames, tablename, data_values::Dict{Symbol, T})
end
