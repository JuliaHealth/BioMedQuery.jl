# Interface to Clinical Trials Database
# https://clinicaltrials.gov/
# Date: May 16, 2016
# Author: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5
module CT

using Requests
using HttpCommon
export search_ct

@enum AgeGroup child=0 adult=1 senior=2
# Submit a search to clinicaltrials.gov
# The query corresponds to a dictionary containing the search criteria.
# The fout must be a .zip file and the parent directory must exist
# If results is true, both the study xml and the results of the study (if available),
# are stored

# Example query
# query = Dict("term" => "acne", "age"=>Int(child),
                # "locn" => "Providence, RI")
# The term can also indicate joint searches, e.g.
# "term" => "aspirin OR ibuprofen"

# For more information on possible searche critiria see:
 # https://clinicaltrials.gov/ct2/search/advanced
function search_ct(query, fout; results=false)

    ext = splitext(fout)[2]
    if  !isequal(ext,".zip")
        println("Error: Output file must have a .zip extension")
        exit(-1)
    end

    uri="https://clinicaltrials.gov/search"

    #Specify whether to return the study or study and results
    #They are mutually exclusive tags
    if (results)
        query["resultsxml"] =true
        if haskey(query, "studyxml")
            delete!(query, "studyxml")
        end
    else
        println("Not saving result files")
        query["studyxml"] =true
        if haskey(query, "resultsxml")
            delete!(query, "resultsxml")
        end
    end

    println("Getting request")
    response = Requests.get(uri, query=query)

    println("Clinical Trials Response: ", STATUS_CODES[response.status])

    if response.status != 200
        error("Bad response from clinicaltrials.gov")
    end

    #Save xml files to disk
    save(response, fout)

    return response.status
end


end
