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

#-----------PubMed----------------
module PubMed

#types
export  PubMedArticle,
MeshHeading,
MeshHeadingList
include("PubMed/pubmed_article.jl")

# sql utilities
export  init_pubmed_db_mysql,
        init_pubmed_db_mysql!,
        init_pubmed_db_sqlite,
        init_pmid_db_mysql,
        get_value,
        all_pmids,
        get_article_mesh,
        get_article_mesh_by_concept,        
        db_insert!,
        abstracts_by_year
include("PubMed/pubmed_sql_utils.jl")
        
# eutils -> sql
export  save_efetch_mysql,
        save_pmid_mysql,
        save_efetch_sqlite
include("PubMed/eutils_sql_save.jl")
        
# citation formats
export  citations_endnote,
citations_bibtex,
save_article_citations
include("PubMed/citation_manager.jl")

end


#--------Clinical Trials------------
module CT
export search_ct
include("CT/CT.jl")
end
#-----------------------------------


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
       export_citation
include("Processes/pubmed_search_and_save.jl")
include("Processes/pubmed_mesh_to_umls_map.jl")
include("Processes/pubmed_occurrance_filtering.jl")
include("Processes/pubmed_export_citations.jl")

end

#-----------------------------------

end #BioMedQuery
