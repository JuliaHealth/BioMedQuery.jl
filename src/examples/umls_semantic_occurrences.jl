# Example Julia script to obtain the occurrance matrix associated with a
# UMLS concept in a previously obtained pubmed/medline search
# Date: September 6, 2016
# Authors: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5

using BioMedQuery.Processes
using BioMedQuery.Entrez
using MySQL
using SQLite
using JLD


results_dir = "./results"
umls_concept = "Disease or Syndrome"
#Database backend
using_sqlite=false
using_mysql=true

 if !isdir(results_dir)
     mkdir(results_dir)
 end

 occur_path = results_dir*"/occur_sp.jdl"
 labels2ind_path = results_dir*"/labels2ind.jdl"


 db = nothing
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
     labels2ind, occur = umls_semantic_occurrences(db, umls_concept)
 end

 println("-------------------------------------------------------------")
 println("Output Descritor to Index Dictionary")
 println(labels2ind)
 println("-------------------------------------------------------------")

 println("-------------------------------------------------------------")
 println("Output Data Matrix")
 println(occur)
 println("-------------------------------------------------------------")

 # save(occur_path, "occur", occur)
 jldopen(occur_path, "w") do file
     write(file, "occur", occur)
 end
 jldopen(labels2ind_path, "w") do file
     write(file, "labels2ind", labels2ind)
 end

 # file  = jldopen(occur_path, "r")
 # obj2 = read(file, "occur")
 # display(obj2)


 println("-------------------------------------------------------------")
 println("Done computing and saving occurance info to disk")
 println("-------------------------------------------------------------")
