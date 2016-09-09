# Example Julia script with typical workflow to populate a MESH2UMLS database
# table relating all concets associated with all MESH terms in the input database
# Date: September 6, 2016
# Authors: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5

using SQLite
using MySQL
using BioMedQuery.Processes
using BioMedQuery.UMLS

user = ENV["UMLS_USER"]
psswd = ENV["UMLS_PSSWD"]
credentials = Credentials(user, psswd)
append = false
db = nothing

#Database backend
using_sqlite=false
using_mysql=true

if using_sqlite
    #************************ LOCALS TO CONFIGURE!!!! **************************
    db_path="./pubmed_obesity_2010_2012.db"
    #***************************************************************************
    db = SQLite.DB(db_path)
elseif using_mysql
    #************************ LOCALS TO CONFIGURE!!!! **************************
    host="localhost" #If want to hide - use enviroment variables instead
    mysql_usr="root"
    mysql_pswd=""
    dbname="pubmed_obesity_2010_2012"
    #***************************************************************************
    db = mysql_connect(host, mysql_usr, mysql_pswd, dbname)
else
    error("Unsupported database backend")
end


@time begin
    map_mesh_to_umls_async!(db, credentials; append_results=append)
end

println("-------------------------------------------------------------")
println("Done Mapping Mesh to UMLS")
println("-------------------------------------------------------------")
