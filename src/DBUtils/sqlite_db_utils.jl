using SQLite

"""
    select_columns_sqlite(db, table)
Return an array with names of columns in the given table
"""
function select_columns_sqlite(db, table)
    cols_query = SQLite.query(db, "SHOW COLUMNS FROM $table;")
    cols_query[2]
end

"""
    select_all_tables_mysql(con)

Return an array of all tables in a given MySQL database
"""
function select_all_tables_sqlite(db)
    tables_query = SQLite.query(db, "SELECT name FROM sqlite_master WHERE type='table'")
    tables_query[1].values
end

"""
    query_sqlite(db, query_code)

Execute a SQLite command
"""
function query_sqlite(db, query_code)
    try
        sel = SQLite.query(db, query_code)
        return sel
    catch
        SQLite.sqliteerror(db)
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
    verbose = false)

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
