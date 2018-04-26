using DataFrames
using CSV

"""
    fieldnames_unionmissing(t)
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
    toDistinctDataFrame(objects)
Takes a vector of mesh descriptors or qualifiers and returns a data frame with the unique pairs.
"""
function toDistinctDataFrame(objects::Vector{T}) where T <: Union{MeshDescriptor,MeshQualifier}
    # use dictionary to create unique key/value pairs
    unique_vals = Dict{Int,String}()
    map(x -> unique_vals[x.uid] = x.name, objects)

    keys = []
    vals = []
    for (key,val) in unique_vals
        push!(keys, key)
        push!(vals, val)
    end

    return DataFrame(Dict(:uid => keys, :desc => vals))

end

"""
    toDataFrames(articles)
Takes a vector of article objects and returns a dictionary of DataFrames with the field names as column names
and the key names as the lowercase type. Format matches medline load sql tables.
"""

# Multiple dispatch: no ID provided - no parent ID passed to child tables
function toDataFrames(objects::Vector{T}) where T <: PubMedArticle
    dfs = Dict{Symbol, DataFrame}()
    col_pairs = Dict{Symbol,Any}()

    for cols in fieldnames_unionmissing(T)
        vals = getfield.(objects, cols)
        if hasfields(vals)
            if eltype(vals) <: Vector
                push!(dfs, toDataFrames(vals, getfield.(objects, :pmid), :pmid)...)
            else
                for child_cols in fieldnames_unionmissing(typeof(vals))
                    child_vals = getfield.(vals, child_cols)
                    col_pairs[child_cols] = child_vals
                end
            end
        else
            if eltype(vals) <: Vector
                col_pairs[cols] = join(vals, "; ")
            else
                col_pairs[cols] = vals
            end
        end
    end
    dfs[typename_unionmissing(T)] = DataFrame(col_pairs)

    return dfs

end

# Construct Mesh Heading Tables (mesh_Headings : pmid, did, maj, qid, maj ; mesh_desc: did, desc ; mesh_qual: qid, desc)
function toDataFrames(objects::Vector{Vector{T}}, ids::Vector{U}, id_col::Symbol) where T <: MeshHeading
    dfs = Dict{Symbol, DataFrame}()
    mh_pairs = Dict{Symbol,Any}()
    md_pairs = Dict{Int,String}()
    mq_pairs = Dict{Int,String}()

    # flattening out mesh header
    mqs = mapfoldl(x -> getfield.(x, :qualifier), append!, Vector{Any}(), objects)
    mqs_id = getfield.(mqs, :uid)
    mqs_maj = mafoldl(x -> getfield.(x, :qualifier_mjr), append!, Vector{Any}(), objects)
    mds = getfield.(objects, :descriptor)
    mds_id = getfield.(mds, :uid)
    mds_maj = getfield.(objects, :descriptor_mjr)

    # stretching PMIDs to be the fill/length of the number of qualifiers
    ids_desc_length = foldl(append!, Vector{Any}(), map((x,y) -> fill(y, length(x)), mds, ids))
    ids_qual_length = foldl(append!, Vector{Any}(), map((x,y) -> fill(y, length(x)), mqs, ids_desc_length))

    # building mesh heading table
    mh_pairs[id_col] = ids_qual_length
    mh_pairs[:desc_id] = foldl(append!, Vector{Any}(), map((x,y) -> fill(y, length(x)), mqs, mds_id))
    mh_pairs[:desc_maj] = foldl(append!, Vector{Any}(), map((x,y) -> fill(y, length(x)), mqs, mds_maj))
    mh_pairs[:qual_id] = mqs_id
    mh_pairs[:qual_maj] = mqs_maj
    dfs[:meshheading] = DataFrame(mh_pairs)

    # building mesh desc and qual talbes
    dfs[:mesh_desc] = toDistinctDataFrame(mds)
    dfs[:mesh_qual] = toDistinctDataFrame(mqs)

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
                for child_cols in fieldnames_unionmissing(typeof(vals))
                    child_vals = getfield.(vals, child_cols)
                    col_pairs[child_cols] = child_vals
                end
            end
        else
            if eltype(vals) <: Vector
                col_pairs[cols] = join(vals, "; ")
            else
                col_pairs[cols] = vals
            end
        end
    end
    col_pairs[id_col] = foldl(append!, Vector{Any}(), map((x,y) -> fill(y, length(x)), objects, ids))

    dfs[typename_unionmissing(T)] = DataFrame(col_pairs)

    return dfs

end

# # Multiple dispatch, creates child tables without parent IDs
# function toDataFrames(objects::Vector{Vector{T}}) where T <: Any
#     dfs = Dict{Symbol, DataFrame}()
#     col_pairs = Dict{Symbol,Any}()
#
#     for cols in fieldnames_unionmissing(T)
#         vals = mapfoldl(x -> getfield.(x, cols), append!, Vector{Any}(), objects)
#         cols == :uid && return toDataFrames(objects, vals, :uid)
#         if hasfields(vals)
#             if eltype(vals) <: Vector
#                 push!(dfs, toDataFrames(vals)...)
#             else
#                 for child_cols in fieldnames_unionmissing(eltype(vals))
#                     child_vals = getfield.(vals, child_cols)
#                     col_pairs[child_cols] = child_vals
#                 end
#             end
#         else
#             col_pairs[cols] = vals
#         end
#     end
#     dfs[typename_unionmissing(T)] = DataFrame(col_pairs)
#
#     return dfs
#
# end

"""
    dfs_to_csv(dfs::Dict, path::String, [file_prefix::String])
Takes output of toDataFrames and writes to CSV files at the provided path and with the file prefix.
"""
function dfs_to_csv(dfs::Dict{Symbol,DataFrame}, path::String, file_prefix::String="")
    [CSV.write(joinpath(path,"$file_prefix$k.csv"),v, missingstring = "NULL") for (k, v) in dfs]
    return nothing
end
