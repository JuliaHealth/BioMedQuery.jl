using SQLite

"""
    select_columns(db, table)
Return an array with names of columns in the given table
"""
function select_columns(db::SQLite.DB, table::AbstractString)
    cols_query = SQLite.columns(db, table)
    cols_query[:name]
end

"""
    select_all_tables_mysql(con)

Return an array of all tables in a given MySQL database
"""
function select_all_tables(db::SQLite.DB)
    tables_query = DataFrame(SQLite.Query(db, "SELECT name FROM sqlite_master WHERE type='table'"))
    tables_query[1]
end

"""
    query(db, query_code)

Execute a SQLite command
"""
function db_query(db::SQLite.DB, query_code)
    sel = DataFrame(SQLite.Query(db, query_code))
    return sel
end

"""
    insert_row!(db, tablename, values)
Insert a row of values into the specified table for a given a SQLite database handle

### Arguments:

* `db::MySQLDB`: Database object (connection and map)
* `data_values::Dict{String, Any}`: Array of (string) values
* `verbose`: Print debugging info
"""
function insert_row!(db::SQLite.DB, tablename, data_values::Dict{Symbol, T},
    verbose = false) where T

    cols_string, vals_string = assemble_cols_and_vals(data_values)
    lastid = -1
    try
        q = SQLite.execute!(db, "INSERT INTO `$tablename` ($cols_string) values $vals_string")
    catch e
        if verbose
            Base.showerror(stdout, e)
            println("\n")
            @warn "Warning! Could not insert values $vals_string into table $tablename"
        end
        return -1
    end

    lastid_query = DataFrame(SQLite.Query(db, "SELECT last_insert_rowid()"))
    lastid = lastid_query[1][1]

    if ismissing(lastid)
        @warn "Could not insert values $vals_string into table $tablename"
    end
    if verbose
        println("Row successfully inserted into table: $tablename")
    end

    return lastid
end

"""
    disable_foreign_checks(con::SQLite.DB)
Disables foreign checks for SQLite database
"""
function disable_foreign_checks(conn::SQLite.DB)
    SQLite.execute!(conn, "PRAGMA foreign_keys = OFF")

end

"""
    enable_foreign_checks(con::SQLite.DB)
Enables foreign checks for SQLite database
"""
function enable_foreign_checks(conn::SQLite.DB)
    SQLite.execute!(conn, "PRAGMA foreign_keys = ON")

end
