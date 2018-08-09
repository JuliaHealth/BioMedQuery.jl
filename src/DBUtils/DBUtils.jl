using Dates
using DataFrames

include("mysql_db_utils.jl")
include("sqlite_db_utils.jl")

# This function takes a single quote and replaces it with
# two single quotes. This is what MySQL requires
db_clean_string(str) = replace(str, "'" => "''")

"""
    assemble_vals(data_values)

Given a dictionary containg (:column=>value) return a single string properly
formatted for a MySQL insert. E.g MySQL requires CHAR or
other non-numeric values be passed with single quotes around them.

"""
function assemble_cols_and_vals(data_values::Dict{Symbol, T}) where T
    vals_single_quotes = Vector{Any}(undef, length(data_values))        # put values in Array to be joined
    table_cols_backticks = Vector{String}(undef, length(data_values))

    for (i, (key,val)) in enumerate(data_values)
        table_cols_backticks[i] = string("`", key, "`")
        if typeof(val) <: Number && !ismissing(val)
            vals_single_quotes[i] = val
        elseif ismissing(val)
            vals_single_quotes[i] = "NULL"
        elseif val == nothing
            vals_single_quotes[i] = "NULL"
        elseif isa(val, Date)
            vals_single_quotes[i] = string("'", val, "'")
        else
            vals_single_quotes[i] = string("'", db_clean_string(val), "'")
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
function assemble_vals(data_values::Dict{Symbol, T}, column_names::Array{Symbol, 1}) where T
    vals_single_quotes = Vector{Any}()        # put values in Array to be joined

    for k in column_names
        if typeof(data_values[k]) <: Number
            push!(vals_single_quotes, data_values[k])
        elseif data_values[k] == nothing
            push!(vals_single_quotes, "NULL")
        elseif isa(data_values[k], Date)
            push!(vals_single_quotes, string("'", data_values[k], "'"))
        else
            push!(vals_single_quotes, string("'", db_clean_string(data_values[k]), "'"))
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
function assemble_cols_and_vals_string(data_values::Dict{Symbol, T}, op = "AND") where T
    val_single_quotes::Any = nothing        # put values in Array to be joined
    col_backticks::String = ""
    select_string_array = Array{String}(undef, length(data_values))

    for (i, (key,val)) in enumerate(data_values)
        col_backticks = string("`", key, "`")
        if typeof(val) <: Number && !ismissing(val)
            val_single_quotes=val
        elseif val == nothing || ismissing(val)
            val_single_quotes = "NULL"
        elseif isa(val, Date)
            val_single_quotes=string("'", val, "'")
        else
            val_single_quotes=string("'", db_clean_string(val), "'")
        end

        select_string_array[i] = string(col_backticks, "=" , val_single_quotes)
    end
    select_string = join(select_string_array, string(" ", op, " "))
    return select_string
end

function assemble_cols_and_vals_select(data_values::Dict{Symbol, T}, op = "AND") where T
    assemble_cols_and_vals_string(data_values, "AND")
end

"""
    assemble_cols(data_values::DataFrame)
Given a DataFrame, returns a column name string formatted for an insert/load statement
"""
function assemble_cols(data_values::DataFrame)
    col_str = ""
    for col in getfield(data_values, :colindex).names
        col_str *= string(col) * ","
    end
    return col_str[1:end-1]
end

#*****************
# colname_dict
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
function db_select(con, colnames, tablename, data_values::Dict{Symbol, T}) where T
    select_cols_backticks = [string("`", x, "`") for x in colnames]
    select_cols_string = join(select_cols_backticks, ", ")
    select_string = assemble_cols_and_vals_select(data_values)
    sel = db_query(con, "SELECT $select_cols_string FROM `$tablename` WHERE $select_string;")
    sel
end


"""
    col_match(con, tablename, data_values)
Checks if each column in the dataframe has a matching column in the table.
"""
function col_match(con, tablename::String, data_values::DataFrame)
    cols = String.(getfield(data_values, :colindex).names)
    col_match(con, tablename, cols)
end


"""
    col_match(con, tablename, col_names)
Checks if each column in the csv/data frame has a matching column in the table.
"""
function col_match(con, tablename::String, col_names::Vector{String})
    all_match = true

    table_cols = select_columns(con, tablename)

    for col in col_names
        this_match = false
        for tc in table_cols
            if tc == string(col)
                this_match = true
                break
            end
        end
        if this_match == false
            all_match = false
            break
        end
    end

    return all_match
end
