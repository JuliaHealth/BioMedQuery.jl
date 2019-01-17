using ..DBUtils
using SQLite
using MySQL
using DataFrames
using Dates


"""
    create_tables!(conn)

Create and initialize tables to save results from an Entrez/PubMed search or a medline file load.
Caution, all related tables are dropped if they exist
"""
function create_tables!(conn)

    # Determine engine
    sql_engine = (typeof(conn)== MySQL.Connection) ? MySQL : SQLite
    AUTOINCREMENT = (sql_engine == MySQL) ? "AUTO_INCREMENT" : "AUTOINCREMENT"
    engine_info = (sql_engine == MySQL) ? "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" : ""

   #purge related tables
   DBUtils.disable_foreign_checks(conn)
   sql_engine.execute!(conn, "DROP TABLE IF EXISTS basic")
   sql_engine.execute!(conn, "DROP TABLE IF EXISTS author2article")
   sql_engine.execute!(conn, "DROP TABLE IF EXISTS author_ref")
   sql_engine.execute!(conn, "DROP TABLE IF EXISTS pub_type")
   sql_engine.execute!(conn, "DROP TABLE IF EXISTS abstract_full")
   sql_engine.execute!(conn, "DROP TABLE IF EXISTS abstract_structured")
   sql_engine.execute!(conn, "DROP TABLE IF EXISTS mesh_heading")
   sql_engine.execute!(conn, "DROP TABLE IF EXISTS mesh_desc")
   sql_engine.execute!(conn, "DROP TABLE IF EXISTS mesh_qual")
   sql_engine.execute!(conn, "DROP TABLE IF EXISTS file_meta")
   sql_engine.execute!(conn, "DROP TABLE IF EXISTS mesh2umls")
   DBUtils.enable_foreign_checks(conn)


   #Create tables to store
   sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS `basic` (
         `pmid` int(9) NOT NULL,
         `pub_year` smallint(4) DEFAULT NULL,
         `pub_month` tinyint(2) DEFAULT NULL,
         `pub_dt_desc` varchar(50) DEFAULT NULL,
         `title` text DEFAULT NULL,
         `authors` text DEFAULT NULL,
         `journal_title` varchar(500) DEFAULT NULL,
         `journal_ISSN` varchar(9) DEFAULT NULL,
         `journal_volume` varchar(30) DEFAULT NULL,
         `journal_issue` varchar(30) DEFAULT NULL,
         `journal_pages` varchar(50) DEFAULT NULL,
         `journal_iso_abbreviation` varchar(255) DEFAULT NULL,
         `url` varchar(100) DEFAULT NULL,
         `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
         PRIMARY KEY (`pmid`)
       ) $engine_info;"
       )


   sql_engine.execute!(conn, "CREATE TABLE `author_ref` (
         `pmid` int(9) NOT NULL,
         `last_name` varchar(60) DEFAULT NULL,
         `first_name` varchar(60) DEFAULT NULL,
         `initials` varchar(10) DEFAULT NULL,
         `suffix` varchar(10) DEFAULT NULL,
         `orcid` varchar(19) DEFAULT NULL,
         `collective` varchar(200) DEFAULT NULL,
         `affiliation` text DEFAULT NULL,
         `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
         FOREIGN KEY(`pmid`) REFERENCES basic(`pmid`)
       ) $engine_info;"
       )

   # sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS `author2article` (
   #       `pmid` int(9) NOT NULL,
   #       `author_id` int(10) NOT NULL,
   #       `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
   #       PRIMARY KEY (`pmid`, `author_id`),
   #       FOREIGN KEY(`pmid`) REFERENCES basic(`pmid`),
   #       FOREIGN KEY(`author_id`) REFERENCES author_ref(`author_id`)
   #     ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;"
   #     )

   sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS `pub_type` (
         `pmid` int(9) NOT NULL,
         `uid` int(6) NOT NULL,
         `name` varchar(100) NOT NULL,
         `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
         PRIMARY KEY (`pmid`,`uid`),
         FOREIGN KEY(`pmid`) REFERENCES basic(`pmid`)
       ) $engine_info;"
       )


   sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS `abstract_full` (
         `pmid` int(9) NOT NULL,
         `abstract_text` text DEFAULT NULL,
         `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
         PRIMARY KEY (`pmid`),
         FOREIGN KEY(`pmid`) REFERENCES basic(`pmid`)
       ) $engine_info;"
       )


   sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS `abstract_structured` (
         `abstract_structured_id` INTEGER PRIMARY KEY $AUTOINCREMENT,
         `pmid` int(9) NOT NULL,
         `nlm_category` varchar(20) DEFAULT NULL,
         `label` varchar(40) DEFAULT NULL,
         `abstract_text` text DEFAULT NULL,
         `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
         FOREIGN KEY(`pmid`) REFERENCES basic(`pmid`)
       ) $engine_info;"
       )

   sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS `file_meta` (
         `file_name` varchar(30) NOT NULL,
         `ins_start_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
         `ins_end_time` timestamp NULL,
         PRIMARY KEY (`file_name`)
       ) $engine_info;"
       )


   # # --------------------------
   # #  MeshHeading Tables
   # # --------------------------
   # # --
   # # Descriptor
   # # The id corresponds to the DUI of mesh library
   # # Adding a "D" at the beginning of the id, allows for
   # # lookup in the mesh browerser
   # #  https://www.nlm.nih.gov/mesh/MBrowser.html

   # Qualifier
   sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS `mesh_desc` (
         `uid` int(6) NOT NULL,
         `name` varchar(255) NOT NULL,
         `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
         PRIMARY KEY (`uid`)
       ) $engine_info;"
       )

   # Heading
   sql_engine.execute!(conn, "CREATE TABLE `mesh_qual` (
         `uid` int(6) NOT NULL,
         `name` varchar(255) NOT NULL,
         `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
         PRIMARY KEY (`uid`)
       ) $engine_info;"
       )

   sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS `mesh_heading` (
         `pmid` int(9) NOT NULL,
         `desc_uid` int(6) NOT NULL,
         `desc_maj_status` tinyint(1) NOT NULL,
         `qual_uid` int DEFAULT NULL,
         `qual_maj_status` tinyint DEFAULT NULL,
         `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
         FOREIGN KEY(`pmid`) REFERENCES basic(`pmid`),
         FOREIGN KEY(`desc_uid`) REFERENCES mesh_desc(`uid`),
         FOREIGN KEY(`qual_uid`) REFERENCES mesh_qual(`uid`)
       ) $engine_info"
       )

end

function create_post_tables!(conn::MySQL.Connection)

    # engine
    engine_info = "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"

   #purge related tables
   DBUtils.disable_foreign_checks(conn)
   MySQL.execute!(conn, "DROP TABLE IF EXISTS author2article")
   MySQL.execute!(conn, "DROP TABLE IF EXISTS author")
   DBUtils.enable_foreign_checks(conn)


   MySQL.execute!(conn, "CREATE TABLE `author` (
         `auth_id` int(12) NOT NULL AUTO_INCREMENT,
         `last_name` varchar(60) DEFAULT NULL,
         `first_name` varchar(60) DEFAULT NULL,
         `initials` varchar(10) DEFAULT NULL,
         `suffix` varchar(10) DEFAULT NULL,
         `orcid` varchar(19) DEFAULT NULL,
         `collective` varchar(200) DEFAULT NULL,
         `affiliation` text DEFAULT NULL,
         `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
         PRIMARY KEY (`auth_id`)
       ) $engine_info;"
       )


   #Create tables to store
   MySQL.execute!(conn, "CREATE TABLE IF NOT EXISTS `author2article` (
         `pmid` int(9) NOT NULL,
         `auth_id` int(12) NOT NULL,
         PRIMARY KEY (`pmid`,`auth_id`),
         FOREIGN KEY (`pmid`) REFERENCES basic(`pmid`),
         FOREIGN KEY (`auth_id`) REFERENCES author(`auth_id`)
       ) $engine_info;"
       )

end

"""
    add_mysql_keys!(conn)

Adds indices/keys to MySQL PubMed tables.
"""
function add_mysql_keys!(conn::MySQL.Connection)

    res = MySQL.Query(conn, "SHOW INDEX FROM basic WHERE key_name = 'pub_year'") |> DataFrame
    size(res)[1] == 1 && return nothing

    MySQL.execute!(conn, "ALTER TABLE `basic`
          ADD KEY `pub_year` (`pub_year`),
          ADD KEY `pub_month` (`pub_month`),
          ADD KEY `pub_year_month` (`pub_year`,`pub_month`),
          ADD KEY `journal_title` (`journal_title`),
          ADD KEY `journal_ISSN` (`journal_ISSN`)
        ;"
        )

    MySQL.execute!(conn, "ALTER TABLE `author_ref`
          ADD KEY `last_name` (`last_name`),
          ADD KEY `last_first_name` (`last_name`, `first_name`),
          ADD KEY `collective` (`collective`)
        ;"
        )

    MySQL.execute!(conn, "ALTER TABLE `pub_type`
          ADD KEY `name` (`name`)
        ;"
        )

    MySQL.execute!(conn, "ALTER TABLE `abstract_structured`
          ADD KEY `label` (`label`),
          ADD KEY `nlm_category` (`nlm_category`)
        ;"
        )

    MySQL.execute!(conn, "ALTER TABLE `mesh_desc`
          ADD KEY `name` (`name`)
        ;"
        )

    MySQL.execute!(conn, "ALTER TABLE `mesh_qual`
          ADD KEY `name` (`name`)
        ;"
        )

   return nothing
end

"""
    drop_mysql_keys!(conn)

Removes keys/indices from MySQL PubMed tables.
"""
function drop_mysql_keys!(conn::MySQL.Connection)

    res = MySQL.Query(conn, "SHOW INDEX FROM basic WHERE key_name = 'pub_year'", DataFrame)
    size(res)[1] == 0 && return nothing

    MySQL.execute!(conn, "ALTER TABLE `basic`
          DROP KEY `pub_year`,
          DROP KEY `pub_month`,
          DROP KEY `pub_year_month`,
          DROP KEY `journal_title`,
          DROP KEY `journal_ISSN`
        ;"
        )

    MySQL.execute!(conn, "ALTER TABLE `author_ref`
          DROP KEY `last_name`,
          DROP KEY `last_first_name`,
          DROP KEY `collective`
        ;"
        )

    MySQL.execute!(conn, "ALTER TABLE `pub_type`
          DROP KEY `name`
        ;"
        )

    MySQL.execute!(conn, "ALTER TABLE `abstract_structured`
          DROP KEY `label`,
          DROP KEY `nlm_category`
        ;"
        )

    MySQL.execute!(conn, "ALTER TABLE `mesh_desc`
          DROP KEY `name`
        ;"
        )

    MySQL.execute!(conn, "ALTER TABLE `mesh_qual`
          DROP KEY `name`
        ;"
        )

    MySQL.execute!(conn, "ALTER TABLE `mesh_heading`
          DROP KEY `pmid_uids`
        ;"
        )
end


"""
    create_pmid_table!(conn; tablename="article")

Creates a table, using either MySQL of SQLite, to store PMIDs from
Entrez related searches. All tables are empty at this point
"""
function create_pmid_table!(conn)

    # Determine engine
    sql_engine = (typeof(conn) == MySQL.Connection) ? MySQL : SQLite

    #purge related tables
    # sql_engine.execute!(conn, "DROP TABLE IF EXISTS $tablename")

    #Create tables to store
    sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS basic (
                                pmid INTEGER NOT NULL PRIMARY KEY
                                );"
                        )
end


"""
    all_pmids(db)

Return all PMIDs stored in the *basic* table of the input database
"""
function all_pmids(conn)
    sql_engine = (typeof(conn)== MySQL.Connection) ? MySQL : SQLite
    query = sql_engine.Query(conn, "SELECT pmid FROM basic;") |> DataFrame
    return query[:pmid]
end

"""
    all_mesh(db)

Return all MeSH stored in the *mesh_desc* table of the input database
"""
function all_mesh(db)
    sel = db_query(db, "SELECT name FROM mesh_desc;")
    return sel[:name]
end

"""
    abstracts_by_year(db, pub_year; local_medline=false)

Return all abstracts of article published in the given year.
If local_medline flag is set to true, it is assumed that db contains *article*
table with only PMIDs and all other info is available in a (same host) medline database
"""
function abstracts_by_year(db, pub_year; local_medline=false, uid_str = "pmid")

    #get all abstracts UNIQUE pairs
    query_code = ""
    if local_medline
    query_code = "SELECT article.$uid_str as $uid_str,
                         medline.abstract_full.abstract_text as abstract_text
                    FROM article
              INNER JOIN medline.basic ON medline.basic.pmid = article.pmid
              INNER JOIN medline.abstract_full ON medline.abstract_full.pmid = article.pmid
                   WHERE medline.basic.pub_year = $pub_year "
    else
        query_code = "SELECT at.$uid_str at $uid_str,
                             at.abstract as abstract_text
                        FROM abstract_text as at
                  INNER JOIN basic ar on at.pmid = ar.pmid
                       WHERE ar.pub_year = $pub_year "
    end

    sel = db_query(db, query_code)
    num_abstracts = size(sel)[1]
    println("Retrieved: ", num_abstracts, " abstracts")
    return sel
end

"""
    abstracts(db; local_medline=false)

Return all abstracts related to PMIDs in the database.
If local_medline flag is set to true, it is assumed that db contains *basic*
table with only PMIDs and all other info is available in a (same host) medline database
"""
function abstracts(db; local_medline=false)

    #get all abstracts UNIQUE pairs
    query_code = ""
    if local_medline
        query_code = "SELECT basic.pmid as pmid,
                             medline.abstract_full.abstract_text as abstract_text
                        FROM basic
                  INNER JOIN medline.abstract_full ON medline.abstract_full.pmid = basic.pmid"
    else
        query_code = "SELECT ar.pmid as pmid,
                             ar.abstract_text as abstract_text
                        FROM abstract_full as ar "
    end

    sel = db_query(db, query_code)
    num_abstracts = size(sel)[1]
    @info "Retrieved abstracts: " num_abstracts
    return sel
end

"""
    get_article_mesh(db, pmid)

Get the all mesh-descriptors associated with a given article
"""
function get_article_mesh(db, pmid::Integer)

    query_string = "SELECT md.name
                      FROM mesh_heading as mh,
                           mesh_desc as md
                     WHERE mh.desc_uid = md.uid
                      AND mh.pmid = $pmid"
    query  = db_query(db, query_string)

    #return data array
    return query[:name]

end

"""
    get_article_mesh_by_concept(db, pmid, umls_concepts...; local_medline)

Get the all mesh-descriptors associated with a given article
## Arguments:
* query_string: "" - assumes full set of results were saved by BioMedQuery directly from XML
"""
function get_article_mesh_by_concept(db, pmid::Integer, umls_concepts...; query_string="")

    concept_set_string = "'" * join(umls_concepts,"','") * "'"

    if query_string == ""
        query_string = "SELECT DISTINCT(md.name), m2u.umls
                        FROM mesh_desc AS md
                        JOIN mesh_heading AS mh ON mh.desc_uid = md.uid
                        JOIN mesh2umls AS m2u ON m2u.mesh = md.name
                        WHERE mh.pmid = $pmid
                        AND m2u.umls IN  ($(concept_set_string))"
    end

    query  = db_query(db, query_string)

    #return data array
    return query[:name]

end

"""
    db_insert!(conn, articles::Dict{String,DataFrame}, csv_path=pwd(), csv_prefix="<current date>_PubMed_"; verbose=false, drop_csvs=false)

Writes dictionary of dataframes to a MySQL database.  Tables must already exist (see PubMed.create_tables!).  CSVs that are created during writing can be saved (default) or removed.
"""
function db_insert!(db::MySQL.Connection, articles::Dict{String,DataFrame}, csv_path::String = pwd(), csv_prefix::String = "$(Date(now()))_PubMed_"; verbose=false, drop_csv=false)

    dfs_to_csv(articles, csv_path, csv_prefix)

    #Insert csv prefix into files_meta talbe
    meta_sql = """INSERT INTO file_meta (file_name,ins_start_time) VALUES ('$csv_prefix',CURRENT_TIMESTAMP)"""
    MySQL.execute!(db, meta_sql)

    for (table, df) in articles
        # check if column names all exist in mysql table
        if !col_match(db, table, df)
            error("Each DataFrame column must match the name of a table column. $table had mismatches.")
        end

        path = joinpath(csv_path, "$(csv_prefix)$(table).csv")
        cols_string = assemble_cols(df)

        # Save article data (MySQL.stream from df)
        ins_sql = """LOAD DATA LOCAL INFILE '$path' INTO TABLE $table CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES ($cols_string)"""
        MySQL.execute!(db, ins_sql)
    end

    meta_sql = """UPDATE file_meta SET ins_end_time = CURRENT_TIMESTAMP WHERE file_name = '$csv_prefix'"""
    MySQL.execute!(db, meta_sql)

    if drop_csv
        remove_csvs(articles, csv_path, csv_prefix)
    end

    return nothing

end

"""
    db_insert!(conn, csv_path=pwd(), csv_prefix="<current date>_PubMed_"; verbose=false, drop_csvs=false)

Writes CSVs from PubMed parsing to a MySQL database.  Tables must already exist (see PubMed.create_tables!).  CSVs can optionally be removed after being written to DB.
"""
function db_insert!(db::MySQL.Connection, csv_path::String = pwd(), csv_prefix::String = "$(Date(now()))_PubMed_"; verbose=false, drop_csv=false)
    paths = Vector{String}()

    #Insert csv prefix into files_meta talbe
    meta_sql = """INSERT INTO file_meta (file_name,ins_start_time) VALUES ('$csv_prefix',CURRENT_TIMESTAMP)"""
    MySQL.execute!(db, meta_sql)

    for table in select_all_tables(db)
        # for all non-file_meta tables
        if table != "file_meta"
            path = joinpath(csv_path, "$(csv_prefix)$(table).csv")
            drop_csv && push!(paths,path)

            headers = CSV.read(path, DataFrame, rows = 1)
            # return headers

            cols = String.(getfield(headers, :colindex).names)
            if !col_match(db, table, cols)
                error("Each CSV column must match the name of a table column. $table had mismatches.")
            end

            cols_string = join(cols, ",")

            # Save article data (MySQL.stream from df)
            ins_sql = """LOAD DATA LOCAL INFILE '$path' INTO TABLE $table CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES ($cols_string)"""
            MySQL.execute!(db, ins_sql)
        end
    end

    meta_sql = """UPDATE file_meta SET ins_end_time = CURRENT_TIMESTAMP WHERE file_name = '$csv_prefix'"""
    MySQL.execute!(db, meta_sql)

    if drop_csv
        remove_csvs(paths)
    end

    return nothing

end

function db_insert!(db::MySQL.Connection, pmid::Int64, articles::Dict{String,DataFrame}, csv_path::String = pwd(), csv_prefix::String = "$(Date(now()))_PubMed_"; verbose=false, drop_csv=false)

    dfs_to_csv(articles, csv_path, csv_prefix)

    for (table, df) in articles
        if occursin(r"$mesh*", table)
            # check if column names all exist in mysql table
            if !col_match(db, table, df)
                error("Each DataFrame column must match the name of a table column. $table had mismatches.")
            end

            path = joinpath(csv_path, "$(csv_prefix)$(table).csv")
            cols_string = assemble_cols(df)

            # Save article data (MySQL.stream from df)
            ins_sql = """LOAD DATA LOCAL INFILE '$path' INTO TABLE $table CHARACTER SET utf8mb4 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES ($cols_string)"""
            MySQL.execute!(db, ins_sql)
        end
    end

    if drop_csv
        remove_csvs(articles, csv_path, csv_prefix)
    end

    return nothing

end

"""
    db_insert!(conn, articles::Dict{String,DataFrame}, csv_path=pwd(), csv_prefix="<current date>_PubMed_"; verbose=false, drop_csvs=false)

Writes dictionary of dataframes to a SQLite database.  Tables must already exist (see PubMed.create_tables!).  CSVs that are created during writing can be saved (default) or removed.
"""
function db_insert!(db::SQLite.DB, articles::Dict{String,DataFrame}, csv_path::String = pwd(), csv_prefix::String = "$(Date(now()))_PubMed_"; verbose=false, drop_csv=false)

    #Insert csv prefix into files_meta talbe
    meta_sql = """INSERT INTO file_meta (file_name,ins_start_time) VALUES ('$csv_prefix',CURRENT_TIMESTAMP)"""
    SQLite.execute!(db, meta_sql)

    for (table, df) in articles

        # check if column names all exist in mysql table
        if !col_match(db, table, df)
            error("Each DataFrame column must match the name of a table column. $table had mismatches.")
        end

        for i = 1:size(df)[1]
            col_dict = Dict{Symbol,Any}()
            for col in getfield(df, :colindex).names
                col_dict[col] = df[i,col]
            end
            insert_row!(db, table, col_dict)
        end

    end

    meta_sql = """UPDATE file_meta SET ins_end_time = CURRENT_TIMESTAMP WHERE file_name = '$csv_prefix'"""
    SQLite.execute!(db, meta_sql)

    return nothing

end
