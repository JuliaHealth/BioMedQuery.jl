
using BioMedQuery.Processes
using BioMedQuery.PubMed

email= "" #Only needed if you want to contact NCBI with inqueries
search_term="(obesity[MeSH Major Topic]) AND (\"2010\"[Date - Publication] : \"2012\"[Date - Publication])"
max_articles = 20
results_dir = "./results";

mysql_config = Dict(:host=>"localhost",
                    :dbname=>"pubmed_obesity_2010_2012",
                    :username=>"root",
                    :pswd=>"",
                    :overwrite=>true)
verbose = false
db = pubmed_search_and_save(email, search_term, max_articles,
    save_efetch_mysql, mysql_config, verbose)

display(all_pmids(db))

tables = ["author", "author2article", "mesh_descriptor",
"mesh_qualifier", "mesh_heading"]

for t in tables
    query_str = "SELECT * FROM "*t*" LIMIT 5;"
    q = BioMedQuery.DBUtils.db_query(db, query_str)
    println(q)
end
