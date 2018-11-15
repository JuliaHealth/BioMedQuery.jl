var documenterSearchIndex = {"docs": [

{
    "location": "#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "#BioMedQuery-Julia-Package-1",
    "page": "Home",
    "title": "BioMedQuery Julia Package",
    "category": "section",
    "text": "Julia utilities to process and save results from BioMedical databases/APIs.BioServices.jl (part of BioJulia) provides the basic interface to some of the APIs, while BioMedQuery helps parse and save results into MySQL, SQLite, DataFrames, CSV etc.Supported APIs include:National Library of Medicine (NLM)Entrez Programming Utilities (E-Utilities)\nUnified Medical Language System (UMLS)\nClinical Trials (clinicaltrials.gov)\nMEDLINE (PubMed MEDLINE)"
},

{
    "location": "#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "BioMedQuery is a registered package. To install the latest stable version, use the package manager.using Pkg\nPkg.add(\"BioMedQuery\")To use the latest development version:using Pkg\nPkg.add(\"BioMedQuery#master\")To checkout the latest development version:using Pkg\nPkg.dev(\"BioMedQuery\")"
},

{
    "location": "#Related-Packages-1",
    "page": "Home",
    "title": "Related Packages",
    "category": "section",
    "text": "Function Description\nBioServices.jl Interface to EUtils and UMLS APIs\nPubMedMiner.jl Examples of comorbidity studies using PubMed articles"
},

{
    "location": "examples/#",
    "page": "Overview",
    "title": "Overview",
    "category": "page",
    "text": ""
},

{
    "location": "examples/#Examples-1",
    "page": "Overview",
    "title": "Examples",
    "category": "section",
    "text": "The repository contains an examples folder with scripts demonstrating how to use BioMedQuery\'s pre-assembled high-level processes and workflows.The following examples are available:Example Description\nSearch and Save PubMed Queries Search PubMed, parse results, store them using a MySQL or SQLite backend, or export to a  citation library\nUMLS-MeSH Mapping and Filtering For all MeSH descriptors in a given data disease_occurances, build a table to match them to their UMLS concept, and filter them by UMLS concepts\nExporting Citations Export the citation for one or more PMIDs to an Endnote/Bibtex file\nLoading MEDLINE Load the MEDLINE baseline files"
},

{
    "location": "examples/1_pubmed_search_and_save/#",
    "page": "Pubmed Search and Save",
    "title": "Pubmed Search and Save",
    "category": "page",
    "text": "EditURL = \"https://github.com/bcbi/BioMedQuery.jl/blob/master/examples/literate_src/1_pubmed_search_and_save.jl\""
},

{
    "location": "examples/1_pubmed_search_and_save/#Search-PubMed-and-Save-Results-1",
    "page": "Pubmed Search and Save",
    "title": "Search PubMed and Save Results",
    "category": "section",
    "text": "(Image: nbviewer)This example demonstrates the typical workflow to query pubmed and store the results. The following backends are supported for storing the results:MySQL\nSQLite\nCitation (endnote/bibtex)\nDataFrames"
},

{
    "location": "examples/1_pubmed_search_and_save/#Set-Up-1",
    "page": "Pubmed Search and Save",
    "title": "Set Up",
    "category": "section",
    "text": "using BioMedQuery.DBUtils\nusing BioMedQuery.PubMed\nusing BioMedQuery.Processes\nusing DataFrames\nusing MySQL\nusing SQLiteVariables used to search PubMedemail = \"\"; # Only needed if you want to contact NCBI with inqueries\nsearch_term = \"\"\"(obesity[MeSH Major Topic]) AND (\"2010\"[Date - Publication] : \"2012\"[Date - Publication])\"\"\";\nmax_articles = 5;\nresults_dir = \".\";\nverbose = true;"
},

{
    "location": "examples/1_pubmed_search_and_save/#MySQL-backend-1",
    "page": "Pubmed Search and Save",
    "title": "MySQL backend",
    "category": "section",
    "text": "Initialize database, if it exists it connects to it, otherwise it creates itconst mysql_conn = DBUtils.init_mysql_database(\"127.0.0.1\", \"root\", \"\", \"pubmed_obesity_2010_2012\");Creates (and deletes if they already exist) all tables needed to save a pubmed searchPubMed.create_tables!(mysql_conn);Search pubmed and save results to databaseProcesses.pubmed_search_and_save!(email, search_term, max_articles, mysql_conn, verbose)"
},

{
    "location": "examples/1_pubmed_search_and_save/#Access-all-PMIDs-1",
    "page": "Pubmed Search and Save",
    "title": "Access all PMIDs",
    "category": "section",
    "text": "all_pmids(mysql_conn)"
},

{
    "location": "examples/1_pubmed_search_and_save/#Explore-tables-1",
    "page": "Pubmed Search and Save",
    "title": "Explore tables",
    "category": "section",
    "text": "You may use the MySQL command directly. If you want the return type to be a DataFrame, you need to explicitly request so.tables = [\"author_ref\", \"mesh_desc\", \"mesh_qual\", \"mesh_heading\"]\nfor t in tables\n    query_str = \"SELECT * FROM $t LIMIT 5;\"\n    q = MySQL.Query(mysql_conn, query_str) |> DataFrame\n    println(q)\nendMySQL.disconnect(mysql_conn);"
},

{
    "location": "examples/1_pubmed_search_and_save/#SQLite-backend-1",
    "page": "Pubmed Search and Save",
    "title": "SQLite backend",
    "category": "section",
    "text": "const db_path = \"$(results_dir)/pubmed_obesity_2010_2012.db\";Overwrite the database if it already existsif isfile(db_path)\n    rm(db_path)\nendConnect to the databaseconst conn_sqlite = SQLite.DB(db_path);Creates (and deletes if they already exist) all tables needed to save a pubmed searchPubMed.create_tables!(conn_sqlite);Search PubMed and save the resultsProcesses.pubmed_search_and_save!(email, search_term, max_articles, conn_sqlite, verbose)"
},

{
    "location": "examples/1_pubmed_search_and_save/#Access-all-PMIDs-2",
    "page": "Pubmed Search and Save",
    "title": "Access all PMIDs",
    "category": "section",
    "text": "all_pmids(conn_sqlite)"
},

{
    "location": "examples/1_pubmed_search_and_save/#Explore-the-tables-1",
    "page": "Pubmed Search and Save",
    "title": "Explore the tables",
    "category": "section",
    "text": "You may use the SQLite commands directly. The return type is a DataFrame.tables = [\"author_ref\", \"mesh_desc\", \"mesh_qual\", \"mesh_heading\"]\nfor t in tables\n    query_str = \"SELECT * FROM $t LIMIT 5;\"\n    q = SQLite.query(conn_sqlite, query_str)\n    println(q)\nend"
},

{
    "location": "examples/1_pubmed_search_and_save/#Citations-1",
    "page": "Pubmed Search and Save",
    "title": "Citations",
    "category": "section",
    "text": "Citation type can be \"endnote\" or \"bibtex\"enw_file = \"$(results_dir)/pubmed_obesity_2010_2012.enw\"\nendnote_citation = PubMed.CitationOutput(\"endnote\", enw_file, true)\nProcesses.pubmed_search_and_save!(email, search_term, max_articles, endnote_citation, verbose);\n\nprintln(read(enw_file, String))"
},

{
    "location": "examples/1_pubmed_search_and_save/#DataFrames-1",
    "page": "Pubmed Search and Save",
    "title": "DataFrames",
    "category": "section",
    "text": "Returns a dictionary of dataframes which match the content and structure of the database tables.dfs = Processes.pubmed_search_and_parse(email, search_term, max_articles, verbose)This page was generated using Literate.jl."
},

{
    "location": "examples/2_umls_map_and_filter/#",
    "page": "MeSH/UMLS Map and Filtering",
    "title": "MeSH/UMLS Map and Filtering",
    "category": "page",
    "text": "EditURL = \"https://github.com/bcbi/BioMedQuery.jl/blob/master/examples/literate_src/2_umls_map_and_filter.jl\""
},

{
    "location": "examples/2_umls_map_and_filter/#Using-UMLS-Concepts-with-MeSH-1",
    "page": "MeSH/UMLS Map and Filtering",
    "title": "Using UMLS Concepts with MeSH",
    "category": "section",
    "text": "(Image: nbviewer)The Medical Subject Headings (MeSH) terms returned from a PubMed search can be further analyzed by mapping them to Unified Medical Language System (UMLS) concepts, as well as filtering the MeSH Terms by concepts.For both mapping MeSH to UMLS Concepts and filtering MeSH by concept, the following backends are supported:MySQL\nSQLite\nDataFrames"
},

{
    "location": "examples/2_umls_map_and_filter/#Set-Up-1",
    "page": "MeSH/UMLS Map and Filtering",
    "title": "Set Up",
    "category": "section",
    "text": "using SQLite\nusing MySQL\nusing BioMedQuery.DBUtils\nusing BioMedQuery.Processes\nusing BioServices.UMLS\nusing BioMedQuery.PubMed\nusing DataFramesCredentials are environment variables (e.g set in your .juliarc.jl)umls_user = ENV[\"UMLS_USER\"];\numls_pswd = ENV[\"UMLS_PSSWD\"];\nemail = \"\"; # Only needed if you want to contact NCBI with inqueries\nsearch_term = \"\"\"(obesity[MeSH Major Topic]) AND (\"2010\"[Date - Publication] : \"2012\"[Date - Publication])\"\"\";\numls_concept = \"Disease or Syndrome\";\nmax_articles = 5;\nresults_dir = \".\";\nverbose = true;\n\nresults_dir = \".\";"
},

{
    "location": "examples/2_umls_map_and_filter/#MySQL-1",
    "page": "MeSH/UMLS Map and Filtering",
    "title": "MySQL",
    "category": "section",
    "text": ""
},

{
    "location": "examples/2_umls_map_and_filter/#Map-Medical-Subject-Headings-(MeSH)-to-UMLS-1",
    "page": "MeSH/UMLS Map and Filtering",
    "title": "Map Medical Subject Headings (MeSH) to UMLS",
    "category": "section",
    "text": "This example demonstrates the typical workflow to populate a MESH2UMLS database table relating all concepts associated with all MeSH terms in the input database.Note: this example reuses the MySQL DB from the PubMed Search and Save example.Create MySQL DB connectionhost = \"127.0.0.1\";\nmysql_usr = \"root\";\nmysql_pswd = \"\";\ndbname = \"pubmed_obesity_2010_2012\";\n\nconst mysql_conn = DBUtils.init_mysql_database(host, mysql_usr, mysql_pswd, dbname) # hide\nPubMed.create_tables!(mysql_conn) # hide\nProcesses.pubmed_search_and_save!(email, search_term, max_articles, mysql_conn, verbose) # hide\nMySQL.disconnect(mysql_conn) #hide\n\ndb_mysql = MySQL.connect(host, mysql_usr, mysql_pswd, db = dbname);Map MeSH to UMLS@time map_mesh_to_umls_async!(db_mysql, umls_user, umls_pswd; append_results=false, timeout=3);"
},

{
    "location": "examples/2_umls_map_and_filter/#Explore-the-output-table-1",
    "page": "MeSH/UMLS Map and Filtering",
    "title": "Explore the output table",
    "category": "section",
    "text": "db_query(db_mysql, \"SELECT * FROM mesh2umls\")"
},

{
    "location": "examples/2_umls_map_and_filter/#Filtering-MeSH-terms-by-UMLS-concept-1",
    "page": "MeSH/UMLS Map and Filtering",
    "title": "Filtering MeSH terms by UMLS concept",
    "category": "section",
    "text": "Getting the descriptor to index dictionary and the occurence matrix@time labels2ind, occur = umls_semantic_occurrences(db_mysql, umls_concept);Descriptor to Index Dictionarylabels2indOutput Data MatrixMatrix(occur)"
},

{
    "location": "examples/2_umls_map_and_filter/#SQLite-1",
    "page": "MeSH/UMLS Map and Filtering",
    "title": "SQLite",
    "category": "section",
    "text": "This example demonstrates the typical workflow to populate a MESH2UMLS database table relating all concepts associated with all MeSH terms in the input database.Note: this example reuses the SQLite DB from the PubMed Search and Save example.Create SQLite DB connectiondb_path = \"$(results_dir)/pubmed_obesity_2010_2012.db\";\ndb_sqlite = SQLite.DB(db_path);\n\nif isfile(db_path) # hide\n    rm(db_path) # hide\nend # hide\ndb_sqlite = SQLite.DB(db_path); # hide\nPubMed.create_tables!(db_sqlite); # hide\nProcesses.pubmed_search_and_save!(email, search_term, max_articles, db_sqlite, false) # hide"
},

{
    "location": "examples/2_umls_map_and_filter/#Map-MeSH-to-UMLS-1",
    "page": "MeSH/UMLS Map and Filtering",
    "title": "Map MeSH to UMLS",
    "category": "section",
    "text": "@time map_mesh_to_umls_async!(db_sqlite, umls_user, umls_pswd; append_results=false, timeout=3);Explore the output tabledb_query(db_sqlite, \"SELECT * FROM mesh2umls;\")"
},

{
    "location": "examples/2_umls_map_and_filter/#Filtering-MeSH-terms-by-UMLS-concept-2",
    "page": "MeSH/UMLS Map and Filtering",
    "title": "Filtering MeSH terms by UMLS concept",
    "category": "section",
    "text": "Getting the descriptor to index dictionary and occurence matrix@time labels2ind, occur = umls_semantic_occurrences(db_sqlite, umls_concept);Descriptor to Index Dictionarylabels2indOutput Data MatrixMatrix(occur)"
},

{
    "location": "examples/2_umls_map_and_filter/#DataFrames-1",
    "page": "MeSH/UMLS Map and Filtering",
    "title": "DataFrames",
    "category": "section",
    "text": "This example demonstrates the typical workflow to create a MeSH to UMLS map as a DataFrame relating all concepts associated with all MeSH terms in the input dataframe.Get the articles (same as example in PubMed Search and Parse)dfs = Processes.pubmed_search_and_parse(email, search_term, max_articles, verbose)Map MeSH to UMLS and explore the output table@time res = map_mesh_to_umls_async(dfs[\"mesh_desc\"], umls_user, umls_pswd)Getting the descriptor to index dictionary and occurence matrix@time labels2ind, occur = umls_semantic_occurrences(dfs, res, umls_concept);Descriptor to Index Dictionarylabels2indOutput Data MatrixMatrix(occur)This page was generated using Literate.jl."
},

{
    "location": "examples/4_pubmed_export_citations/#",
    "page": "Export to Citations",
    "title": "Export to Citations",
    "category": "page",
    "text": "EditURL = \"https://github.com/bcbi/BioMedQuery.jl/blob/master/examples/literate_src/4_pubmed_export_citations.jl\""
},

{
    "location": "examples/4_pubmed_export_citations/#Export-PubMed-Citations-1",
    "page": "Export to Citations",
    "title": "Export PubMed Citations",
    "category": "section",
    "text": "(Image: nbviewer)BioMedQuery has functions to search PubMed for PMIDs and save the xml data as either a BibTex or EndNote citation.Here we export EndNote/BibTex citations from a PMID or a list of PMIDs. If you need to search Entrez/PubMed and save the results as citations, refer to Examples / PubMed Search and Save."
},

{
    "location": "examples/4_pubmed_export_citations/#Set-Up-1",
    "page": "Export to Citations",
    "title": "Set Up",
    "category": "section",
    "text": "using BioMedQuery.ProcessesThe functions require a directory to save the citation files toresults_dir = \".\";\n\nif !isdir(results_dir)\n     mkdir(results_dir)\nendFor this example, the below PMIDs are searched and saved as citationspmid = 11748933;\npmid_list = [24008025, 24170597];"
},

{
    "location": "examples/4_pubmed_export_citations/#Export-as-an-EndNote-library-file-1",
    "page": "Export to Citations",
    "title": "Export as an EndNote library file",
    "category": "section",
    "text": "Saving one PMID\'s citaiton as an EndNote fileenw_file = results_dir * \"/11748933.enw\";\nexport_citation(pmid, \"endnote\", enw_file);Saving two PMIDs\' citations as an EndNote fileenw_file = results_dir * \"/pmid_list.enw\";\nexport_citation(pmid_list, \"endnote\", enw_file);"
},

{
    "location": "examples/4_pubmed_export_citations/#Explore-one-of-the-output-files-1",
    "page": "Export to Citations",
    "title": "Explore one of the output files",
    "category": "section",
    "text": "println(read(enw_file, String))"
},

{
    "location": "examples/4_pubmed_export_citations/#Export-as-a-Bibtex-file-1",
    "page": "Export to Citations",
    "title": "Export as a Bibtex file",
    "category": "section",
    "text": "Saving one PMID\'s citation as a BibTex filebib_file = results_dir * \"/11748933.bib\";\nexport_citation(pmid, \"bibtex\", bib_file);Saving two PMIDs\' citations as a BibTex filebib_file = results_dir * \"/pmid_list.bib\";\nexport_citation(pmid_list, \"bibtex\", bib_file);"
},

{
    "location": "examples/4_pubmed_export_citations/#Explore-one-of-the-output-files-2",
    "page": "Export to Citations",
    "title": "Explore one of the output files",
    "category": "section",
    "text": "println(read(bib_file, String))This page was generated using Literate.jl."
},

{
    "location": "examples/5_load_medline/#",
    "page": "Load MEDLINE",
    "title": "Load MEDLINE",
    "category": "page",
    "text": "EditURL = \"https://github.com/bcbi/BioMedQuery.jl/blob/master/examples/literate_src/5_load_medline.jl\""
},

{
    "location": "examples/5_load_medline/#Load-MEDLINE-1",
    "page": "Load MEDLINE",
    "title": "Load MEDLINE",
    "category": "section",
    "text": "(Image: nbviewer)The MEDLINE loader process in BioMedQuery saves the MEDLINE baseline files to a MySQL database and saves the raw (xml.gz) and parsed (csv) files to a medline directory that will be created in the provided output_dir.WARNING: There are 900+ medline files each with approximately 30,000 articles. This process will take hours to run for the full baseline load.The baseline files can be found here."
},

{
    "location": "examples/5_load_medline/#Set-Up-1",
    "page": "Load MEDLINE",
    "title": "Set Up",
    "category": "section",
    "text": "The database and tables must already be created before loading the medline files. This process is set up for parallel processing.  To take advantage of this, workers can be added before loading the BioMedQuery package using the addprocs function.using BioMedQueryBioMedQuery has utility functions to create the database and tables. Note: creating the tables using this function will drop any tables that already exist in the target database.const conn = BioMedQuery.DBUtils.init_mysql_database(\"127.0.0.1\",\"root\",\"\",\"test_db\", true);\nBioMedQuery.PubMed.create_tables!(conn);"
},

{
    "location": "examples/5_load_medline/#Load-a-Test-File-1",
    "page": "Load MEDLINE",
    "title": "Load a Test File",
    "category": "section",
    "text": "As the full medline load is a large operation, it is recommended that a test run be completed first.@time BioMedQuery.Processes.load_medline!(conn, pwd(), test=true)Review the output of this run in MySQL to make sure that it ran as expected. Additionally, the sample raw and parsed file should be in the new medline directory in the current directory."
},

{
    "location": "examples/5_load_medline/#Performing-a-Full-Load-1",
    "page": "Load MEDLINE",
    "title": "Performing a Full Load",
    "category": "section",
    "text": "To run a full load, use the same code as above, but do not pass the test variable. It is also possible to break up the load by passing which files to start and stop at - simply pass start_file=n andend_file=p`.After loading, it is recommended you add indexes to the tables, the add_mysql_keys! function can be used to add a standard set of indexes.BioMedQuery.PubMed.add_mysql_keys!(conn)This page was generated using Literate.jl."
},

{
    "location": "processes/#",
    "page": "Processes/Workflows",
    "title": "Processes/Workflows",
    "category": "page",
    "text": "This module provides common processes/workflows when using the BioMedQuery utilities. For instance, searching PubMed, requires calling the NCBI e-utils in a particular order. After the search, the results are often saved to the database. This module contains pre-assembled functions performing all necessary steps. To see sample scripts that use this processes, refer to the following section##Importusing BioMedQuery.Processes"
},

{
    "location": "processes/#Index-1",
    "page": "Processes/Workflows",
    "title": "Index",
    "category": "section",
    "text": "Modules = [BioMedQuery.Processes]"
},

{
    "location": "processes/#BioMedQuery.Processes.export_citation",
    "page": "Processes/Workflows",
    "title": "BioMedQuery.Processes.export_citation",
    "category": "function",
    "text": "export_citation(pmid::Int64, citation_type, output_file,verbose)\n\nExport, to an output file, the citation for PubMed article identified by the given pmid\n\nArguments\n\ncitation_type::String: At the moment supported types include: \"endnote\", \"bibtex\"\n\n\n\n\n\n"
},

{
    "location": "processes/#BioMedQuery.Processes.export_citation",
    "page": "Processes/Workflows",
    "title": "BioMedQuery.Processes.export_citation",
    "category": "function",
    "text": "export_citation(pmids::Vector{Int64}, citation_type, output_file,verbose)\n\nExport, to an output file, the citation for collection of PubMed articles identified by the given pmids\n\nArguments\n\ncitation_type::String: At the moment supported types include: \"endnote\", \"bibtex\"\n\n\n\n\n\n"
},

{
    "location": "processes/#BioMedQuery.Processes.load_medline!-Tuple{MySQL.Connection,String}",
    "page": "Processes/Workflows",
    "title": "BioMedQuery.Processes.load_medline!",
    "category": "method",
    "text": "load_medline(db_con, output_dir; start_file=1, end_file=928, year=2018, test=false)\n\nGiven a MySQL connection and optionally the start and end files, fetches the medline files, parses the xml, and loads into a MySQL DB (assumes tables already exist). The raw (xml.gz) and parsed (csv) files will be stored in the output_dir.\n\nArguments\n\ndb_con : A MySQL Connection to a db (tables must already be created - see PubMed.create_tables!)\noutput_dir : root directory where the raw and parsed files should be stored\nstart_file : which medline file should the loading start at\nend_file : which medline file should the loading end at (default is last file in 2018 baseline)\nyear : which year medline is (current is 2018)\ntest : if true, a sample file will be downloaded, parsed, and loaded instead of the baseline files\n\n\n\n\n\n"
},

{
    "location": "processes/#BioMedQuery.Processes.map_mesh_to_umls_async!-Tuple{Any,Any,Any}",
    "page": "Processes/Workflows",
    "title": "BioMedQuery.Processes.map_mesh_to_umls_async!",
    "category": "method",
    "text": "map_mesh_to_umls_async!(db, c::Credentials; timeout, append_results, verbose)\n\nBuild (using async UMLS-API calls) and store in the given database a map from MESH descriptors to UMLS Semantic Concepts. For large queies this function will be faster than it\'s synchrounous counterpart\n\nArguments\n\ndb: Database. Must contain TABLE:mesh_descriptor. For each of the descriptors  in that table, search and insert the associated semantic concepts into a new (cleared) TABLE:mesh2umls\nuser : UMLS username\npsswd : UMLS Password\nappend_results::Bool : If false a NEW and EMPTY mesh2umls database table in creted\nbatch_size: Number of\n\n\n\n\n\n"
},

{
    "location": "processes/#BioMedQuery.Processes.map_mesh_to_umls_async-Tuple{DataFrames.DataFrame,Any,Any}",
    "page": "Processes/Workflows",
    "title": "BioMedQuery.Processes.map_mesh_to_umls_async",
    "category": "method",
    "text": "map_mesh_to_umls_async(mesh_df, user, psswd; timeout, append_results, verbose)\n\nBuild (using async UMLS-API calls) and return a map from MESH descriptors to UMLS Semantic Concepts. For large queies this function will be faster than it\'s synchrounous counterpart\n\nArguments\n\nmesh_df: DataFrame countaining MeshDescriptors. This is the dataframe with the key `meshdesc` that is returned from pubmedsearchand_parse.\nuser : UMLS username\npsswd : UMLS Password\n\n\n\n\n\n"
},

{
    "location": "processes/#BioMedQuery.Processes.pubmed_search_and_parse",
    "page": "Processes/Workflows",
    "title": "BioMedQuery.Processes.pubmed_search_and_parse",
    "category": "function",
    "text": "pubmed_search_and_parse(email, search_term::String, article_max, verbose=false)\n\nSearch pubmed and parse the results into a dictionary of DataFrames.  The dataframes have the same names and fields as the pubmed database schema. (e.g. df_dict[\"basic\"] returns a dataframe with the basic article info)\n\nArguments\n\nemail : valid email address (otherwise pubmed may block you)\nsearch_term : search string to submit to PubMed e.g (asthma[MeSH Terms]) AND (\"2001/01/29\"[Date - Publication] : \"2010\"[Date - Publication]) see http://www.ncbi.nlm.nih.gov/pubmed/advanced for help constructing the string\narticle_max : maximum number of articles to return\nverbose : if true, the NCBI xml response files are saved to current directory\n\n\n\n\n\n"
},

{
    "location": "processes/#BioMedQuery.Processes.pubmed_search_and_save!",
    "page": "Processes/Workflows",
    "title": "BioMedQuery.Processes.pubmed_search_and_save!",
    "category": "function",
    "text": "pubmed_search_and_save!(email, search_term::String, article_max,\nconn, verbose=false)\n\nSearch pubmed and save the results into a database connection. The database is expected to exist and have the appriate pubmed related tables. You can create such tables using PubMed.create_tables(conn)\n\nArguments\n\nemail : valid email address (otherwise pubmed may block you)\nsearch_term : search string to submit to PubMed e.g (asthma[MeSH Terms]) AND (\"2001/01/29\"[Date - Publication] : \"2010\"[Date - Publication]) see http://www.ncbi.nlm.nih.gov/pubmed/advanced for help constructing the string\narticle_max : maximum number of articles to return\nconn : database connection\nverbose : if true, the NCBI xml response files are saved to current directory\n\n\n\n\n\n"
},

{
    "location": "processes/#BioMedQuery.Processes.umls_semantic_occurrences-Tuple{Any,Vararg{Any,N} where N}",
    "page": "Processes/Workflows",
    "title": "BioMedQuery.Processes.umls_semantic_occurrences",
    "category": "method",
    "text": "umls_semantic_occurrences(db, umls_semantic_type)\n\nReturn a sparse matrix indicating the presence of MESH descriptors associated with a given umls semantic type in all articles of the input database\n\nOutput\n\ndes_ind_dict: Dictionary matching row number to descriptor names\ndisease_occurances : Sparse matrix. The columns correspond to a feature vector, where each row is a MESH descriptor. There are as many columns as articles. The occurance/abscense of a descriptor is labeled as 1/0\n\n\n\n\n\n"
},

{
    "location": "processes/#BioMedQuery.Processes.umls_semantic_occurrences-Tuple{Dict{String,DataFrames.DataFrame},DataFrames.DataFrame,Vararg{Any,N} where N}",
    "page": "Processes/Workflows",
    "title": "BioMedQuery.Processes.umls_semantic_occurrences",
    "category": "method",
    "text": "umls_semantic_occurrences(dfs, mesh2umls_df, umls_semantic_type)\n\nReturn a sparse matrix indicating the presence of MESH descriptors associated with a given umls semantic type in all articles of the input database\n\nOutput\n\ndes_ind_dict: Dictionary matching row number to descriptor names\ndisease_occurances : Sparse matrix. The columns correspond to a feature vector, where each row is a MESH descriptor. There are as many columns as articles. The occurance/abscense of a descriptor is labeled as 1/0\n\n\n\n\n\n"
},

{
    "location": "processes/#BioMedQuery.Processes.close_cons-Tuple{FTPClient.ConnContext}",
    "page": "Processes/Workflows",
    "title": "BioMedQuery.Processes.close_cons",
    "category": "method",
    "text": "close_cons(ftp_con)\n\ncloses connection and cleans up\n\n\n\n\n\n"
},

{
    "location": "processes/#BioMedQuery.Processes.get_file_name",
    "page": "Processes/Workflows",
    "title": "BioMedQuery.Processes.get_file_name",
    "category": "function",
    "text": "get_file_name(fnum::Int, year::Int = 2018, test = false)\n\nReturns the medline file name given the file number and year.\n\n\n\n\n\n"
},

{
    "location": "processes/#BioMedQuery.Processes.get_ftp_con",
    "page": "Processes/Workflows",
    "title": "BioMedQuery.Processes.get_ftp_con",
    "category": "function",
    "text": "get_ftp_con(test = false)\n\nGet an FTP connection\n\n\n\n\n\n"
},

{
    "location": "processes/#BioMedQuery.Processes.get_ml_file",
    "page": "Processes/Workflows",
    "title": "BioMedQuery.Processes.get_ml_file",
    "category": "function",
    "text": "get_ml_file(fname::String, conn::ConnContext, output_dir)\n\nRetrieves the file with fname and puts in medline/raw_files.  Returns the HTTP response.\n\n\n\n\n\n"
},

{
    "location": "processes/#BioMedQuery.Processes.init_medline",
    "page": "Processes/Workflows",
    "title": "BioMedQuery.Processes.init_medline",
    "category": "function",
    "text": "init_medline(output_dir, test=false)\n\nSets up environment (folders), and connects to medline FTP Server and returns the connection.\n\n\n\n\n\n"
},

{
    "location": "processes/#BioMedQuery.Processes.parse_ml_file-Tuple{String,String}",
    "page": "Processes/Workflows",
    "title": "BioMedQuery.Processes.parse_ml_file",
    "category": "method",
    "text": "parse_ml_file(fname::String, output_dir::String)\n\nParses the medline xml file into a dictionary of dataframes. Saves the resulting CSV files to medline/parsed_files.\n\n\n\n\n\n"
},

{
    "location": "processes/#Functions-1",
    "page": "Processes/Workflows",
    "title": "Functions",
    "category": "section",
    "text": "Modules = [BioMedQuery.Processes]\nOrder   = [:function, :type]"
},

{
    "location": "pubmed/#",
    "page": "PubMed",
    "title": "PubMed",
    "category": "page",
    "text": "Utility functions to parse and store PubMed searches via BioServices.EUtils"
},

{
    "location": "pubmed/#Import-Module-1",
    "page": "PubMed",
    "title": "Import Module",
    "category": "section",
    "text": "using BioMedQuery.PubMedThis module provides utility functions to parse, store and export queries to PubMed via the NCBI EUtils and its julia interface BioServices.EUtils. For many purposes you may interact with the higher level pipelines in [BioMedQuery.Processes]. Here, some of the lower level functions are discussed in case you need to assemble different pipelines."
},

{
    "location": "pubmed/#Basics-of-searching-PubMed-1",
    "page": "PubMed",
    "title": "Basics of searching PubMed",
    "category": "section",
    "text": "We are often interested in searching PubMed for all articles related to a search term, and possibly restricted by other search criteria. To do so we use BioServices.EUtils. A basic example of how we may use the functions esearch and efetch to accomplish such task is illustrated below.using BioServices.EUtils\nusing XMLDict\nusing LightXML\n\nsearch_term = \"obstructive sleep apnea[MeSH Major Topic]\"\n\n#esearch\nesearch_response = esearch(db=\"pubmed\", term = search_term,\nretstart = 0, retmax = 20, tool =\"BioJulia\")\n\n#convert xml to dictionary\nesearch_dict = parse_xml(String(esearch_response.body))\n\n#convert id\'s to a array of numbers\nids = [parse(Int64, id_node) for id_node in esearch_dict[\"IdList\"][\"Id\"]]\n\n#efetch\nefetch_response = efetch(db = \"pubmed\", tool = \"BioJulia\", retmode = \"xml\", rettype = \"null\", id = ids)\n\n#convert xml to xml node tree\nefetch_doc = root(parse_string(String(efetch_response.body)))"
},

{
    "location": "pubmed/#Handling-XML-responses-1",
    "page": "PubMed",
    "title": "Handling XML responses",
    "category": "section",
    "text": "Many APIs return responses in XML form.To parse an XML to a Julia dictionary we can use the XMLDict packageusing XMLDict\ndict = parse_xml(String(response.body))  You can save directly the XML String to filexdoc = parse_string(esearch)\nsave_file(xdoc, \"./file.xml\")"
},

{
    "location": "pubmed/#Save-eseach/efetch-responses-1",
    "page": "PubMed",
    "title": "Save eseach/efetch responses",
    "category": "section",
    "text": ""
},

{
    "location": "pubmed/#Save-PMIDs-to-MySQL-1",
    "page": "PubMed",
    "title": "Save PMIDs to MySQL",
    "category": "section",
    "text": "If we are only interseted in saving a list of PMIDs associated with a query, we can do so as followsdbname = \"entrez_test\"\nhost = \"127.0.0.1\";\nuser = \"root\"\npwd = \"\"\n\n#Collect PMIDs from esearch result\nids = Array{Int64,1}()\nfor id_node in esearch_dict[\"IdList\"][\"Id\"]\n    push!(ids, parse(Int64, id_node))\nend\n\n# Initialize or connect to database\nconst conn = DBUtils.init_mysql_database(host, user, pwd, dbname)\n\n# Create `article` table to store pmids\nPubMed.create_pmid_table!(conn)\n\n#Save pmids\nPubMed.save_pmids!(conn, ids)\n\n#query the article table to explore list of pmids\nall_pmids = BioMedQuery.PubMed.all_pmids(conn)"
},

{
    "location": "pubmed/#Export-efetch-response-as-EndNote-citation-file-1",
    "page": "PubMed",
    "title": "Export efetch response as EndNote citation file",
    "category": "section",
    "text": "We can export the information returned by efetch as and EndNote/BibTex library filecitation = PubMed.CitationOutput(\"endnote\", \"./citations_temp.endnote\", true)\nnsucceses = PubMed.save_efetch!(citation, efetch_doc, verbose)"
},

{
    "location": "pubmed/#Save-efetch-response-to-MySQL-database-1",
    "page": "PubMed",
    "title": "Save efetch response to MySQL database",
    "category": "section",
    "text": "Save the information returned by efetch to a MySQL databasedbname = \"efetch_test\"\nhost = \"127.0.0.1\";\nuser = \"root\"\npwd = \"\"\n\n# Save results of efetch to database and cleanup intermediate CSV files\nconst conn = DBUtils.init_mysql_database(host, user, pwd, dbname)\nPubMed.create_tables!(conn)\nPubMed.save_efetch!(conn, efetch_doc, false, true) # verbose = false, drop_csv = true"
},

{
    "location": "pubmed/#Save-efetch-response-to-SQLite-database-1",
    "page": "PubMed",
    "title": "Save efetch response to SQLite database",
    "category": "section",
    "text": "Save the information returned by efetch to a MySQL databasedb_path = \"./test_db.db\"\n\nconst conn = SQLite.DB(db_path)\nPubMed.create_tables!(conn)\nPubMed.save_efetch!(conn, efetch_doc)"
},

{
    "location": "pubmed/#Return-efetch-response-as-a-dictionary-of-DataFrames-1",
    "page": "PubMed",
    "title": "Return efetch response as a dictionary of DataFrames",
    "category": "section",
    "text": "The information returned by efetch can also be returned as dataframes. The dataframes match the format of the tables that are created for the sql saving functions (schema image below). These dataframes can also easily be saved to csv files.    dfs = PubMed.parse(efetch_doc)\n\n    PubMed.dfs_to_csv(dfs, \"my/path\", \"my_file_prefix_\")"
},

{
    "location": "pubmed/#Exploring-output-databases-1",
    "page": "PubMed",
    "title": "Exploring output databases",
    "category": "section",
    "text": "The following schema has been used to store the results. If you are interested in having this module store additional fields, feel free to open an issue		(Image: alt)We can also explore the tables using BioMedQuery.DBUtils, e,gtables = [\"author_ref\", \"mesh_desc\",\n\"mesh_qual\", \"mesh_heading\"]\n\nfor t in tables\n    query_str = \"SELECT * FROM \"*t*\" LIMIT 10;\"\n    q = DBUtils.db_query(db, query_str)\n    println(q)\nend"
},

{
    "location": "pubmed/#Index-1",
    "page": "PubMed",
    "title": "Index",
    "category": "section",
    "text": "Modules = [BioMedQuery.PubMed]"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.abstracts-Tuple{Any}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.abstracts",
    "category": "method",
    "text": "abstracts(db; local_medline=false)\n\nReturn all abstracts related to PMIDs in the database. If local_medline flag is set to true, it is assumed that db contains basic table with only PMIDs and all other info is available in a (same host) medline database\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.abstracts_by_year-Tuple{Any,Any}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.abstracts_by_year",
    "category": "method",
    "text": "abstracts_by_year(db, pub_year; local_medline=false)\n\nReturn all abstracts of article published in the given year. If local_medline flag is set to true, it is assumed that db contains article table with only PMIDs and all other info is available in a (same host) medline database\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.add_mysql_keys!-Tuple{MySQL.Connection}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.add_mysql_keys!",
    "category": "method",
    "text": "add_mysql_keys!(conn)\n\nAdds indices/keys to MySQL PubMed tables.\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.all_pmids-Tuple{Any}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.all_pmids",
    "category": "method",
    "text": "all_pmids(db)\n\nReturn all PMIDs stored in the basic table of the input database\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.citations_bibtex",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.citations_bibtex",
    "category": "function",
    "text": "citations_bibtex(article::Dict{String,DataFrame}, verbose=false)\n\nTransforms a Dictionary of pubmed dataframes into text corresponding to its bibtex citation\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.citations_endnote",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.citations_endnote",
    "category": "function",
    "text": "citations_endnote(article::Dict{String,DataFrame}, verbose=false)\n\nTransforms a Dictionary of pubmed dataframes into text corresponding to its endnote citation\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.create_pmid_table!-Tuple{Any}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.create_pmid_table!",
    "category": "method",
    "text": "create_pmid_table!(conn; tablename=\"article\")\n\nCreates a table, using either MySQL of SQLite, to store PMIDs from Entrez related searches. All tables are empty at this point\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.create_tables!-Tuple{Any}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.create_tables!",
    "category": "method",
    "text": "create_tables!(conn)\n\nCreate and initialize tables to save results from an Entrez/PubMed search or a medline file load. Caution, all related tables are dropped if they exist\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.db_insert!",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.db_insert!",
    "category": "function",
    "text": "db_insert!(conn, csv_path=pwd(), csv_prefix=\"<current date>_PubMed_\"; verbose=false, drop_csvs=false)\n\nWrites CSVs from PubMed parsing to a MySQL database.  Tables must already exist (see PubMed.create_tables!).  CSVs can optionally be removed after being written to DB.\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.db_insert!",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.db_insert!",
    "category": "function",
    "text": "db_insert!(conn, articles::Dict{String,DataFrame}, csv_path=pwd(), csv_prefix=\"<current date>_PubMed_\"; verbose=false, drop_csvs=false)\n\nWrites dictionary of dataframes to a MySQL database.  Tables must already exist (see PubMed.create_tables!).  CSVs that are created during writing can be saved (default) or removed.\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.db_insert!",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.db_insert!",
    "category": "function",
    "text": "db_insert!(conn, articles::Dict{String,DataFrame}, csv_path=pwd(), csv_prefix=\"<current date>_PubMed_\"; verbose=false, drop_csvs=false)\n\nWrites dictionary of dataframes to a SQLite database.  Tables must already exist (see PubMed.create_tables!).  CSVs that are created during writing can be saved (default) or removed.\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.dfs_to_csv",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.dfs_to_csv",
    "category": "function",
    "text": "dfs_to_csv(dfs::Dict, path::String, [file_prefix::String])\n\nTakes output of toDataFrames and writes to CSV files at the provided path and with the file prefix.\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.drop_mysql_keys!-Tuple{MySQL.Connection}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.drop_mysql_keys!",
    "category": "method",
    "text": "drop_mysql_keys!(conn)\n\nRemoves keys/indices from MySQL PubMed tables.\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.get_article_mesh-Tuple{Any,Integer}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.get_article_mesh",
    "category": "method",
    "text": "get_article_mesh(db, pmid)\n\nGet the all mesh-descriptors associated with a given article\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.get_article_mesh_by_concept-Tuple{Any,Integer,Vararg{Any,N} where N}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.get_article_mesh_by_concept",
    "category": "method",
    "text": "get_article_mesh_by_concept(db, pmid, umls_concepts...; local_medline)\n\nGet the all mesh-descriptors associated with a given article\n\nArguments:\n\nquery_string: \"\" - assumes full set of results were saved by BioMedQuery directly from XML\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.parse_articles-Tuple{LightXML.XMLElement}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.parse_articles",
    "category": "method",
    "text": "parse_articles(xml)\n\nParses a PubMedArticleSet that matches the NCBI-XML format\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.save_efetch!",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.save_efetch!",
    "category": "function",
    "text": "save_efetch!(output::CitationOutput, efetch_dict, verbose=false)\n\nSave the results of a Entrez efetch to a bibliography file, with format and file path given by output::CitationOutput\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.save_efetch!",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.save_efetch!",
    "category": "function",
    "text": " pubmed_save_efetch(efetch_dict, conn)\n\nSave the results (dictionary) of an entrez-pubmed fetch to the input database.\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.save_pmids!",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.save_pmids!",
    "category": "function",
    "text": " save_pmids!(conn, pmids::Vector{Int64}, verbose::Bool=false)\n\nSave a list of PMIDS into input database.\n\nArguments:\n\nconn: Database connection (MySQL or SQLite)\npmids: Array of PMIDs\nverbose: Boolean to turn on extra print statements\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.all_mesh-Tuple{Any}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.all_mesh",
    "category": "method",
    "text": "all_mesh(db)\n\nReturn all MeSH stored in the mesh_desc table of the input database\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.dict_to_array-Tuple{Dict}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.dict_to_array",
    "category": "method",
    "text": "dict_to_array(dict::Dict)\n\nGiven a dictionary, returns a tuple of arrays with the keys and values.\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.parse_MedlineDate-Tuple{String}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.parse_MedlineDate",
    "category": "method",
    "text": "parse_MedlineDate(ml_dt::String)\n\nParses the contents of the MedlineDate element and returns a tuple of the year and month.\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.parse_author-Tuple{LightXML.XMLElement}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.parse_author",
    "category": "method",
    "text": "parse_author\n\nTakes xml for author, and returns parsed elements\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.parse_month-Tuple{AbstractString}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.parse_month",
    "category": "method",
    "text": "parse_month(mon::String)\n\nParses the string month (month or season) and returns an integer with the first month in range.\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.parse_orcid-Tuple{String}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.parse_orcid",
    "category": "method",
    "text": "parse_orcid(raw_orc::String)\n\nTakes a string containing an ORC ID (url, 16 digit string) and returns a formatted ID (0000-1111-2222-3333).\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.parse_year-Tuple{AbstractString}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.parse_year",
    "category": "method",
    "text": "parse_year(yr::String)\n\nParses the string year and returns an integer with the first year in range.\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.remove_csvs",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.remove_csvs",
    "category": "function",
    "text": "remove_csvs(dfs, path, file_prefix)\n\nRemoves all of the CSV files associated with a dictionary of dataframes\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.remove_csvs-Tuple{Array{String,1}}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.remove_csvs",
    "category": "method",
    "text": "remove_csvs(paths::Vector)\n\nRemoves all of the CSV files associated with an array of paths\n\n\n\n\n\n"
},

{
    "location": "pubmed/#BioMedQuery.PubMed.strip_newline-Tuple{String}",
    "page": "PubMed",
    "title": "BioMedQuery.PubMed.strip_newline",
    "category": "method",
    "text": "strip_newline(val::String)\n\nReplaces new line characters with spaces.\n\n\n\n\n\n"
},

{
    "location": "pubmed/#Structs-and-Functions-1",
    "page": "PubMed",
    "title": "Structs and Functions",
    "category": "section",
    "text": "Modules = [BioMedQuery.PubMed]\nOrder   = [:struct, :function]"
},

{
    "location": "ct/#",
    "page": "Clinical Trials",
    "title": "Clinical Trials",
    "category": "page",
    "text": "Submit and save queries to clinicaltrials.gov"
},

{
    "location": "ct/#Import-1",
    "page": "Clinical Trials",
    "title": "Import",
    "category": "section",
    "text": "using BioMedQuery.CT"
},

{
    "location": "ct/#Search-and-save-1",
    "page": "Clinical Trials",
    "title": "Search and save",
    "category": "section",
    "text": ""
},

{
    "location": "ct/#Create-a-query:-1",
    "page": "Clinical Trials",
    "title": "Create a query:",
    "category": "section",
    "text": "query = Dict(\"term\" => \"acne\", \"age\"=>Int(CT.child), \"locn\" => \"New York, NY\")Note: The term can also indicate joint searches, e.g.\"term\" => \"aspirin OR ibuprofen\""
},

{
    "location": "ct/#Submit-and-save:-1",
    "page": "Clinical Trials",
    "title": "Submit and save:",
    "category": "section",
    "text": "fout= \"./test_CT_search.zip\"\nstatus = BioMedQuery.CT.search_ct(query, fout;)"
},

{
    "location": "dbutils/#",
    "page": "Database Utilities",
    "title": "Database Utilities",
    "category": "page",
    "text": "Collection of functions that extend of simplify interactions with MySQL and SQLite databases"
},

{
    "location": "dbutils/#Import-Module-1",
    "page": "Database Utilities",
    "title": "Import Module",
    "category": "section",
    "text": "using BioMedQuery.DBUtils"
},

{
    "location": "dbutils/#Index-1",
    "page": "Database Utilities",
    "title": "Index",
    "category": "section",
    "text": "Modules = [BioMedQuery.DBUtils]"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.assemble_cols-Tuple{DataFrames.DataFrame}",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.assemble_cols",
    "category": "method",
    "text": "assemble_cols(data_values::DataFrame)\n\nGiven a DataFrame, returns a column name string formatted for an insert/load statement\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.assemble_cols_and_vals-Union{Tuple{Dict{Symbol,T}}, Tuple{T}} where T",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.assemble_cols_and_vals",
    "category": "method",
    "text": "assemble_vals(data_values)\n\nGiven a dictionary containg (:column=>value) return a single string properly formatted for a MySQL insert. E.g MySQL requires CHAR or other non-numeric values be passed with single quotes around them.\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.assemble_cols_and_vals_string-Union{Tuple{Dict{Symbol,T}}, Tuple{T}, Tuple{Dict{Symbol,T},Any}} where T",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.assemble_cols_and_vals_string",
    "category": "method",
    "text": "assemble_vals(data_values)\n\nGiven a dictionary containg (:column=>value), return a single string properly formatted for a MySQL SELECT. E.g MySQL requires CHAR or other non-numeric values be passed with single quotes around them.\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.assemble_vals-Union{Tuple{T}, Tuple{Dict{Symbol,T},Array{Symbol,1}}} where T",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.assemble_vals",
    "category": "method",
    "text": "assemble_vals(data_values, column_names)\n\nGiven a Dict of values and the column names, return a single string properly formatted for a MySQL INSERT. E.g MySQL requires CHAR or other non-numeric values be passed with single quotes around them.\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.col_match-Tuple{Any,String,Array{String,1}}",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.col_match",
    "category": "method",
    "text": "col_match(con, tablename, col_names)\n\nChecks if each column in the csv/data frame has a matching column in the table.\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.col_match-Tuple{Any,String,DataFrames.DataFrame}",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.col_match",
    "category": "method",
    "text": "col_match(con, tablename, data_values)\n\nChecks if each column in the dataframe has a matching column in the table.\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.db_query-Tuple{MySQL.Connection,Any}",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.db_query",
    "category": "method",
    "text": "query_mysql(con, query_code)\n\nExecute a mysql command\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.db_query-Tuple{SQLite.DB,Any}",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.db_query",
    "category": "method",
    "text": "query(db, query_code)\n\nExecute a SQLite command\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.db_select-Union{Tuple{T}, Tuple{Any,Any,Any,Dict{Symbol,T}}} where T",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.db_select",
    "category": "method",
    "text": "select_(con, colnames, tablename, data_values)\n\nPerform: SELECT colnames tablename WHERE keys(datavalues)=values(datavalues)\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.init_mysql_database",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.init_mysql_database",
    "category": "function",
    "text": "init_mysql_database(;host = \"127.0.0.1\", dbname=\"test\",\nusername=\"root\", pswd=\"\", mysql_code=nothing, overwrite=false)\n\nCreate a MySQL database using the code inside mysql_code\n\nArguments\n\nhost, dbname, user, pswd\nmysql_code::String: String with MySQL code that crates all default tables\noverwrite::Bool : Flag, if true and dbname exists, drops all database and re-creates it\n\nOutput\n\ncon: Database connection and table-column names map\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.insert_row!-Union{Tuple{T}, Tuple{Connection,Any,Dict{Symbol,T}}, Tuple{Connection,Any,Dict{Symbol,T},Any}} where T",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.insert_row!",
    "category": "method",
    "text": "insert_row!(db, tablename, values)\n\nInsert a row of values into the specified table for a given a MySQL database handle\n\nArguments:\n\ndb::MySQLDB: Database object (connection and map)\ndata_values::Dict{String, Any}: Array of (string) values\nverbose: Print debugging info\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.insert_row!-Union{Tuple{T}, Tuple{DB,Any,Dict{Symbol,T}}, Tuple{DB,Any,Dict{Symbol,T},Any}} where T",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.insert_row!",
    "category": "method",
    "text": "insert_row!(db, tablename, values)\n\nInsert a row of values into the specified table for a given a SQLite database handle\n\nArguments:\n\ndb::MySQLDB: Database object (connection and map)\ndata_values::Dict{String, Any}: Array of (string) values\nverbose: Print debugging info\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.select_all_tables-Tuple{MySQL.Connection}",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.select_all_tables",
    "category": "method",
    "text": "select_all_tables_mysql(con)\n\nReturn an array of all tables in a given MySQL database\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.select_all_tables-Tuple{SQLite.DB}",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.select_all_tables",
    "category": "method",
    "text": "select_all_tables_mysql(con)\n\nReturn an array of all tables in a given MySQL database\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.set_innodb_checks!",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.set_innodb_checks!",
    "category": "function",
    "text": "set_innodb_checks(conn, autocommit = 1, foreign_keys = 1, unique = 1)\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.colname_dict-Tuple{Any}",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.colname_dict",
    "category": "method",
    "text": "colname_dict_(con)\n\nReturn a dictionary maping tables and their columns for a given MySQL-connection/SQLite-database\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.disable_foreign_checks-Tuple{MySQL.Connection}",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.disable_foreign_checks",
    "category": "method",
    "text": "disable_foreign_checks(con::MySQL.MySQLHandle)\n\nDisables foreign checks for MySQL database\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.disable_foreign_checks-Tuple{SQLite.DB}",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.disable_foreign_checks",
    "category": "method",
    "text": "disable_foreign_checks(con::SQLite.DB)\n\nDisables foreign checks for SQLite database\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.enable_foreign_checks-Tuple{MySQL.Connection}",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.enable_foreign_checks",
    "category": "method",
    "text": "enable_foreign_checks(con::MySQL.MySQLHandle)\n\nEnables foreign checks for MySQL database\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.enable_foreign_checks-Tuple{SQLite.DB}",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.enable_foreign_checks",
    "category": "method",
    "text": "enable_foreign_checks(con::SQLite.DB)\n\nEnables foreign checks for SQLite database\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.select_columns-Tuple{MySQL.Connection,Any}",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.select_columns",
    "category": "method",
    "text": "select_columns_mysql(con, table)\n\nFor a MySQL database, return an array of all columns in the given table\n\n\n\n\n\n"
},

{
    "location": "dbutils/#BioMedQuery.DBUtils.select_columns-Tuple{SQLite.DB,AbstractString}",
    "page": "Database Utilities",
    "title": "BioMedQuery.DBUtils.select_columns",
    "category": "method",
    "text": "select_columns(db, table)\n\nReturn an array with names of columns in the given table\n\n\n\n\n\n"
},

{
    "location": "dbutils/#Functions-1",
    "page": "Database Utilities",
    "title": "Functions",
    "category": "section",
    "text": "Modules = [BioMedQuery.DBUtils]\nOrder   = [:function, :type]"
},

{
    "location": "library/#",
    "page": "Library",
    "title": "Library",
    "category": "page",
    "text": ""
},

{
    "location": "library/#Index-1",
    "page": "Library",
    "title": "Index",
    "category": "section",
    "text": ""
},

]}
