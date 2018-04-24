
using DataFrames
using CSV


"""
    toDataFrames(articles, [id_col])
Takes a vector of article (or any) objects and returns a dictionary of DataFrames with the field names as column names
and the key names as the lowercase type. Optionally, a column can be marked as the identifier that should propogate to any child tables (e.g. :pmid).
"""
function toDataFrames(objects::Vector{T}, id_col::Symbol) where T <: Any
    dfs = Dict{Symbol, DataFrame}()

    col_pairs = Dict{Symbol,Any}()
    for cols in fieldnames(T)
        vals = getfield.(objects, cols)
        if eltype(vals) <: Vector
            push!(dfs, toDataFrames(vals, getfield.(objects, id_col), id_col)...)
        else
            col_pairs[cols] = vals
        end
    end
    dfs[Symbol(lowercase(string(T)))] = DataFrame(col_pairs)

    return dfs

end

# Multiple dispatch: no ID provided - no parent ID passed to child tables
function toDataFrames(objects::Vector{T}) where T <: Any
    dfs = Dict{Symbol, DataFrame}()

    col_pairs = Dict{Symbol,Any}()
    for cols in fieldnames(T)
        vals = getfield.(objects, cols)
        if eltype(vals) <: Vector
            push!(dfs, toDataFrames(vals)...)
        else
            col_pairs[cols] = vals
        end
    end
    dfs[Symbol(lowercase(string(T)))] = DataFrame(col_pairs)

    return dfs

end

# Multiple dispatch, creates child tables with parent IDs
function toDataFrames(objects::Vector{Vector{T}}, ids::Vector{U}, id_col::Symbol) where T <: Any where U <: Any
    dfs = Dict{Symbol, DataFrame}()

    col_pairs = Dict{Symbol,Any}()

    for cols in fieldnames(T)
        vals = mapfoldl(x -> getfield.(x, cols), append!, Vector{Any}(), objects)
        if eltype(vals) <: Vector
            push!(dfs, toDataFrames(vals)...)
        else
            col_pairs[cols] = vals
        end
    end
    col_pairs[id_col] = foldl(append!, Vector{Any}(), map((x,y) -> fill(y, length(x)), objects, ids))

    dfs[Symbol(lowercase(string(T)))] = DataFrame(col_pairs)

    return dfs

end

# Multiple dispatch, creates child tables without parent IDs
function toDataFrames(objects::Vector{Vector{T}}) where T <: Any
    dfs = Dict{Symbol, DataFrame}()

    col_pairs = Dict{Symbol,Any}()
    for cols in fieldnames(T)
        vals = mapfoldl(x -> getfield.(x, cols), append!, Vector{Any}(), objects)
        if eltype(vals) <: Vector
            push!(dfs, toDataFrames(vals)...)
        else
            col_pairs[cols] = vals
        end
    end
    dfs[Symbol(lowercase(string(T)))] = DataFrame(col_pairs)

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
