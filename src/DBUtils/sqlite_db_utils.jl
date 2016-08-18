using SQLite

"""
Return an array with names of columns in the given table
"""
function select_columns_sqlite(db, table)
    cols_query = SQLite.query(db, "SHOW COLUMNS FROM $table;")
    cols_query[2]
end

function select_all_tables_sqlite(db)
    tables_query = SQLite.query(db, "SELECT name FROM sqlite_master WHERE type='table'")
    tables_query[1].values
end

# function print_error_sqlite(db)
#     Base.showerror(STDOUT, MySQLInternalError(db))
#     println("\n")
# end


function query_sqlite(db, query_code)
    try
        sel = SQLite.query(db, query_code)
        return sel
    catch
        error("Failed to perform SQLite SELECT")
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
function insert_row_sqlite!{T}(db, tablename, data_values::Dict{Symbol, T},
    verbose = true)

    cols_string, vals_string = assemble_cols_and_vals(data_values)
    lastid = -1
    q = query_sqlite(db, "INSERT INTO `$tablename` ($cols_string) values $vals_string")
    lastid_query = query_sqlite(db, "SELECT last_insert_rowid()")
    lastid = get(lastid_query[1][1], -1)
    if verbose
        println("Row successfully inserted into table: $tablename")
    end
    return lastid
end
