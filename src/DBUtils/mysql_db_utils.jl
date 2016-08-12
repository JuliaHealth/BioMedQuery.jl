module MySQLUtils

using MySQL


function init_connect(host, username, pswd)
    # call shell to ensure the MySQL server is running
    if host == "localhost"
        try
            run(`mysql.server start`)
        catch
            warn("Failed to start MySQL server")
        end
    end
    # Connecting to MySQL, but not to a specific DB,
    # we then create DB we want
    con = mysql_connect(host, username, pswd)
end


# This function creates a MySQL database using the code
# passed in the mysql_code argument to set up tables.
function init_mysql_database(con::MySQLHandle, dbname, username, pswd, mysql_code)

    mysql_execute(con, "CREATE DATABASE $dbname;")
    con = mysql_connect(host, username, pswd, dbname)

    mysql_execute(con, mysql_code)

    println("Success! $dbname has been created.")
    return con
end



# This function takes a single quote and replaces it with
# two single quotes. This is what MySQL requires
clean_string(str) = replace(str, "'", "''")

# Inserting rows into the MySQL database seems to require CHAR or
# other non-numeric values be passed with single quotes around them.
# Thus, given a Dict of values, as well as the column names, this
# function returns a single string properly formatted for an insert.

function assemble_vals(data_values::Dict{ASCIIString, Any}, column_names::Array{ASCIIString, 1})
    vals_single_quotes = Array{Any, 1}()        # put values in Array to be joined

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


# Given a database handle (i.e., connection), as well as the table name,
# values, and a dictionary of column names for our tables, this function
# updates the table with the data in data_values.

function insert_row_mysql!(con, tablename, data_values::Dict{ASCIIString, Any}, colname_dict::Dict{ASCIIString, Array{ASCIIString, 1}}, verbose = true)

    table_cols = colname_dict[tablename]
    table_cols_backticks = [string("`", x, "`") for x in table_cols]
    cols_string = join(table_cols_backticks, ", ")
    vals_string = assemble_vals(data_values, table_cols)
    lastid = -1

    try
        lastid = mysql_execute(con, "INSERT INTO `$tablename` ($cols_string) values $vals_string; SELECT LAST_INSERT_ID();")[2][1,1]
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




end # module
