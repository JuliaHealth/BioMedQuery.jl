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


"""
    assemble_vals(data_values, column_names)

Given a Dict of values and the column names, return a single string properly
formatted for a MySQL insert. E.g MySQL requires CHAR or
other non-numeric values be passed with single quotes around them.

"""
function assemble_cols_and_vals{T}(data_values::Dict{Symbol, T})
    vals_single_quotes = Array{Any, 1}(length(data_values))        # put values in Array to be joined
    table_cols_backticks = Array{ASCIIString}(length(data_values))
    for (i, (key,val)) in enumerate(data_values)
        table_cols_backticks[i] = string("`", key, "`")
        if typeof(val) <: Number
            vals_single_quotes[i] = val
        elseif val == nothing
            vals_single_quotes[i] = "NULL"
        elseif isa(val, Date)
            vals_single_quotes[i] = string("'", val, "'")
        else
            vals_single_quotes[i] = string("'", clean_string(val), "'")
        end
    end
    cols_string = join(table_cols_backticks, ", ")
    value_string = string("(", join(vals_single_quotes, ", "), ")")
    return cols_string, value_string
end

"""
    assemble_vals(data_values, column_names)

Given a Dict of values and the column names, return a single string properly
formatted for a MySQL insert. E.g MySQL requires CHAR or
other non-numeric values be passed with single quotes around them.

"""
function assemble_cols_and_vals_select{T}(data_values::Dict{Symbol, T}, op = "AND")
    val_single_quotes::Any = nothing        # put values in Array to be joined
    col_backticks::ASCIIString = ""
    select_string_array = Array{ASCIIString}(length(data_values))
    for (i, (key,val)) in enumerate(data_values)
        println("i: ", i, " key: ", key, " val: ", val)
        col_backticks = string("`", key, "`")
        if typeof(val) <: Number
            val_single_quotes=val
        elseif val == nothing
            val_single_quotes = "NULL"
        elseif isa(val, Date)
            val_single_quotes=string("'", val, "'")
        else
            val_single_quotes=string("'", clean_string(val), "'")
        end
        println(val_single_quotes)
        select_string_array[i] = string(col_backticks, "=" , val_single_quotes)
    end
    select_string = join(select_string_array, string(" ", op, " "))
    return select_string
end

"""
    colname_dict(con)
Return a dictionary maping tables and their columns for a given MySQL connection
"""
function colname_dict(con)

    tables_query = mysql_execute(con, "SHOW TABLES;")
    colname_dict = Dict{Symbol, Array{Symbol, 1}}()

    for table in tables_query.columns[1]
        col_query = mysql_execute(con, "SHOW COLUMNS FROM $table;")
        cols = [symbol(c) for c in col_query.columns[1]]
        colname_dict[symbol(table)] = cols
    end

    return colname_dict
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
    SELECT colonames tablename WHERE keys(data_values)=values(data_values)
"""
function select{T}(con, colnames, tablename, data_values::Dict{Symbol, T})
    select_cols_backticks = [string("`", x, "`") for x in colnames]
    select_cols_string = join(select_cols_backticks, ", ")
    select_string = assemble_cols_and_vals_select(data_values)
    try
        lastid = mysql_execute(con, "SELECT $select_cols_string FROM `$tablename` WHERE $select_string;")
        return lastid
    catch
        Base.showerror(STDOUT, MySQLInternalError(con))
        println("\n")
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
    verbose = true)

    cols_string, vals_string = assemble_cols_and_vals(data_values)
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
