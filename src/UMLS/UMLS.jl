module UMLS

using Gumbo
using Requests
import Requests: post, get

export Credentials, search_umls, best_match_cui, get_semantic_type

const uri="https://utslogin.nlm.nih.gov"
const auth_endpoint = "/cas/v1/tickets/"
const service="http://umlsks.nlm.nih.gov"
const rest_uri = "https://uts-ws.nlm.nih.gov"

"""
    Credentials(user, psswd)
"""
type Credentials
    "username"
    username::ASCIIString
    "password"
    password::ASCIIString
end

# Request  ticket granting ticket (tgt) using login credentials
function get_tgt(c::Credentials)
    params = Dict("username" => c.username, "password"=> c.password)
    headers = Dict("Content-type"=> "application/x-www-form-urlencoded",
    "Accept"=> "text/plain", "User-Agent"=>"julia" )
    r = post(uri*auth_endpoint,data=params,headers=headers)
    ascii_r = ASCIIString(r.data)

    doc = parsehtml(ascii_r)
    #for now - harcoded
    #TO DO:: parse and check
    ticket = getattr(doc.root.children[2].children[2], "action")
    return ticket
end


# Get ticket from tgt
function get_ticket(ticket)
    params = Dict("service"=> service)
    h = Dict("Content-type"=> "application/x-www-form-urlencoded",
    "Accept"=> "text/plain", "User-Agent"=>"julia" )
    r = post(ticket;data=params,headers=h)
    return ASCIIString(r.data)
end

"""
    search_umls(c::Credentials, query)

Search UMLS Rest API. For more info see
[UMLS_API](https://documentation.uts.nlm.nih.gov/rest/search/)


###Arguments

- `c::Credentials`: UMLS username and password
- `query`: UMLS query containing the search term

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
term = "obesity"
query = Dict("string"=>term, "searchType"=>"exact" )
all_results= search_umls(credentials, query)
```
"""
function search_umls(c::Credentials, query)

    # Ticket granting ticket
    tgt = get_tgt(c)
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
        ticket = get_ticket(tgt)
        page +=1
        #append ticket to query
        query["ticket"]= ticket
        query["pageNumber"]= @sprintf("%d", page)
        r = get(rest_uri*content_endpoint, query=query)
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
cui = "C0028754"
sm = BioMedQuery.UMLS.get_semantic_type(credentials, cui)
```
"""
function get_semantic_type(c::Credentials, cui)
    # Ticket granting ticket
    tgt = get_tgt(c)
    content_endpoint = "/rest/content/current/CUI/"*cui
    #get a new ticket
    ticket = get_ticket(tgt)
    r = get( rest_uri*content_endpoint,query=Dict("ticket"=> ticket))

    json_response = Requests.json(r)
    st = json_response["result"]["semanticTypes"]
    concepts = Array{ASCIIString}(length(st))
    for (ci, concept) in enumerate(st)
        concepts[ci] =concept["name"]
    end

    return concepts
end

end
