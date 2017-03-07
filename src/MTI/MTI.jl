using BioMedQuery.Entrez.DB
using BioMedQuery.DBUtils
using DataArrays

function install_web_api( clean_install = false)
    root_dir= string(Pkg.dir() , "/BioMedQuery/src/MTI/IIWebAPI")

    if !isdir(root_dir)
        mkdir(root_dir)
    end

    cd(root_dir)

    if clean_install
        println("Dowloading fresh copy of sources")
        # get sources and expand
        download("https://ii.nlm.nih.gov/Web_API/SKR_Web_API_V2_3.jar", "./SKR_Web_API_V2_3.jar")
        run(`java sun.tools.jar.Main xf SKR_Web_API_V2_3.jar`)
    end

    # compile
    cd("SKR_Web_API_V2_3")
    run(`chmod +x ./compile.sh ./run.sh ./build.sh`)
    run(`./compile.sh ../../GenericBatchCustom.java`)

end

function generic_batch(email, username, password, in_file, out_file)
    root_dir= string(Pkg.dir() , "/BioMedQuery/src/MTI")
    cd(root_dir)
    run(`./generic_batch.sh $email $username $password $in_file $out_file`)
end


"""
    abs_to_request_file(pub_year)

Write all abstracts in a year, to a file to be used for MTI batch query.
The format is:

UI - pmid
AB - abstract_text
"""
function abstracts_to_request_file(db, pub_year, out_file; local_medline = false)
    abs_sel = abstracts_by_year(db, pub_year; local_medline = local_medline)

    #call MTI
    open(out_file, "w") do file

        for i=1:size(abs_sel)[1]
            pmid = abs_sel[i, :pmid]
            abstract_text = abs_sel[i, :abstract_text]

            if isna(abstract_text)
                println( "Skipping empty abstract for PMID: ", pmid)
                continue
            end
            # convert to ascii - all unicode caracters to " "
            abstract_ascii = replace(abstract_text, r"[^\u0000-\u007F]", " ")
            write(file, "UI  - $pmid \n")
            write(file, "AB  - $abstract_ascii \n \n")
        end
    end

end

function parse_and_save_MoD(file, db; num_cols = 9, num_cols_prc = 4, append_results=false, verbose= false)
    mesh_lines, prc_lines = parse_result_file(file, num_cols, num_cols_prc)
    println("Saving ", length(mesh_lines), " mesh entries")
    save_MoD(db, mesh_lines, prc_lines; append_results=append_results, verbose= verbose)
end

function parse_and_save_default_MTI(file, db; num_cols = 8, num_cols_prc = 10000, append_results=false, verbose= false)
    mesh_lines, prc_lines = parse_result_file(file, num_cols, num_cols_prc)
    println("Saving ", length(mesh_lines), " mesh entries")
    save_default_MTI(db, mesh_lines; append_results=append_results, verbose= verbose)
end


function parse_result_file(file, num_cols = 9, num_cols_prc = 4)
    mesh_lines = []
    prc_lines =[]
    open(file, "r") do f
        lines = eachline(f)
        for line in lines
            entries = split(chomp(line), "|")
            if length(entries) == num_cols
                push!(mesh_lines, entries)
            elseif length(entries) == num_cols_prc
                push!(prc_lines, entries)
            end
        end
    end
    return mesh_lines, prc_lines
end

function init_MoD_tables(db, append_results = false)

    query_str ="CREATE TABLE IF NOT EXISTS mti (
                    term VARCHAR(255),
                    dui INT,
                    pmid INT,
                    cui INT,
                    score INT,
                    term_type CHAR(2),

                    PRIMARY KEY(pmid, term)
                );
                CREATE TABLE IF NOT EXISTS mti_prc  (
                                pmid INT,
                                prc_pmid INT,

                                PRIMARY KEY(pmid, prc_pmid)
                 );
                 "


    # FOREIGN KEY (term, dui)
    #   REFERENCES mesh_descriptor(name, id),
    db_query(db, query_str)

    #clear the relationship table
    if !append_results
        db_query(db, "DELETE FROM mti")
    end
end


function init_default_MTI_tables(db, append_results = false)

    query_str ="CREATE TABLE IF NOT EXISTS mti (
                    term VARCHAR(255),
                    dui INT,
                    pmid INT,
                    cui INT,
                    score INT,
                    term_type CHAR(2),

                    PRIMARY KEY(pmid, term)
                );
                "


    # FOREIGN KEY (term, dui)
    #   REFERENCES mesh_descriptor(name, id),
    db_query(db, query_str)

    #clear the relationship table
    if !append_results
        db_query(db, "DELETE FROM mti")
    end
end
function save_MoD(db, mesh_lines, prc_lines; append_results=false, verbose= false)
    init_MoD_tables(db, append_results)

    for ml in mesh_lines

        dui = parse(Int64, ml[9][2:end])  #remove preceding D
        cui = parse(Int64, ml[3][2:end])  #remove preceding C

        insert_row!(db, "mti",
                    Dict(:pmid =>ml[1],
                         :term => ml[2],
                         :cui=>cui,
                         :score=>ml[4],
                         :term_type=> ml[5],
                         :dui=>dui), verbose)

    end

    for prc in prc_lines
        prc_pmids = split(prc[3], ';')
        for id in prc_pmids
            insert_row!(db, "mti_prc",
                        Dict(:pmid =>prc[1],
                             :prc_pmid=>id), verbose)
        end
    end

end


function save_default_MTI(db, mesh_lines; append_results=false, verbose= false)

    init_default_MTI_tables(db, append_results)

    for ml in mesh_lines

        cui = parse(Int64, ml[3][2:end])  #remove preceding C

        insert_row!(db, "mti",
                    Dict(:pmid =>ml[1],
                         :term => ml[2],
                         :cui=>cui,
                         :score=>ml[4],
                         :term_type=> ml[5]), verbose)

    end

end
