# Interface to NCBI Entrez utilities
# http://www.ncbi.nlm.nih.gov/books/NBK25497/
# Date: May 6, 2016
# Authors: Isabel Restrepo, Paul Stey
# BCBI - Brown University
# Version: Julia 0.4.5
using Requests
using LightXML
using HttpCommon

using  XMLconvert

# Helper function to build the url and open a handle to it
# Uses HTTP POST instead of GET for long queries
function open_entrez(cgi, params, post=false)
    if get(params, "tool", "") == ""
        params["tool"] = "BioJulia"
    end
    if get(params, "email", "") == ""
        error("Email address is required to search Entrez")
    end
    #open a handle to Entrez
    if post
        response = Requests.post(cgi; data=params)

    else
        response = Requests.get(cgi; query=params)
    end

    println("NCBI Response: ", STATUS_CODES[response.status])

    if response.status != 200
        error("Bad response from NCBI ENTREZ")
    end

    # convert binary xml data to ascii
    return String(response.data)
end


"""
    esearch(search_dict)

Request list of UIDs matiching a query - see [NCBI Entrez:Esearch](http://www.ncbi.nlm.nih.gov/books/NBK25499/#chapter4.ESearch)

###Arguments

* `search_dic::Dict`: dictionary specifying search criteria

###Output

* `::String`: XML response from NCBI

###Example

```julia
search_dic = Dict("db"=>"pubmed", "term" => search_term,
"retstart" => 0, "retmax"=>5, "tool" =>"BioJulia",
"email" => "email")
esearch_response = esearch(search_dic)
```

###Note

* email must be a valid email address (otherwise pubmed will block you)
* search_term corresponds to a valid [PubMed Search](http://www.ncbi.nlm.nih.gov/pubmed/advanced). It may contain one or more filtering criteria using AND/OR.
For instance:

`search_term = (asthma[MeSH Terms]) AND ("2001/01/29"[Date - Publication] : "2010"[Date - Publication])`.

"""
function esearch(search_dic)
    # Seach Entrez database
    cgi = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi"
    variables = Dict("db"=>"db")
    variables = merge(variables, search_dic)
    # return variables
    return open_entrez(cgi, variables, false)
end


"""
    efetch(fetch_dic, id_list)

Retrieve data records from a list of UIDs - see [NCBI Entrez: EFetch](http://www.ncbi.nlm.nih.gov/books/NBK25499/#chapter4.EFetch)

###Arguments

* `fetch_dic::Dict` - Dictionary specifying fetch criteria
* `id_list::Array` - List of ids e.g those embedded in response from esearch

###Results

* `::String` - XML response from NCBI

###Example

```julia
# get the list of ids
if !haskey(esearch_dict, "IdList")
  error("Error: IdList not found")
end

ids = []

for id_node in esearch_dict["IdList"][1]["Id"]
  push!(ids, id_node)
end

# define the fetch dictionary
fetch_dic = Dict("db"=>"pubmed","tool" =>"BioJulia",
"email" => email, "retmode" => "xml", "rettype"=>"null")

# fetch
efetch_response = efetch(fetch_dic, ids)
```

"""
function efetch(fetch_dic, id_list)
    post = false
    cgi = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi"
    # NCBI prefers an HTTP POST instead of an HTTP GET if there are
    # more than about 200 IDs
    if length(id_list) > 200
        post = true
    end
    id_list = join(id_list,",")
    variables = Dict("id"=>id_list)
    variables = merge(variables, fetch_dic)
    return open_entrez(cgi, variables,  post)
end


"""
    elink(elink_dict)

Lists, checks or returns UIDs linked to an input list of UIDs in the same or
different Entrez database. For more info see
[NCBI Entrez:ELink](http://www.ncbi.nlm.nih.gov/books/NBK25499/#chapter4.ELink)

###Arguments

* `elink_dict::Dict`: dictionary specifying elink inputs as credentials, ids...

###Output

* `::String`: XML response from NCBI

###Example

```julia
pmid = "19304878"
elink_dict = Dict("dbfrom" =>"pubmed", "id" => pmid,
                  "linkname" => "pubmed_pubmed", "email"=>email)
elink_response = elink(elink_dict)
```
"""

function elink(elink_dict)
    cgi = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/elink.fcgi"
    return open_entrez(cgi, elink_dict)
end

"""
    esummary(esummary_dict)

Return document summaries for a list of input UIDs. For more info see
[NCBI Entrez:ESummary](http://www.ncbi.nlm.nih.gov/books/NBK25499/#chapter4.ESummary)

###Arguments

* `esummary_dict::Dict`: dictionary specifying esummary inputs as credentials, ids...

###Output

* `::String`: XML response from NCBI

###Example

```julia
pmid = "30367"
esummary_dict = Dict("db" =>"pubmed", "id" => pmid, "email"=>email)
esummary_response = esummary(esummary_dict)
```
"""
function esummary(esummary_dict)
    cgi = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi"
    return open_entrez(cgi, esummary_dict)
end

"""
    eparse(response::String)

Converts NCBI XML response into a Julia dictionary

"""
function eparse(ncbi_response::String)
    xdoc = parse_string(ncbi_response)
    # get the root element
    xroot = root(xdoc)  # an instance of XMLElement
    # get all child nodes and append to dictionary
    node_element = xroot
    #convert attributes to elements
    attributes_to_elements!(xroot)
    #convert to a dictionary
    dict = xml2dict(xroot)
    return dict
end


"""
    eparse_from_file(xml_file::String)

Converts NCBI XML (previously saved) file into a Julia dictionary

"""
function eparse_from_file(xml_file::String)
    xdoc = parse_file(xml_file)
    # get the root element
    xroot = root(xdoc)  # an instance of XMLElement
    # get all child nodes and append to dictionary
    node_element = xroot
    #convert attributes to elements
    attributes_to_elements!(xroot)
    #convert to a dictionary
    dict = xml2dict(xroot)
    return dict
end
