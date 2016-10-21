
# Julia executable to populate UMLS Semantic Network Database
# Example of how to use from terminal (inside this file directory):
# ```
#     julia populate_net.jl --clean_db mysql --host "localhost" --username "root --password "" --dbname "umls_sn"
# ```

using ArgParse
using BioMedQuery.UMLS

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "--clean_db"
            help = "Flag indicating wether to empty database"
            action = :store_true
        "mysql"
             help = "Use MySQL backend"
             action = :command
    end
    @add_arg_table s["mysql"] begin
        "--host"
             help = "Host where you database lives"
             arg_type = String
             default = "localhost"
        "--dbname"
             help = "Database name"
             arg_type = String
             required = true
        "--username"
             help = "MySQL username"
             arg_type = String
             default = "root"
        "--password"
             help = "MySQL password"
             arg_type = String
             default = ""
    end
    return parse_args(s)
end

function main()
    parsed_args = parse_commandline()
    println("Parsed args:")
    for (arg,val) in parsed_args
        println("  $arg  =>  $val")
    end

    if haskey(parsed_args, "mysql")
        db_config = Dict(:host=>parsed_args["mysql"]["host"],
        :dbname=>parsed_args["mysql"]["dbname"],
        :username=>parsed_args["mysql"]["username"],
        :pswd=>parsed_args["mysql"]["password"],
        :overwrite=>parsed_args["clean_db"])
    else
        error("Unsupported database backend")
    end

    populate_net_mysql(db_config)

end

main()
