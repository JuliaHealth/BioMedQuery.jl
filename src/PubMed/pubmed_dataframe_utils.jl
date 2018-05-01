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
    mh_dict_transpose(dict::Dict)

Given a dictionary of mesh descriptors or qualifiers, returns an array of the keys and values.
"""
function mh_dict_transpose(dict::Dict{Int64,String})
    keys = Vector{Int64}()
    vals = Vector{String}()

    for (key, val) in dict
        push!(keys, key)
        push!(vals, val)
    end

    return keys, vals
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
                for child_cols in fieldnames_unionmissing(eltype(vals))
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

    dfs[:abstractfull] = DataFrame(pmid = col_pairs[:pmid], abstract_text = col_pairs[:abstract_full])

    delete!(col_pairs,:abstract_full)

    dfs[typename_unionmissing(T)] = DataFrame(col_pairs)

    return dfs

end


# Construct Mesh Heading Tables (mesh_Headings : pmid, did, maj, qid, maj ; mesh_desc: did, desc ; mesh_qual: qid, desc)
function toDataFrames(objects::Vector{Vector{T}}, ids::Vector{U}, id_col::Symbol) where T <: Union{MeshHeading,Missing} where U <: Any
    dfs = Dict{Symbol, DataFrame}()

    ids_mh_length = foldl(append!, Vector{Any}(), map((x,y) -> fill(y, length(x)), objects, ids))

    nrows = length(objects)

    pmid = Vector{Int64}()
    desc_id = Vector{Int64}()
    desc_maj_status = Vector{Int64}()
    qual_id = Vector{Int64}()
    qual_maj_status = Vector{Int64}()

    mesh_descs = Dict{Int64,String}()
    mesh_quals = Dict{Int64,String}()


    for i in 1:nrows
        for mh in objects[i]
            for k in 1:length(mh.qualifier)
                push!(pmid,ids[i])
                push!(desc_id, mh.descriptor.uid)
                push!(desc_maj_status, mh.descriptor_mjr)
                push!(qual_id, mh.qualifier[k].uid)
                push!(qual_maj_status, mh.qualifier_mjr[k])

                mesh_quals[mh.qualifier[k].uid] = mh.qualifier[k].name
            end
            mesh_descs[mh.descriptor.uid] = mh.descriptor.name
        end
    end

    dfs[:meshheading] = DataFrame(pmid = pmid, desc_id = desc_id, desc_maj_status = desc_maj_status, qual_id = qual_id, qual_maj_status = qual_maj_status)

    desc_keys, desc_vals = mh_dict_transpose(mesh_descs)
    qual_keys, qual_vals = mh_dict_transpose(mesh_quals)

    dfs[:meshdescriptor] = DataFrame(uid = desc_keys, description = desc_vals)
    dfs[:meshqualifier] = DataFrame(uid = qual_keys, description = qual_vals)

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

"""
    dfs_to_csv(dfs::Dict, path::String, [file_prefix::String])
Takes output of toDataFrames and writes to CSV files at the provided path and with the file prefix.
"""
function dfs_to_csv(dfs::Dict{Symbol,DataFrame}, path::String, file_prefix::String="")
    [CSV.write(joinpath(path,"$file_prefix$k.csv"),v, missingstring = "NULL") for (k, v) in dfs]
    return nothing
end
