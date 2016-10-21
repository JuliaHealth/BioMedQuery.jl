using BioMedQuery.Entrez

"""
    export_citation(entrez_email, pmid::Int64, citation_type, output_file,verbose)

Export, to an output file, the citation for PubMed article identified by the given pmid

### Arguments
* `citation_type::String`: At the moment supported types include: "endnote"
"""
function export_citation(entrez_email, pmid::Int64, citation_type, output_file,
    overwrite = true, verbose=false)
    fetch_dic = Dict("db"=>"pubmed","tool" =>"BioJulia", "email" => entrez_email,
    "retmode" => "xml", "rettype"=>"null")
    efetch_response = efetch(fetch_dic, [pmid])
    if verbose
        xmlASCII2file(efetch_response, "./efetch.xml")
    end
    efetch_dict = eparse(efetch_response)
    config = Dict(:type => citation_type, :output_file => output_file, :overwrite=>overwrite)
    save_article_citations(efetch_dict, config, verbose)
end

"""
    export_citation(entrez_email, pmids::Vector{Int64}, citation_type, output_file,verbose)

Export, to an output file, the citation for collection of PubMed articles identified by the given pmids

### Arguments
* `citation_type::String`: At the moment supported types include: "endnote"
"""
function export_citation(entrez_email, pmids::Vector{Int64}, citation_type, output_file,
    overwrite=true, verbose=false)
    fetch_dic = Dict("db"=>"pubmed","tool" =>"BioJulia", "email" => entrez_email,
    "retmode" => "xml", "rettype"=>"null")
    efetch_response = efetch(fetch_dic, pmids)
    if verbose
        xmlASCII2file(efetch_response, "./efetch.xml")
    end
    efetch_dict = eparse(efetch_response)
    config = Dict(:type => citation_type, :output_file => output_file, :overwrite=>overwrite)
    save_article_citations(efetch_dict, config, verbose)
end
