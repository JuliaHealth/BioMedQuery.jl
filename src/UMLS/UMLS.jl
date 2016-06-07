module UMLS

  using Gumbo
  using Requests
  import Requests: post, get

  export Credentials, search_umls, best_match_cui, get_concepts

  const uri="https://utslogin.nlm.nih.gov"
  const auth_endpoint = "/cas/v1/tickets/"
  const service="http://umlsks.nlm.nih.gov"
  const rest_uri = "https://uts-ws.nlm.nih.gov"

  type Credentials
    username::ASCIIString
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

  # Search UMLS Rest API
  # Input query is expected to be a dictionary using query parametres
  # specified by UMLS_API https://documentation.uts.nlm.nih.gov/rest/search/
  function search_umls(c::Credentials, query, version="current")

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

  #Retrieve the id for the top match
  function best_match_cui(result_pages, term)
      # if (term == normalize_string(result["name"], casefold=true))
      return result_pages[1]["result"]["results"][1]["ui"]
  end

  #Get umls concepts (semantic types) associated with a cui
  function get_concepts(c::Credentials, cui)
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
