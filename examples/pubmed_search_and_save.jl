
using BioMedQuery.Processes
using BioMedQuery.PubMed

email= "" #Only needed if you want to contact NCBI with inqueries
search_term="(obesity[MeSH Major Topic]) AND (\"2010\"[Date - Publication] : \"2012\"[Date - Publication])"
max_articles = 5
results_dir = "./results"
verbose = false;

mysql_config = Dict(:host=>"localhost",
                    :dbname=>"pubmed_obesity_2010_2012",
                    :username=>"root",
                    :pswd=>"",
                    :overwrite=>true)
db_mysql = pubmed_search_and_save(email, search_term, max_articles,
    save_efetch_mysql, mysql_config, verbose)

display(all_pmids(db_mysql))

tables = ["author", "author2article", "mesh_descriptor",
"mesh_qualifier", "mesh_heading"]

for t in tables
    query_str = "SELECT * FROM "*t*" LIMIT 5;"
    q = BioMedQuery.DBUtils.db_query(db_mysql, query_str)
    println(q)
end

sqlite_config = Dict(:db_path=>"$(results_dir)/pubmed_obesity_2010_2012.db",
              :overwrite=>true)
db_sqlite = pubmed_search_and_save(email, search_term, max_articles,
    save_efetch_sqlite, sqlite_config, verbose)

display(all_pmids(db_sqlite))

tables = ["author", "author2article", "mesh_descriptor",
"mesh_qualifier", "mesh_heading"]

for t in tables
    query_str = "SELECT * FROM "*t*" LIMIT 5;"
    q = BioMedQuery.DBUtils.db_query(db_sqlite, query_str)
    println(q)
end

enw_file = "$(results_dir)/pubmed_obesity_2010_2012.enw"
endnote_config = Dict(:type => "endnote", 
                      :output_file => enw_file, 
                      :overwrite=> true)
pubmed_search_and_save(email, search_term, max_articles,
    save_article_citations, endnote_config, verbose);

println(readstring(enw_file))
