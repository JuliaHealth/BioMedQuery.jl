using MySQL
using FTPClient
using BioMedQuery.PubMed
using BioMedQuery.DBUtils
using LightXML
using DataFrames

"""
    load_medline(db_con, output_dir; start_file=1, end_file=928, year=2018, test=false)

Given a MySQL connection and optionally the start and end files, fetches the medline files, parses the xml, and loads into a MySQL DB (assumes tables already exist). The raw (xml.gz) and parsed (csv) files will be stored in the output_dir.

## Arguments
* `db_con` : A MySQL Connection to a db (tables must already be created - see `PubMed.create_tables!`)
* `output_dir` : root directory where the raw and parsed files should be stored
* `start_file` : which medline file should the loading start at
* `end_file` : which medline file should the loading end at (default is last file in 2018 baseline)
* `year` : which year medline is (current is 2018)
* `test` : if true, a sample file will be downloaded, parsed, and loaded instead of the baseline files
"""
function load_medline!(db_con::MySQL.Connection, output_dir::String; start_file::Int=1, end_file::Int=928, year::Int=2018, test::Bool=false)

    ftp_con = init_medline(output_dir, test)

    set_innodb_checks!(db_con,0,0,0)
    # drop_mysql_keys!(db_con)

    if test
        start_file = 1
        end_file = 1
    end

    info("Getting files from Medline")
    @sync for n = start_file:end_file
        @async get_ml_file(get_file_name(n, year, test), ftp_con, output_dir)
    end

    info("Parsing files into CSV")
    pmap(x -> parse_ml_file(get_file_name(x, year, test), output_dir), start_file:end_file)

    info("Loading CSVs into MySQL")
    @sync for n = start_file:end_file

        fname = get_file_name(n, year, test) ::String
        println("Loading file: ", fname)

        csv_prefix = "$(fname[1:end-7])_"
        csv_path = joinpath(output_dir,"medline","parsed_files")

        @async db_insert!(db_con, csv_path, csv_prefix)
    end

    set_innodb_checks!(db_con)
    # add_mysql_keys!(db_con)

    info("All files processed - closing FTP connection")
    close_cons(ftp_con)

    return nothing
end

"""
    init_medline(output_dir, test=false)

Sets up environment (folders), and connects to medline FTP Server and returns the connection.
"""
function init_medline(output_dir::String, test::Bool=false)
    ## SET UP ENVIRONMENT
    info("======Setting up folders and creating FTP Connection======")

    try
        mkdir(joinpath(output_dir,"medline"))
    catch
        println("medline directory already exists")
    end

    try
        mkdir(joinpath(output_dir,"medline","raw_files"))
        mkdir(joinpath(output_dir,"medline","parsed_files"))
    catch
        println("files directories already exists")
    end

    # Initialize FTP
    ftp_init()

    ftp_con = get_ftp_con(test)

    return ftp_con
end



"""
    get_file_name(fnum::Int, year::Int = 2018, test = false)
Returns the medline file name given the file number and year.
"""
function get_file_name(fnum::Int, year::Int, test::Bool=false)
    nstr = lpad(fnum,4,0) # pad iterator with leading zeros so total length is 4
    y2 = string(year)[3:4]
    if test
        y2 = "sample" * y2
    end
    return "pubmed$(y2)n$nstr.xml.gz"
end

"""
    get_ml_file(fname::String, conn::ConnContext, output_dir)

Retrieves the file with fname and puts in medline/raw_files.  Returns the HTTP response.
"""
function get_ml_file(fname::String, conn::ConnContext, output_dir::String)
    println("Getting file: ", fname)
    # get file
    path = joinpath(output_dir,"medline","raw_files",fname)
    if isfile(path)
        resp = "File already exists, using local file"
    else
        # conn = get_ftp_con()
        resp = ftp_get(conn, fname, path)
        # ftp_close_connection(conn)
    end

    return resp
end


"""
    get_ftp_con(test = false)
Get an FTP connection
"""
function get_ftp_con(test::Bool = false)
    if test
        options = RequestOptions(url="ftp://ftp.ncbi.nlm.nih.gov/pubmed/baseline-2018-sample/")
    else
        options = RequestOptions(url="ftp://ftp.ncbi.nlm.nih.gov/pubmed/baseline/")
    end
    conn = ftp_connect(options) # returns connection and response
    return conn[1]# get ConnContext object
end

"""
    parse_ml_file(fname::String, output_dir::String)

Parses the medline xml file into a dictionary of dataframes. Saves the resulting CSV files to medline/parsed_files.
"""
function parse_ml_file(fname::String, output_dir::String)
    println("Parsing file: ", fname)

    parsed_path = joinpath(output_dir,"medline","parsed_files","$(fname[1:end-7])_basic.csv")
    if isfile(parsed_path)
        resp = "File already exists, using local file"
    else
        path = joinpath(output_dir,"medline","raw_files",fname)
        doc = parse_file(path)
        raw_articles = root(doc)

        dfs = PubMed.parse(raw_articles)

        dfs_to_csv(dfs, joinpath(output_dir,"medline","parsed_files"), "$(fname[1:end-7])_")

        free(doc)
    end

    return nothing
end

"""
    close_cons(ftp_con)
closes connection and cleans up
"""
function close_cons(ftp_con::ConnContext)
    # Close FTP Connection
    ftp_close_connection(ftp_con)
    ftp_cleanup()

    return nothing
end

# Commented out as this requires database priveleges that aren't common
# """
#     post_process!(conn)
#
# Creates an article2author and author table.  The author table has unique identifiers for every combination of last_name, first_name, initials, suffix, orcid, collective, and affiliation.  The article2author table provides a mapping from PMIDs to these unique authors.
# """
# function post_process!(conn::MySQL.Connection)
#
#     PubMed.create_post_tables!(conn)
#
#     a = db_query(conn, "select count(*) from author_ref")
#
#     num_a = a[1,1]
#
#     info("==============Processing ", num_a, " article/author entries==============")
#
#     set_innodb_checks!(conn,0,0,0)
#
#     println("Inserting into author table")
    # MySQL.execute!(conn, """
    #     select distinct sql_big_result last_name, first_name, initials, suffix, orcid, collective, affiliation
    #     from author_ref
    #     into dumpfile 'medline_author_dump';""")
    #
    # MySQL.execute!(conn, """load data infile 'medline_author_dump'
    #     into author;""")
    #
    # println("Inserting into author2article table")
    # MySQL.execute!(conn, """insert into author2article
    #     (pmid, auth_id)
    #     select distinct sql_big_result ar.pmid, a.auth_id
    #     from author_ref ar, author a
    #     where (ar.last_name = a.last_name or (ar.last_name is null and a.last_name is null))
    #     and (ar.first_name = a.first_name or (ar.first_name is null and a.first_name is null))
    #     and (ar.initials = a.initials or (ar.initials is null and a.initials is null))
    #     and (ar.suffix = a.suffix or (ar.suffix is null and a.suffix is null))
    #     and (ar.orcid = a.orcid or (ar.orcid is null and a.orcid is null))
    #     and (ar.collective = a.collective or (ar.collective is null and a.collective is null))
    #     and (ar.affiliation = a.affiliation or (ar.affiliation is null and a.affiliation is null))
    #     ;""")
#
#     set_innodb_checks!(conn)
#     add_mysql_keys!(conn)
#
#     return nothing
# end
