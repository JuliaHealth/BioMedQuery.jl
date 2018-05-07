using ..DBUtils
using SQLite
using MySQL
using DataStreams, DataFrames


"""
    create_tables!(conn, medline_load=false)
Create and initialize tables to save results from an Entrez/PubMed search or a medline file load.
Caution, all related tables are dropped if they exist
"""
function create_tables!(conn, medline_load::Bool=false)

    # Determine engine
    sql_engine = (typeof(conn)== MySQL.Connection) ? MySQL : SQLite
    AUTOINCREMENT = (sql_engine == MySQL) ? "AUTO_INCREMENT" : "AUTOINCREMENT"

    if !medline_load
        #purge related tables
        DBUtils.disable_foreign_checks(conn)
        sql_engine.execute!(conn, "DROP TABLE IF EXISTS article")
        sql_engine.execute!(conn, "DROP TABLE IF EXISTS author")
        sql_engine.execute!(conn, "DROP TABLE IF EXISTS author2article")
        sql_engine.execute!(conn, "DROP TABLE IF EXISTS mesh_descriptor")
        sql_engine.execute!(conn, "DROP TABLE IF EXISTS mesh_qualifier")
        sql_engine.execute!(conn, "DROP TABLE IF EXISTS mesh_heading")
        DBUtils.enable_foreign_checks(conn)


        #Create tables to store
        sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS article(
                pmid INTEGER NOT NULL PRIMARY KEY,
                title TEXT,
                pubYear INTEGER,
                abstract TEXT
                );"
            )

        sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS author(
                id INTEGER PRIMARY KEY $AUTOINCREMENT,
                forename VARCHAR(255),
                lastname VARCHAR(255) NOT NULL,
                CONSTRAINT unq UNIQUE(forename,  lastname)
                );"
            )

        sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS author2article(
                aid INTEGER,
                pmid INTEGER,
                FOREIGN KEY(aid) REFERENCES author(id),
                FOREIGN KEY(pmid) REFERENCES article(pmid),
                PRIMARY KEY(aid, pmid)
                );"
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

        sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS mesh_descriptor(
                id INTEGER NOT NULL PRIMARY KEY,
                name VARCHAR(255) UNIQUE
                );"
            )

        # Qualifier
        sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS mesh_qualifier(
                id INTEGER NOT NULL PRIMARY KEY,
                name VARCHAR(255) UNIQUE
                );"
            )

        # Heading
        sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS mesh_heading(
                id INTEGER PRIMARY KEY $AUTOINCREMENT,
                pmid INTEGER, did INTEGER, qid INTEGER,
                dmjr VARCHAR(1), qmjr VARCHAR(1),
                FOREIGN KEY(pmid) REFERENCES article(pmid),
                FOREIGN KEY(did) REFERENCES mesh_descriptor(id),
                FOREIGN KEY(qid) REFERENCES mesh_qualifier(id),
                CONSTRAINT unq UNIQUE(pmid, did, qid)
                );"
            )
   else #MEDLINE LOAD = TRUE
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
             `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
             PRIMARY KEY (`pmid`),
             KEY `pub_year` (`pub_year`),
             KEY `pub_month` (`pub_month`),
             KEY `pub_year_month` (`pub_year`,`pub_month`),
             KEY `journal_title` (`journal_title`),
             KEY `journal_ISSN` (`journal_ISSN`)
           ) ENGINE=InnoDB DEFAULT CHARSET=latin1;"
           )


       sql_engine.execute!(conn, "CREATE TABLE `author_ref` (
             `author_id` int(10) NOT NULL,
             `last_name` varchar(60) DEFAULT NULL,
             `first_name` varchar(60) DEFAULT NULL,
             `initials` varchar(10) DEFAULT NULL,
             `suffix` varchar(10) DEFAULT NULL,
             `orcid` varchar(19) DEFAULT NULL,
             `collective` varchar(200) DEFAULT NULL,
             `affiliation` varchar(255) DEFAULT NULL,
             `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
             PRIMARY KEY (`author_id`),
             KEY `last_name` (`last_name`),
             KEY `last_first_name` (`last_name`, `first_name`),
             KEY `collective` (`collective`)
           ) ENGINE=InnoDB DEFAULT CHARSET=latin1;"
           )

       sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS `author2article` (
             `pmid` int(9) NOT NULL,
             `author_id` int(10) NOT NULL,
             `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
             PRIMARY KEY (`pmid`, `author_id`),
             FOREIGN KEY(`pmid`) REFERENCES basic(`pmid`),
             FOREIGN KEY(`author_id`) REFERENCES author_ref(`author_id`)
           ) ENGINE=InnoDB DEFAULT CHARSET=latin1;"
           )

       sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS `pub_type` (
             `pmid` int(9) NOT NULL,
             `uid` int(6) NOT NULL,
             `name` varchar(100) NOT NULL,
             `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
             PRIMARY KEY (`pmid`,`uid`),
             KEY `name` (`name`),
             FOREIGN KEY(`pmid`) REFERENCES basic(`pmid`)
           ) ENGINE=InnoDB DEFAULT CHARSET=latin1;"
           )


       sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS `abstract_full` (
             `pmid` int(9) NOT NULL,
             `abstract_text` text DEFAULT NULL,
             `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
             PRIMARY KEY (`pmid`),
             FOREIGN KEY(`pmid`) REFERENCES basic(`pmid`)
           ) ENGINE=InnoDB DEFAULT CHARSET=latin1;"
           )


       sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS `abstract_structured` (
             `abstracts_structured_id` int(12) NOT NULL AUTO_INCREMENT,
             `pmid` int(9) NOT NULL,
             `nlm_category` varchar(20) DEFAULT NULL,
             `label` varchar(40) DEFAULT NULL,
             `abstract_text` text DEFAULT NULL,
             `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
             PRIMARY KEY (`abstracts_structured_id`, `pmid`),
             FOREIGN KEY(`pmid`) REFERENCES basic(`pmid`),
             KEY `label` (`label`),
             KEY `nlm_category` (`nlm_category`)
           ) ENGINE=InnoDB DEFAULT CHARSET=latin1;"
           )

       sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS `file_meta` (
             `file_name` varchar(30) NOT NULL,
             `ins_start_time` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
             `ins_end_time` timestamp NULL,
             PRIMARY KEY (`file_name`)
           ) ENGINE=InnoDB DEFAULT CHARSET=latin1;"
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
             `name` varchar(100) NOT NULL,
             `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
             PRIMARY KEY (`uid`),
             KEY `name` (`name`)
           ) ENGINE=InnoDB DEFAULT CHARSET=latin1;"
           )

       # Heading
       sql_engine.execute!(conn, "CREATE TABLE `mesh_qual` (
             `uid` int(6) NOT NULL,
             `name` varchar(100) NOT NULL,
             `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
             PRIMARY KEY (`uid`),
             KEY `name` (`name`)
           ) ENGINE=InnoDB DEFAULT CHARSET=latin1;"
           )

       sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS `mesh_heading` (
             `pmid` int(9) NOT NULL,
             `desc_uid` int(6) NOT NULL,
             `desc_maj_status` boolean DEFAULT NULL,
             `qual_uid` int(6) DEFAULT -1,
             `qual_maj_status` boolean DEFAULT NULL,
             `ins_dt_time` timestamp DEFAULT CURRENT_TIMESTAMP,
             PRIMARY KEY (`pmid`, `desc_uid`, `qual_uid`),
             FOREIGN KEY(`pmid`) REFERENCES basic(`pmid`),
             FOREIGN KEY(`desc_uid`) REFERENCES mesh_desc(`uid`),
             KEY `desc_uid_maj` (`desc_uid`,`desc_maj_status`),
             FOREIGN KEY(`qual_uid`) REFERENCES mesh_qual(`uid`),
             KEY `qual_UID_maj` (`qual_UID`,`qual_maj_status`)
           ) ENGINE=InnoDB DEFAULT CHARSET=latin1;"
           )

   end

end



"""
    init_pmid_db!(conn; tablename="article")
Creates a database, using either MySQL of SQLite, with all necessary tables to store
Entrez related searches. All tables are empty at this point
"""
function create_pmid_table!(conn; tablename="article")

    # Determine engine
    sql_engine = (typeof(conn)== MySQL.Connection) ? MySQL : SQLite

    #purge related tables
    # sql_engine.execute!(conn, "DROP TABLE IF EXISTS $tablename")

    #Create tables to store
    sql_engine.execute!(conn, "CREATE TABLE IF NOT EXISTS $tablename(
                                pmid INTEGER NOT NULL PRIMARY KEY
                                );"
                        )
end


"""
    all_pmids(db)
Return all PMIDs stored in the *article* table of the input database
"""
function all_pmids(conn)
    sql_engine = (typeof(conn)== MySQL.Connection) ? MySQL : SQLite
    query = sql_engine.query(conn, "SELECT pmid FROM article;")
    return query[1]
end

"""
    all_mesh(db)
Return all PMIDs stored in the *article* table of the input database
"""
function all_mesh(db)
    sel = db_query(db, "SELECT name FROM mesh_descriptor;")
    return sel[1]
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
                         medline.basic.abstract as abstract_text
                    FROM article
              INNER JOIN medline.basic ON medline.basic.pmid = article.pmid
                   WHERE medline.basic.pubYear = '$pub_year' "
    else
        query_code = "SELECT ar.$uid_str as $uid_str,
                             ar.abstract as abstract_text
                        FROM article as ar
                       WHERE ar.pubYear = '$pub_year' "
    end

    sel = db_query(db, query_code)
    num_abstracts = size(sel)[1]
    println("Retrieved: ", num_abstracts, " abstracts")
    return sel
end

"""
abstracts(db; local_medline=false)

Return all abstracts related to PMIDs in the database.
If local_medline flag is set to true, it is assumed that db contains *article*
table with only PMIDs and all other info is available in a (same host) medline database
"""
function abstracts(db; local_medline=false)

    #get all abstracts UNIQUE pairs
    query_code = ""
    if local_medline
        query_code = "SELECT article.pmid as pmid,
                             medline.basic.abstract as abstract_text
                        FROM article
                  INNER JOIN medline.basic ON medline.basic.pmid = article.pmid"
    else
        query_code = "SELECT ar.pmid as pmid,
                             ar.abstract as abstract_text
                        FROM article as ar "
    end

    sel = db_query(db, query_code)
    num_abstracts = size(sel)[1]
    println("Retrieved: ", num_abstracts, " abstracts")
    return sel
end

"""
    get_article_mesh(db, pmid)
Get the all mesh-descriptors associated with a give article
"""
function get_article_mesh(db, pmid::Integer)

    query_string = "SELECT md.name
                      FROM mesh_heading as mh,
                           mesh_descriptor as md
                     WHERE mh.did = md.id
                      AND mh.pmid = $pmid"
    query  = db_query(db, query_string)

    #return data array
    return query.columns[1]

end

"""
    get_article_mesh_by_concept(db, pmid, umls_concepts...; local_medline)
Get the all mesh-descriptors associated with a give article
## Argumets:
* query_string: "" - assumes full set of results were saved by BioMedQuery directly from XML
"""
function get_article_mesh_by_concept(db, pmid::Integer, umls_concepts...; query_string="")

    concept_set_str = """( "$(umls_concepts[1])" """

    for i=2:length(umls_concepts)
        concept_set_str = """$(concept_set_str), "$(umls_concepts[i])" """
    end

    concept_set_str = "$(concept_set_str))"

    if query_string == ""
        query_string = "SELECT DISTINCT(md.name), m2u.umls
                        FROM mesh_descriptor AS md
                        JOIN mesh_heading AS mh ON mh.did = md.id
                        JOIN mesh2umls AS m2u ON m2u.mesh = md.name
                        WHERE mh.pmid = $pmid
                        AND m2u.umls IN  $(concept_set_str)"
    end

    query  = db_query(db, query_string)

    #return data array
    return query.columns[1]

end

function db_insert!(db, article::PubMedArticle, verbose=false)

    sql_engine = (typeof(db)== MySQL.Connection) ? MySQL : SQLite


    #------- PMID - TITLE - YEAR
    ismissing(article.pmid) && error("NULL PMID")

    # Save article data
    insert_row!(db, "article",
                Dict(:pmid =>article.pmid,
                     :title=>article.title,
                     :pubYear=>article.date.year,
                     :abstract=>article.abstract_full), verbose)

    #------- AUTHORS
    for au in article.authors

        if ismissing(au.last_name)
           println("Skipping author, null field: ", au)
           continue
        end

        forename = au.first_name
        lastname = au.last_name

        author_id = insert_row!(db, "author", Dict(:id => missing, :forename => forename, :lastname => lastname), verbose)

        if author_id < 0
            sel = db_select(db, ["id"], "author",
                            Dict(:forename => forename,
                                 :lastname => lastname))
            if length(sel[1]) > 0
                author_id = sel[1][1]
                if verbose
                    println("Author already in db: ", au)
                end
                insert_row!(db, "author2article",
                Dict(:aid =>author_id, :pmid => article.pmid), verbose)
            else
                error("Can't save nor find Author: ", au)
            end
        else
          insert_row!(db, "author2article",
          Dict(:aid =>author_id, :pmid => article.pmid), verbose)
        end
    end
end

function db_insert!(db, pmid::Int64, mesh_heading_list::MeshHeadingList, verbose=false)

    for heading in mesh_heading_list
        did_int = heading.descriptor.uid
        descriptor_name = heading.descriptor.name
        dmjr = heading.descriptor_mjr


        #Save Descriptor
        insert_row!(db, "mesh_descriptor",
        Dict(:id=>did_int,
             :name=>descriptor_name),
             verbose)

        if isempty(heading.qualifier)
            #Save Headings
            insert_row!(db, "mesh_heading",
            Dict(:id=>missing,
                 :pmid=> pmid,
                 :did=>did_int,
                 :qid=>missing,
                 :dmjr=>missing, :qmjr=>missing), verbose )
        else

            for i=1:length(heading.qualifier)
                qid_int = heading.qualifier[i].uid
                qualifier_name = heading.qualifier[i].name
                qmjr = heading.qualifier_mjr[i]

                #Save Qualifiers`
                insert_row!(db, "mesh_qualifier",
                Dict(:id=>qid_int,
                     :name=>qualifier_name),
                     verbose )

                #Save Headings
                insert_row!(db, "mesh_heading",
                Dict(:id=>missing,
                     :pmid=> pmid,
                     :did=>did_int,
                     :qid=>qid_int,
                     :dmjr=>dmjr, :qmjr=>qmjr), verbose )
            end
        end

    end
end
