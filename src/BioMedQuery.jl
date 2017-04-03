module BioMedQuery

# --------Database Utilities---------
module DBUtils
export init_mysql_database,
       assemble_vals,
       assemble_cols_and_vals_select,
       assemble_cols_and_vals,
       assemble_cols_and_vals_string,
       insert_row!,
       db_select,
       db_query,
       db_clean_string,
       create_server

include("DBUtils/DBUtils.jl")
end

#-----------Entrez----------------
module Entrez
export esearch,
       efetch,
       eparse,
       eparse_from_file,
       save_efetch_mysql,
       save_pmid_mysql,
       save_efetch_sqlite,
       citations_endnote,
       citations_bibtex,
       save_article_citations

#types
export PubMedArticle,
       MeshHeading,
       MeshHeadingList


include("Entrez/Entrez.jl")
include("Entrez/pubmed_article.jl")
include("Entrez/entrez_save.jl")
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

# --------MTI------------
module MTI
export install_web_api,
       generic_batch,
       abstracts_to_request_file,
       parse_and_save_default_MTI,
       parse_and_save_MoD
include("MTI/MTI.jl")
end
# -----------------------------------


#--------Processes------------
module Processes
export pubmed_search_and_save,
       pubmed_search_and_save_mysql!,
       pubmed_pmid_search,
       pubmed_pmid_search_and_save,
       map_mesh_to_umls_async!,
       map_mesh_to_umls!,
       umls_semantic_occurrences,
       filter_mesh_by_concept,
       export_citation,
       mti_search_and_save
include("Processes/pubmed_search_and_save.jl")
include("Processes/pubmed_mesh_to_umls_map.jl")
include("Processes/pubmed_occurrance_filtering.jl")
include("Processes/pubmed_export_citations.jl")
include("Processes/mti_search_and_save.jl")
end

#-----------------------------------

end #BioMedQuery
