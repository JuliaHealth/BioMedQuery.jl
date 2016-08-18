module BioMedQuery

# --------Database Utilities---------
module DBUtils
export init_mysql_database,
       assemble_vals,
       insert_row_mysql!,
       insert_row_sqlite!,
       select_mysql,
       select_sqlite

include("DBUtils/DBUtils.jl")
end

#-----------Entrez----------------
module Entrez
export esearch,
       efetch,
       eparse,
       save_efetch_mysql
include("Entrez/Entrez.jl")
end
#
#
# #----------UMLS--------------------
# module UMLS
# export Credentials,
#        search_umls,
#        best_match_cui,
#        get_semantic_type
# include("UMLS/UMLS.jl")
# end
#
# #--------Clinical Trials------------
# module CT
# export search_ct
# include("CT/CT.jl")
# end

#-----------------------------------
end #BioMedQuery
