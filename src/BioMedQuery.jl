module BioMedQuery

# --------Database Utilities---------
module DBUtils
export init_mysql_database,
       assemble_vals,
       insert_row!,
       db_select,
       db_query,
       db_clean_string

include("DBUtils/DBUtils.jl")
end

#-----------Entrez----------------
module Entrez
export esearch,
       efetch,
       eparse,
       save_efetch_mysql,
       save_efetch_sqlite,
       PubMedArticle,
       citations_endnote,
       save_article_citations

include("Entrez/Entrez.jl")
include("Entrez/entrez_save.jl")
include("Entrez/pubmed_article.jl")
include("Entrez/citation_manager.jl")
end


#----------UMLS--------------------
module UMLS
export Credentials,
       get_tgt,
       search_umls,
       best_match_cui,
       get_semantic_type,
       populate_net_mysql,
       build_tree_dict
include("UMLS/UMLS.jl")
include("UMLS/semantic_network.jl")
end

#--------Clinical Trials------------
module CT
export search_ct
include("CT/CT.jl")
end

#-----------------------------------
end #BioMedQuery
