using BioServices.EUtils
using BioMedQuery.PubMed
using LightXML

"""
    export_citation(pmid::Int64, citation_type, output_file,verbose)

Export, to an output file, the citation for PubMed article identified by the given pmid

## Arguments
* `citation_type::String`: At the moment supported types include: "endnote", "bibtex"
"""
function export_citation(pmid::Int64, citation_type, output_file, overwrite = true, verbose=false)

    efetch_response = efetch(db = "pubmed", tool = "BioJulia", retmode = "xml", rettype = "null", id = [pmid])

    if verbose
        xdoc = parse_string(String(efetch_response.body))
        save_file(xdoc, "./efetch.xml")
    end

    #convert xml to ezxml doc
    efetch_doc = root(parse_string(String(efetch_response.body)))
    citation_output = PubMed.CitationOutput(citation_type, output_file, overwrite)
    save_efetch!(citation_output, efetch_doc, verbose)
end

"""
    export_citation(pmids::Vector{Int64}, citation_type, output_file,verbose)

Export, to an output file, the citation for collection of PubMed articles identified by the given pmids

## Arguments
* `citation_type::String`: At the moment supported types include: "endnote", "bibtex"
"""
function export_citation(pmids::Vector{Int64}, citation_type, output_file, overwrite=true, verbose=false)
    efetch_response = efetch(db = "pubmed", tool = "BioJulia", retmode = "xml", rettype = "null", id = pmids)

    if verbose
        xdoc = parse_string(efetch_response.body)
        save_file(xdoc, "./efetch.xml")
    end

    #convert xml to ezxml doc
    efetch_doc = root(parse_string(String(efetch_response.body)))

    citation_output = PubMed.CitationOutput(citation_type, output_file, overwrite)
    save_efetch!(citation_output, efetch_doc, verbose)
end
