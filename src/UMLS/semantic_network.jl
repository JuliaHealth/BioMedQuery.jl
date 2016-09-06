using MySQL
using ..DBUtils

function populate_net_mysql(config; sn_version="2015AB", mysql_version="mysql5_6")

    println("Populating UMSL S-NET MySQL Database")
    #intput dictionary must have the following keys
    if haskey(config, :host) && haskey(config, :dbname) &&
       haskey(config, :username) && haskey(config, :pswd) &&
       haskey(config, :overwrite)

       mysql_code=nothing

       filename = string(Pkg.dir() , "/BioMedQuery/src/UMLS/NET/", sn_version, "/",
        mysql_version,  "/mysql_net_tables.sql")
       try
           f = open(filename, "r")
           mysql_code = readall(f)
           close(f)
       catch
           error("Could not read $filename")
       end

       sql_data_path = string("infile '", Pkg.dir() , "/BioMedQuery/src/UMLS/NET/", sn_version, "/SR")
       mysql_code = replace(mysql_code, "infile 'SR", sql_data_path)

       db = init_mysql_database(host = config[:host], dbname =config[:dbname],
       username = config[:username], pswd= config[:pswd],
       overwrite = config[:overwrite], mysql_code = mysql_code)
       return db
   else
       error("populate_net_mysql: incorrect db_config")
   end
end


"""
    build_tree_dict()

Build a dictionary that represents the root-leafs hierarchy
"""
function build_tree_dict(db)
    umls_sn_tree = Dict(:name=>"UMLS Semantic Network", :children=>[])
    #get all parents - which are those with a 'isa' relation = NULL
    query_code = "SELECT * FROM SRSTR WHERE `RL`='isa' AND `STY_RL2` is NULL;"
    query = db_query(db, query_code)
    roots = query[1]
    all_keys = Dict{ASCIIString, ASCIIString}()
    for (idx, r) in enumerate(roots)
        root_dict = Dict{Symbol,Any}(:name=>r)
        all_keys[r]= string("[:children]", "[", idx, "]")
        append_children!(db, root_dict, r, all_keys)
        push!(umls_sn_tree[:children],root_dict)
    end

    return umls_sn_tree, all_keys
end


function append_children!(db, parent_dict::Dict{Symbol,Any}, node, all_keys)
    #check if the parent has children
    query_code = "SELECT * FROM SRSTR WHERE `RL`='isa' AND `STY_RL2`='$node'"
    query = db_query(db, query_code)
    children = query[1]
    #if yes recurr
    if !isempty(children)
        parent_dict[:children] = []
        for (idx, child) in enumerate(children)
            node_dict = Dict{Symbol,Any}(:name=>child)
            all_keys[child]= string(all_keys[node], "[:children]", "[", idx, "]")
            append_children!(db, node_dict, child, all_keys)
            push!(parent_dict[:children], node_dict)
        end
    end
end
