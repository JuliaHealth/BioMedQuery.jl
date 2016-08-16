# using MySQL
# using ...DBUtils
#
# # colname_dict = Dict("article" => ["pmid", "title", "pubYear"])
#
# function init_database(;host = "localhost", dbname ="test", username = "root",
#     pswd= "", overwrite = false)
#     #read mysql code and create database using .sql script
#     mysql_code=""
#     try
#         filename = Pkg.dir() * "/BioMedQuery/src/Entrez/create_entrez_db.sql"
#         println(filename)
#         f = open(filename, "r")
#         mysql_code = readall(f)
#         close(f)
#     catch
#         error("Could not read create_entrez_db.sql")
#     end
#
#     init_mysql_database(host = host, dbname = dbname, username = username,
#     pswd= pswd, overwrite = overwrite, mysql_code = mysql_code)
# end

# function insert_row
#
#     insert_row_mysql!(con, tablename, data_values::Dict{ASCIIString, Any}, colname_dict::Dict{ASCIIString, Array{ASCIIString, 1}}, verbose = true)
#
# end #module
