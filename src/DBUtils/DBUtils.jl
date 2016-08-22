include("mysql_db_utils.jl")
include("sqlite_db_utils.jl")

"""
    assemble_vals(data_values)

Given a dictionary containg (:column=>value) return a single string properly
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
formatted for a MySQL INSERT. E.g MySQL requires CHAR or
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
    assemble_vals(data_values)

Given a dictionary containg (:column=>value), return a single string properly
formatted for a MySQL SELECT. E.g MySQL requires CHAR or
other non-numeric values be passed with single quotes around them.

"""
function assemble_cols_and_vals_select{T}(data_values::Dict{Symbol, T}, op = "AND")
    val_single_quotes::Any = nothing        # put values in Array to be joined
    col_backticks::ASCIIString = ""
    select_string_array = Array{ASCIIString}(length(data_values))
    for (i, (key,val)) in enumerate(data_values)
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
        select_string_array[i] = string(col_backticks, "=" , val_single_quotes)
    end
    select_string = join(select_string_array, string(" ", op, " "))
    return select_string
end

#*****************
# colname_dict_
#*****************
"""
    colname_dict_(con)
Return a dictionary maping tables and their columns for a given
MySQL-connection/SQLite-database
"""
function colname_dict(con)

    tables_query = select_all_tables(con)
    colname_dict = Dict{Symbol, Array{Symbol, 1}}()

    for table in tables_query
        cols_query = select_columns(con, table)
        cols = [symbol(c) for c in cols_query]
        colname_dict[symbol(table)] = cols
    end

    return colname_dict
end

#*****************
# select
#*****************
"""
    select_(con, colnames, tablename, data_values)

Perform: SELECT colnames tablename WHERE keys(data_values)=values(data_values)
"""
function db_select{T}(con, colnames, tablename, data_values::Dict{Symbol, T})
    select_cols_backticks = [string("`", x, "`") for x in colnames]
    select_cols_string = join(select_cols_backticks, ", ")
    select_string = assemble_cols_and_vals_select(data_values)
    sel = db_query(con, "SELECT $select_cols_string FROM `$tablename` WHERE $select_string;")
    sel
end
