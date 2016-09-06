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
    return ASCIIString(response.data)
end


"""
    esearch(search_dict)

Request list of UIDs matiching a query - see [NCBI Entrez:Esearch](http://www.ncbi.nlm.nih.gov/books/NBK25499/#chapter4.ESearch)

###Arguments

* `search_dic::Dict`: dictionary specifying search criteria

###Output

* `::ASCIIString`: XML response from NCBI

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

* `::ASCIIString` - XML response from NCBI

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

* `::ASCIIString`: XML response from NCBI

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

* `::ASCIIString`: XML response from NCBI

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
    eparse(response::ASCIIString)

Converts NCBI XML response into a Julia dictionary

"""
function eparse(ncbi_response::ASCIIString)
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


# """
#     save_efetch(efetch_dict, db_path)
#
# Save the results (dictionary) of an entrez fetch to a SQLite database.
#
# ####Note:
#
# It is best to assure the databese file does not exist. If the file
# path corresponds to an exixting database, the system
# attempts to use that database, which must contain the correct tables.
#
# ###Example
#
# ```julia
# #SQLite example
# db_backend("SQLite")
# db_config = Dict(:db_path=>"test_db.slqite", :overwrite=>true)
# db = save_efetch(efetch_dict, db_config)
# ```
#
# """
# function save_efetch(efetch_dict, db_config)
#     #init database with its structure only if file doesn't exist
#     db = DB.init_database(db_config)
#
#     if !haskey(efetch_dict, "PubmedArticle")
#         println("Error: Could not save to DB key:PubmedArticleSet not found")
#         return
#     end
#     articles = efetch_dict["PubmedArticle"]
#
#     #articles should be an array
#     if !isa(articles, Array{Any, 1})
#         println("Error: Could not save to DB articles should be in an Array")
#         return
#     end
#
#     println("Saving " , length(articles) ,  " articles to database")
#
#     for article in articles
#
#         if !haskey(article,"MedlineCitation")
#             println("Error: Could not save to DB key:MedlineCitation not found")
#             return
#         end
#
#         pmid = DB.NULL[_db_backend[1]];
#         title = DB.NULL[_db_backend[1]];
#         pubYear = DB.NULL[_db_backend[1]];
#
#
#         # PMID is used as primary key - therefore it must be present
#         if haskey(article["MedlineCitation"][1],"PMID")
#             pmid = article["MedlineCitation"][1]["PMID"][1]["PMID"][1]
#         else
#             println("Error: Could not save to DB key:PMID not found - cannot be NULL")
#             return
#         end
#
#         # Retrieve basic article info
#         if haskey(article["MedlineCitation"][1],"Article")
#             if haskey(article["MedlineCitation"][1]["Article"][1], "ArticleTitle")
#                 title = article["MedlineCitation"][1]["Article"][1]["ArticleTitle"][1]
#             end
#             if haskey(article["MedlineCitation"][1]["Article"][1], "ArticleDate")
#                 if haskey(article["MedlineCitation"][1]["Article"][1]["ArticleDate"][1], "Year")
#                     pubYear = article["MedlineCitation"][1]["Article"][1]["ArticleDate"][1]["Year"][1]
#                 end
#             else  #series of attempts to pull a publication year from alternative xml elements
#                 try
#                     pubYear = article["MedlineCitation"][1]["Article"][1]["Journal"][1]["JournalIssue"][1]["PubDate"][1]["Year"][1]
#                 catch
#                     try
#                         pubYear = article["MedlineCitation"][1]["Article"][1]["Journal"][1]["JournalIssue"][1]["PubDate"][1]["MedlineDate"][1]
#                         pubYear = parse(Int64, pubYear[1:4])
#                     catch
#                         println("Warning: No date found")
#                     end
#                 end
#             end
#
#             # Save article data
#             DB.insert_row(db, "article", Dict(:pmid => pmid,
#             :title=>title,
#             :pubYear=>pubYear))
#
#             # insert all authors
#             forename = DB.NULL[_db_backend[1]]
#             lastname = DB.NULL[_db_backend[1]]
#             if haskey(article["MedlineCitation"][1]["Article"][1], "AuthorList")
#                 authors = article["MedlineCitation"][1]["Article"][1]["AuthorList"][1]["Author"]
#                 for author in authors
#
#                     if author["ValidYN"][1] == "N"
#                         continue
#                     end
#
#                     if haskey(author, "ForeName")
#                         forename = author["ForeName"][1]
#                     else
#                         forname = "UNKNOWN"
#                     end
#
#                     if haskey(author, "LastName")
#                         lastname = author["LastName"][1]
#                     else
#                         println("Skipping Author: ", author)
#                         continue
#                     end
#
#                     # Authors must be unique - insert only if it doesn't exist
#                     # DB.exists(db, "author", )
#
#                     # Save author data
#                     author_id = DB.insert_row(db, "author",
#                     Dict(:id => DB.NULL[_db_backend[1]],
#                     :forename => forename,
#                     :lastname => lastname))
#
#                     if (author_id >= 0 )
#                         DB.insert_row(db, "author2article",
#                         Dict(:aid =>author_id, :pmid => pmid))
#                     end
#
#                 end
#             end
#
#             # Save related "keywords" of MESH Descriptors
#             if haskey(article["MedlineCitation"][1], "MeshHeadingList")
#                 if haskey(article["MedlineCitation"][1]["MeshHeadingList"][1], "MeshHeading")
#                     mesh_headings = article["MedlineCitation"][1]["MeshHeadingList"][1]["MeshHeading"]
#                     for heading in mesh_headings
#
#                         if !haskey(heading,"DescriptorName")
#                             println("Error: MeshHeading must have DescriptorName")
#                             return
#                         end
#
#                         #save descriptor
#                         descriptor_name = heading["DescriptorName"][1]["DescriptorName"][1]
#                         descriptor_name = normalize_string(descriptor_name, casefold=true)
#
#                         did = heading["DescriptorName"][1]["UI"][1]
#                         did_int = parse(Int64, did[2:end])  #remove preceding D
#
#                         DB.insert_row(db, "mesh_descriptor",
#                         Dict(:id=>did_int, :name=>descriptor_name))
#
#                         heading["DescriptorName"][1]["MajorTopicYN"][1] == "Y" ? dmjr = 1 : dmjr = 0
#
#                         #save the qualifiers
#                         if haskey(heading,"QualifierName")
#                             qualifiers = heading["QualifierName"]
#                             for qual in qualifiers
#                                 qualifier_name = qual["QualifierName"][1]
#                                 qualifier_name = normalize_string(qualifier_name, casefold=true)
#
#                                 qid = qual["UI"][1]
#                                 qid_int = parse(Int64, qid[2:end])  #remove preceding Q
#
#                                 DB.insert_row(db, "mesh_qualifier",
#                                 Dict(:id=>qid_int, :name=>qualifier_name) )
#
#                                 qual["MajorTopicYN"][1] == "Y" ? qmjr = 1 : qmjr = 0
#
#                                 #save the heading related to this paper
#                                 DB.insert_row(db, "mesh_heading",
#                                 Dict(:id=>DB.NULL[_db_backend[1]], :pmid=> pmid, :did=>did_int,
#                                 :qid=>qid_int, :dmjr=>dmjr, :qmjr=>qmjr) )
#                             end
#                         else
#                             #save the heading related to this paper
#                             DB.insert_row(db, "mesh_heading",
#                             Dict(:id=>DB.NULL[_db_backend[1]], :pmid=> pmid, :did=>did_int,
#                             :qid=>DB.NULL[_db_backend[1]], :dmjr=>dmjr, :qmjr=>DB.NULL[_db_backend[1]]) )
#                         end
#                     end
#                 end
#             end
#
#         end
#
#     end
#
#     return db
#
# end
