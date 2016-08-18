__precompile__()
include("mysql_db_utils.jl")
include("sqlite_db_utils.jl")

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

#*****************
# colname_dict
#*****************
for f in [:mysql, :sqlite]
    f_str = Symbol(string("colname_dict_", f))
    f_select_tables = Symbol(string("select_all_tables_", f))
    f_select_cols = Symbol(string("select_columns_", f))
    @eval begin
        """
            colname_dict_(con)
        Define two function to return a dictionary maping tables and their columns for a given
        MySQL-connection/SQLite-database
        """
        function ($f_str)(con)

            tables_query = ($f_select_tables)(con)
            colname_dict = Dict{Symbol, Array{Symbol, 1}}()

            for table in tables_query
                cols_query = ($f_select_cols)(con, table)
                cols = [symbol(c) for c in cols_query]
                colname_dict[symbol(table)] = cols
            end

            return colname_dict
        end
    end
end

#*****************
# select
#*****************
for f in [:mysql, :sqlite]
    f_str = Symbol(string("select_", f))
    f_query = Symbol(string("query_", f))
    @eval begin
        """
            SELECT colnames tablename WHERE keys(data_values)=values(data_values)
        """
        function ($f_str){T}(con, colnames, tablename, data_values::Dict{Symbol, T})
            select_cols_backticks = [string("`", x, "`") for x in colnames]
            select_cols_string = join(select_cols_backticks, ", ")
            select_string = assemble_cols_and_vals_select(data_values)
            sel = ($f_query)(con, "SELECT $select_cols_string FROM `$tablename` WHERE $select_string;")
            sel
        end
    end
end
