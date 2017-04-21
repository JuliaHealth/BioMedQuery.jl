using Gumbo
using Requests
using HttpCommon

const uri="https://utslogin.nlm.nih.gov"
const auth_endpoint = "/cas/v1/tickets/"
const service="http://umlsks.nlm.nih.gov"
const rest_uri = "https://uts-ws.nlm.nih.gov"

immutable BadResponseException <: Exception
    code::Int64
end

function Base.showerror(io::IO, e::BadResponseException)
    print(io, "BadResponseException with code: ",STATUS_CODES[e.code])
end

"""
    Credentials(user, psswd)
"""
type Credentials
    "username"
    username::String
    "password"
    password::String
end

function time_to_last_save(file)
    #unix time is GMT
    time_diff = Int(Dates.unix2datetime(time()) - Dates.unix2datetime(mtime(file)))/ (1000 * 60 * 60)
    return time_diff
end

"""
    get_tgt(c::Credentials)

Retrieve a ticket granting ticket (TGT) using UTS login credentials
A tgt is valid for 8 hours. Therefore, look for UTS_TGT.txt in the local
directory to see if it has been recently stored.
"""
function get_tgt(c::Credentials)
    # Commented out due to old TGT not working
    # Check if there is a valid ticket on disk
    TGT_file = "UTS_TGT.txt"
    if isfile(TGT_file)
        #check time
        time_elapsed = time_to_last_save(TGT_file)
        # Expiration time should be 8 hours - but I tend to expirience bad TGT after few hours
        if time_elapsed > 1
            println("UTS TGT Expired")
            rm(TGT_file)
        else
            # println("Using TGT from disk - saved ", time_elapsed, " hours ago")
            fin = open(TGT_file)
            lines = readlines(fin)
            ticket = lines[1]
            return ticket
        end

    end

    println("Requesting new TGT")
    params = Dict("username" => c.username, "password"=> c.password)
    headers = Dict("Content-type"=> "application/x-www-form-urlencoded",
    "Accept"=> "text/plain", "User-Agent"=>"julia" )
    r = post(uri*auth_endpoint,data=params,headers=headers)
    ascii_r = String(r.data)

    doc = parsehtml(ascii_r)
    #for now - harcoded
    #TO DO:: parse and check
    try
        ticket = getattr(doc.root.children[2].children[2], "action")
        return ticket
    catch
        error("Could not get TGT: UTS response structure is wrong")
    end
    fout = open(TGT_file, "w")
    write(fout, ticket)
end


"""
    get_ticket(tgt)

Retrieve a single-use Service Ticket using TGT
"""
function get_ticket(TGT)
    params = Dict("service"=> service)
    h = Dict("Content-type"=> "application/x-www-form-urlencoded",
    "Accept"=> "text/plain", "User-Agent"=>"bcbi-julia" )
    r = HttpCommon.Response(503)
    try
        r = post(TGT; data=params, headers=h)
    catch
        error("UMLS POST error: ", STATUS_CODES[r.code])
    end
    return String(r.data)
end

"""
    search_umls(c::Credentials, query)

Search UMLS Rest API. For more info see
[UMLS_API](https://documentation.uts.nlm.nih.gov/rest/search/)


###Arguments

- `c::Credentials`: UMLS username and password
- `query`: UMLS query containing the search term
- `version:` Optional - defaults to current

###Output

- `result_pages`: Array, where each entry is a dictionary containing a page of
results. e.g
 ```Dict{AbstractString,Any} with 3 entries:
  "pageSize"   => 25
   "pageNumber" => 1
  "result"     => Dict{AbstractString,Any}("classType"=>"searchResults","result…
  ```

###Examples

```julia
credentials = Credentials(user, psswd)
tgt = get_tgt(credentials)
term = "obesity"
query = Dict("string"=>term, "searchType"=>"exact" )
all_results= search_umls(tgt, query)
```
"""
function search_umls(tgt, query; version::String="current", timeout=1)

    # Ticket granting ticket
    if tgt == nothing
        tgt = get_tgt(c)
    end
    page=0

    content_endpoint = "/rest/search/current"

    #each page of results is appended to the output list
    #where each entry is a dictionary containing that pages's results
    # e.g
    # Dict{AbstractString,Any} with 3 entries:
    #   "pageSize"   => 25
    #   "pageNumber" => 1
    #   "result"     => Dict{AbstractString,Any}("classType"=>"searchResults","result…
    result_pages = Array{Any,1}()

    while true

        #get a new ticket per page if necessary
        ticket = ""
        try
            ticket = get_ticket(tgt)
        catch err
            rethrow(err)
        end

        page +=1
        #append ticket to query
        query["ticket"]= ticket
        query["pageNumber"]= @sprintf("%d", page)

        r = get(rest_uri*content_endpoint, query=query, timeout=timeout)

        if r.status != 200
            error("Bad HTTP status $(r.status)")
        end

        json_response = Requests.json(r)
        # println("No Results ", length(json_response["result"]["results"]))
        if json_response["result"]["results"][1]["ui"]=="NONE"
            break
        end
        push!(result_pages,json_response)
    end

    return result_pages

end

"""
    best_match_cui(result_pages)

Retrive the best match from array of all result pages

###Example

```julia
cui = BioMedQuery.UMLS.best_match_cui(all_results)
```
"""
function best_match_cui(result_pages)
    return result_pages[1]["result"]["results"][1]["ui"]
end

"""
    get_semantic_type(c::Credentials, cui)

Return an array of the semantic types associated with a cui

###Example

```julia
credentials = Credentials(user, psswd)
tgt = get_tgt(credentials)
cui = "C0028754"
sm = BioMedQuery.UMLS.get_semantic_type(tgt, cui)
```
"""
function get_semantic_type(tgt, cui)

    content_endpoint = "/rest/content/current/CUI/"*cui
    #get a new ticket
    ticket = ""
    try
        ticket = get_ticket(tgt)
    catch err
        rethrow(err)
    end

    r = HttpCommon.Response(503)
    try
        r = get( rest_uri*content_endpoint,query=Dict("ticket"=> ticket))
    catch
        isdefined(r, :code) ? error("UMLS GET error: ", r.code) : error("UMLS COULD NOT GET")
    end

    json_response = Requests.json(r)
    st = json_response["result"]["semanticTypes"]
    concepts = Array{String}(length(st))
    for (ci, concept) in enumerate(st)
        concepts[ci] =concept["name"]
    end

    return concepts
end
