# Example Julia script calling the typical workflow to  search PubMed and store
# the results in a database
# Date: September 6, 2016
# Authors: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5

using BioMedQuery.Processes
using BioMedQuery.Entrez

#************************ LOCALS TO CONFIGURE!!!! **************************
email= ENV["NCBI_EMAIL"] #This is an enviroment variable that you need to setup
search_term="(obesity[MeSH Major Topic]) AND (\"2010\"[Date - Publication] : \"2012\"[Date - Publication])"
max_articles = 20
overwrite_db=true
verbose = false

#Database backend
using_sqlite=false
using_mysql=true

#***************************************************************************


if using_mysql
    #************************ LOCALS TO CONFIGURE!!!! **************************
    host="localhost" #If want to hide - use enviroment variables instead
    mysql_usr="root"
    mysql_pswd=""
    dbname="pubmed_obesity_2010_2012"
    #***************************************************************************
    db_config = Dict(:host=>host,
                     :dbname=>dbname,
                     :username=>mysql_usr,
                     :pswd=>mysql_pswd,
                     :overwrite=>overwrite_db)
    save_func = save_efetch_mysql
elseif using_sqlite
    #************************ LOCALS TO CONFIGURE!!!! **************************
    db_path="./pubmed_obesity_2010_2012.db"
    #***************************************************************************

    db_config = Dict(:db_path=>db_path,
                        :overwrite=>overwrite_db)
    save_func = save_efetch_sqlite
else
   error("Unsupported database backend")
end


@time begin
    db = pubmed_search_and_save(email, search_term, max_articles,
    save_func, db_config, verbose)
end
