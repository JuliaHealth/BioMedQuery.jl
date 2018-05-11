using MySQL
using FTPClient
using BioMedQuery.PubMed
using BioMedQuery.DBUtils
using EzXML
using DataFrames

"""
    load_medline(mysql_host, mysql_user, mysql_pwd, mysql_db; start_file = 1, end_file = 928, overwrite = true, year=2018)

Given MySQL connection info and optionally the start and end files, fetches the medline files, parses the xml, and loads into a MySQL DB (assumes tables already exist).
"""
function load_medline(mysql_host::String, mysql_user::String, mysql_pwd::String, mysql_db::String, output_dir::String; start_file::Int = 1, end_file::Int = 928, overwrite::Bool=true, year::Int=2018)

    db_con, ftp_con = init_medline(mysql_host, mysql_user, mysql_pwd, mysql_db, output_dir, overwrite)

    set_innodb_checks!(db_con,0,0,0)
    drop_mysql_keys!(db_con)


    info("Getting files from Medline")
    @sync for n = start_file:end_file
        @async get_ml_file(get_file_name(n, year), ftp_con, output_dir)
    end

    info("Parsing files into CSV")
    pmap(x -> parse_ml_file(get_file_name(x, year), output_dir), start_file:end_file)

    info("Loading CSVs into MySQL")
    @sync for n = start_file:end_file
        println("Loading file ", n)

        fname = get_file_name(n, year) ::String
        csv_prefix = "$(fname[1:end-7])_"
        csv_path = joinpath(output_dir,"medline","parsed_files")

        @async db_insert!(db_con, csv_path, csv_prefix)
    end

    set_innodb_checks!(db_con)
    add_mysql_keys!(db_con)
    info("All files processed - closing connections")
    close_cons(db_con, ftp_con)

    return nothing
end

"""
    init(mysql_host::String, mysql_user::String, mysql_pwd::String, mysql_db::String, overwrite::bool)

Sets up environment (folders), and connects to MySQL DB and FTP Server returns these connections.
"""
function init_medline(mysql_host::String, mysql_user::String, mysql_pwd::String, mysql_db::String, output_dir::String, overwrite::Bool)
    ## SET UP ENVIRONMENT
    info("======Setting up folders and creating FTP, DB Connections======")

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

    # Get MySQL Connection
    db_con = init_mysql_database(mysql_host, mysql_user, mysql_pwd, mysql_db, overwrite)

    ftp_con = get_ftp_con()

    overwrite && PubMed.create_tables!(db_con)

    return db_con, ftp_con
end



"""
    get_file_name(fnum::Int, year::Int = 2018)
Returns the medline file name given the file number.
"""
function get_file_name(fnum::Int, year::Int)
    nstr = lpad(fnum,4,0) # pad iterator with leading zeros so total length is 4
    y2 = string(year)[3:4]
    return "pubmed$(y2)n$nstr.xml.gz"
end

"""
    get_ml_file(fname::String, conn::ConnContext)

Retrieves the file with fname /files.  Returns the HTTP response.
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
    get_ftp_con()
Get an FTP connection
"""
function get_ftp_con()
    options = RequestOptions(url="ftp://ftp.ncbi.nlm.nih.gov/pubmed/baseline/")
    conn = ftp_connect(options) # returns connection and response
    return conn[1]# get ConnContext object
end

"""
    parse_ml_file(fname::String)

Parses the medline xml file into a dictionary of dataframes
"""
function parse_ml_file(fname::String, output_dir::String)
    println("Parsing file: ", fname)
    doc = EzXML.readxml(joinpath(output_dir,"medline","raw_files",fname))
    raw_articles = EzXML.root(doc)

    dfs = pubmed_to_dfs(raw_articles)

    dfs_to_csv(dfs, joinpath(output_dir,"medline","parsed_files"), "$(fname[1:end-7])_")

    return nothing
end

"""
    close_cons(db_con, ftp_con)
closes connections and cleans up
"""
function close_cons(db_con::MySQL.Connection, ftp_con::ConnContext)
    # Close FTP Connection
    ftp_close_connection(ftp_con)
    ftp_cleanup()

    # Close MySQL Connection
    MySQL.disconnect(db_con)

    return nothing
end
