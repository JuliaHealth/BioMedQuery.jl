using BioMedQuery.MTI

function mti_search_and_save(config)

    println("*-------------This is: mti_search_and_save-------------------*")

    # make sure all keys are present
    keys = [:email, :db, :pub_year, :mti_query_file, :mti_result_file]

    if reduce(+, map(x->haskey(config, x), keys)) != length(keys)
        error("Incorrect configuration for mti_search_and_save")
    end

    # easy refernces
    email = config[:email]
    db = config[:db]
    pub_year = config[:pub_year]
    mti_query_file = config[:mti_query_file]
    mti_result_file = config[:mti_result_file]


    # write abstracts to quey file
    abstracts_to_request_file(db, pub_year, mti_query_file)

    # submit query file to batch processing
    generic_batch(email, mti_query_file, mti_result_file)

    #save to Database
    parse_and_save_results(mti_result_file, db)

end
