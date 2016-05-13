module xml
export xml2dict, show_key_structure


using LightXML, DataStructures

function has_any_children(node_element)
    if length(collect(child_elements(node_element))) > 0
        res = true
    else
        res = false
    end
    return res
end


function isnumeric(x)
    res = false
    try
        res = typeof(parse(x)) <: Number
    end
    return res
end




# This function converts (recursively) XML files to a nested
# multi-dictionary that handles chidlren with the same name. The
# optional replace_newline argument can be used to remove or
# replace any newline characters.

function xml2dict(element_node, replace_newline = nothing)



    if has_any_children(element_node)
        ces = collect(child_elements(element_node))
        dict_res = MultiDict{Any, Any}()
        for c in ces
            childname = name(c)
            value = xml2dict(c, replace_newline)
            if isa(value, ASCIIString) && isnumeric(value)
                value = parse(value)
            elseif !isa(replace_newline, Void) && isa(value, ASCIIString)
                value = replace(value, "\n", replace_newline)
            end
            insert!(dict_res, childname, value)
        end
        return dict_res
    else
        return content(element_node)
    end
end






function is_multidict(obj)
    if typeof(obj) == DataStructures.MultiDict{Any, Any}
        res = true
    else
        res = false
    end
    return res
end


# Given an integer, `nspaces`, this function returns
# and ASCIIString with that number of black characters.

function get_indentation(nspaces)
    res = ""
    for i = 1:nspaces
        res *= " "
    end
    return res
end


# This function prints the keys structure of a
# parsed XML file.

function show_key_structure(xmldict_obj, nspaces = 4)
    if is_multidict(xmldict_obj)
        keys_array = collect(keys(xmldict_obj))
        indent_str = get_indentation(nspaces)
        for k in keys_array
            println(indent_str, "-", k)
            if is_multidict(xmldict_obj[k]) || typeof(xmldict_obj[k]) == Array{Any, 1}
                num_elem = length(xmldict_obj[k])
                for i = 1:num_elem
                    show_key_structure(xmldict_obj[k][i], nspaces + 4)
                    if i < num_elem
                        println(indent_str, "-", k)
                    end
                end
            end
        end
    end
end



end         # end module
