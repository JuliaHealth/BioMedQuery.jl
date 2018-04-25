
using DataFrames
using CSV

"""
    fieldnames_unionmissing(t, a)
Returns fieldnames is not a union, and if is a union, returns the non-missing, fieldnames.
"""
function fieldnames_unionmissing(t)
    if typeof(t) <: Union
        return t.a <: Missing ? fieldnames(t.b) : fieldnames(t.a)
    else
        return fieldnames(t)
    end
end

"""
    typename_unionmissing(t)
Given a type if it is a union of missing and something, returns :something, else returns :t
"""
function typename_unionmissing(t)
    tnm = ""
    if typeof(t) <: Union
        tnm = t.a <: Missing ? string(t.b) : string(t.a)
    else
        tnm = string(t)
    end
    return Symbol(lowercase(split(tnm,".")[end]))
end

"""
    hasfields(v::Vector)
Checks if the innter type of a Vector has fields to iterate through
"""
function hasfields(v::Vector{T}) where T <: Any
    try
        num_fields = length(fieldnames_unionmissing(T))
        return num_fields > 1 ? true : false
    catch
        return false
    end
end

function hasfields(v::Vector{Vector{T}}) where T <: Any
    try
        num_fields = length(fieldnames_unionmissing(T))
        return num_fields > 1 ? true : false
    catch
        return false
    end
end

"""
    toDataFrames(articles, id_col=:uid)
Takes a vector of article objects and returns a dictionary of DataFrames with the field names as column names
and the key names as the lowercase type. Optionally, a column can be marked as the identifier that should propogate to any child tables (e.g. :pmid).
"""
function toDataFrames(objects::Vector{T}, id_col::Symbol) where T <: Any
    dfs = Dict{Symbol, DataFrame}()
    col_pairs = Dict{Symbol,Any}()

    for cols in fieldnames_unionmissing(T)
        vals = getfield.(objects, cols)
        if hasfields(vals)
            if eltype(vals) <: Vector
                push!(dfs, toDataFrames(vals, getfield.(objects, id_col), id_col)...)
            else
                for child_cols in fieldnames_unionmissing(eltype(vals))
                    child_vals = getfield.(vals, child_cols)
                    col_pairs[child_cols] = child_vals
                end
            end
        else
            col_pairs[cols] = vals
        end
    end
    dfs[typename_unionmissing(T)] = DataFrame(col_pairs)

    return dfs

end

# Multiple dispatch: no ID provided - no parent ID passed to child tables
function toDataFrames(objects::Vector{T}) where T <: Any
    dfs = Dict{Symbol, DataFrame}()
    col_pairs = Dict{Symbol,Any}()

    for cols in fieldnames_unionmissing(T)
        cols == :uid && return toDataFrames(objects, :uid)
        vals = getfield.(objects, cols)
        if hasfields(vals)
            if eltype(vals) <: Vector
                push!(dfs, toDataFrames(vals)...)
            else
                for child_cols in fieldnames_unionmissing(eltype(vals))
                    child_vals = getfield.(vals, child_cols)
                    col_pairs[child_cols] = child_vals
                end
            end
        else
            col_pairs[cols] = vals
        end
    end
    dfs[typename_unionmissing(T)] = DataFrame(col_pairs)

    return dfs

end

# Multiple dispatch, creates child tables with parent IDs
function toDataFrames(objects::Vector{Vector{T}}, ids::Vector{U}, id_col::Symbol) where T <: Any where U <: Any
    dfs = Dict{Symbol, DataFrame}()
    col_pairs = Dict{Symbol,Any}()

    for cols in fieldnames_unionmissing(T)
        vals = mapfoldl(x -> getfield.(x, cols), append!, Vector{Any}(), objects)
        if hasfields(vals)
            if eltype(vals) <: Vector
                push!(dfs, toDataFrames(vals)...)
            else
                for child_cols in fieldnames_unionmissing(eltype(vals))
                    child_vals = getfield.(vals, child_cols)
                    col_pairs[child_cols] = child_vals
                end
            end
        else
            col_pairs[cols] = vals
        end
    end
    col_pairs[id_col] = foldl(append!, Vector{Any}(), map((x,y) -> fill(y, length(x)), objects, ids))

    dfs[typename_unionmissing(T)] = DataFrame(col_pairs)

    return dfs

end

# Multiple dispatch, creates child tables without parent IDs
function toDataFrames(objects::Vector{Vector{T}}) where T <: Any
    dfs = Dict{Symbol, DataFrame}()
    col_pairs = Dict{Symbol,Any}()

    for cols in fieldnames_unionmissing(T)
        vals = mapfoldl(x -> getfield.(x, cols), append!, Vector{Any}(), objects)
        cols == :uid && return toDataFrames(objects, vals, :uid)
        if hasfields(vals)
            if eltype(vals) <: Vector
                push!(dfs, toDataFrames(vals)...)
            else
                for child_cols in fieldnames_unionmissing(eltype(vals))
                    child_vals = getfield.(vals, child_cols)
                    col_pairs[child_cols] = child_vals
                end
            end
        else
            col_pairs[cols] = vals
        end
    end
    dfs[typename_unionmissing(T)] = DataFrame(col_pairs)

    return dfs

end

"""
    dfs_to_csv(dfs::Dict, path::String, [file_prefix::String])
Takes output of toDataFrames and writes to CSV files at the provided path and with the file prefix.
"""
function dfs_to_csv(dfs::Dict{Symbol,DataFrame}, path::String, file_prefix::String="")
    [CSV.write(joinpath(path,"$file_prefix$k.csv"),v) for (k, v) in dfs]
    return nothing
end
