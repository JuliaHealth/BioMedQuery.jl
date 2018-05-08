using MySQL
using FTPClient
using CSV
using LightXML
using BioMedQuery.PubMed
using EzXML
using DataFrames

"""
    load_medline(mysql_host, mysql_user, mysql_pwd, mysql_db; start_file = 1, [end_file], create_tables = true, year=2018)

Given MySQL connection info and optionally the start and end files, fetches the medline files, parses the xml, and loads into a MySQL DB (assumes tables already exist).
"""
function load_medline(mysql_host::String, mysql_user::String, mysql_pwd::String, mysql_db::String; start_file::Int = 1, end_file::Int = 928, create_tables::Bool=true, year::Int=2018)

    db_con, ftp_con = init_medline(mysql_host, mysql_user, mysql_pwd, mysql_db, create_tables)

    # Set start file number
    n = start_file
    file_exists = true

    # df_articles = Dict{Symbol,DataFrame}
    dfs = Dict{String,DataFrame}()

    for n = start_file:end_file

        info("======Processing medline file #", n, "======")
        fname = get_file_name(n, year)

        try
            fileresp = get_ml_file(fname, ftp_con)
            println("Found file #", n, ": ",fname)
        catch e
            run(`rm medline/raw_files/$fname`)
            if e.lib_curl_error == 78
                file_exists = false
                warn("File #", n, " doesn't exists - ending program")
            else
                warn("Problem downloading file ", n, " - removing and moving on")
            end
            break
        end

        doc = EzXML.readxml(joinpath("medline/raw_files",fname))

        raw_articles = EzXML.root(doc)

        csv_prefix = "test_"
        csv_path = "medline/parsed_files"

        try
            dfs = pubmed_to_csv(raw_articles, csv_prefix, csv_path)
        catch e
            return e, catch_stacktrace()
        end

        n += 1
    end

    info("All files processed - closing connections")
    # Close FTP Connection
    ftp_close_connection(ftp_con)
    ftp_cleanup()

    # Close MySQL Connection
    MySQL.disconnect(db_con)

    return dfs
end

"""
    init(mysql_host::String, mysql_user::String, mysql_pwd::String, mysql_db::String)

Sets up environment (folders), and connects to MySQL DB and FTP Server returns these connections.
"""
function init_medline(mysql_host::String, mysql_user::String, mysql_pwd::String, mysql_db::String, create_tables::Bool)
    ## SET UP ENVIRONMENT
    info("======Setting up folders and creating FTP, DB Connections======")

    try
        mkdir(joinpath(pwd(),"medline"))
    catch
        println("medline directory already exists")
    end

    try
        mkdir(joinpath("pwd","medline","raw_files"))
        mkdir(joinpath("pwd","medline","parsed_files"))
    catch
        println("files directories already exists")
    end

    # Initialize FTP
    ftp_init()
    options = RequestOptions(url="ftp://ftp.ncbi.nlm.nih.gov/pubmed/baseline/")

    conn = ftp_connect(options) # returns connection and response
    ctxt = conn[1] # get ConnContext object

    # Get MySQL Connection
    db_con = MySQL.connect(mysql_host, mysql_user, mysql_pwd, db = mysql_db)

    if create_tables
        PubMed.create_tables!(db_con, true)
    end

    return db_con, ctxt
end

"""
    get_ml_file(fname::String, conn::ConnContext)

Retrieves the file with fname /files.  Returns the HTTP response.
"""
function get_ml_file(fname::String, conn::ConnContext)

    # get file
    if isfile("medline/raw_files/"*fname)
        resp = "File already exists, using local file"
    else
        resp = ftp_get(conn, fname, "medline/raw_files/"*fname)
    end

    return resp
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
    load_ml_file(fname::AbstractString, conn::MySQL.Connection)

Loads the localhost medline tables for the filename passed.
"""
function load_ml_file(fname::AbstractString, conn::MySQL.Connection)

    #Insert file name into files_meta talbe
    meta_sql = """INSERT INTO file_meta (file_name,ins_start_time) VALUES ('$fname',CURRENT_TIMESTAMP)"""
    nrows = MySQL.execute!(conn, meta_sql)

    table_names = ["basic", "author", "pub_type", "abstract_full", "abstract_structured", "mesh_heading", "mesh_desc", "mesh_qual"]

    ins_sql = ""
    for table in table_names
        path = "medline/parsed_files/$(fname[1:end-7])_$(table)_table.csv"
        headers = CSV.read(path, rows = 1, datarow=1)
        # return headers

        cols = ""
        for i = 1:length(headers)
            @inbounds cols *= headers[1,i]*","
        end
        cols = cols[1:end-1]

        ins_sql = """LOAD DATA LOCAL INFILE '$path' INTO TABLE $table CHARACTER SET latin1 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES ($cols)"""
        nrows = MySQL.execute!(conn, ins_sql)

    end

    meta_sql = """UPDATE file_meta SET ins_end_time = CURRENT_TIMESTAMP WHERE file_name = '$fname'"""
    nrows = MySQL.execute!(conn, meta_sql)

    return nothing

end
