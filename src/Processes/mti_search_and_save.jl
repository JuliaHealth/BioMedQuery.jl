using BioMedQuery.MTI

function mti_search_and_save(config, main_func = parse_and_save_default_MTI; append_results=false, verbose= false, num_cols = 9, num_cols_prc = 4)

    println("*-------------This is: mti_search_and_save-------------------*")

    # make sure all keys are present
    keys = [:email, :db, :pub_year, :mti_query_file, :mti_result_file]

    if reduce(+, map(x -> haskey(config, x), keys)) != length(keys)
        error("Incorrect configuration for mti_search_and_save")
    end

    # easy refernces
    email = config[:email]
    username = config[:uts_user]
    password = config[:uts_psswd]
    db = config[:db]
    pub_year = config[:pub_year]
    mti_query_file = config[:mti_query_file]
    mti_result_file = config[:mti_result_file]
    use_local_medline = config[:local_medline]


    # write abstracts to quey file
    abstracts_to_request_file(db, pub_year, mti_query_file; local_medline = use_local_medline)

    # submit query file to batch processing
    generic_batch(email, username, password, mti_query_file, mti_result_file)

    #save to Database
    main_func(mti_result_file, db; num_cols = num_cols, num_cols_prc = num_cols_prc, append_results=append_results, verbose= verbose)

end
