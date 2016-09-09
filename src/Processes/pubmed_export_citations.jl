using BioMedQuery.Entrez


function export_citation(entrez_email, pmid::Int64, citation_type, output_file,
    verbose=false)
    fetch_dic = Dict("db"=>"pubmed","tool" =>"BioJulia", "email" => entrez_email,
    "retmode" => "xml", "rettype"=>"null")
    efetch_response = efetch(fetch_dic, [pmid])
    if verbose
        xmlASCII2file(efetch_response, "./efetch.xml")
    end
    efetch_dict = eparse(efetch_response)
    config = Dict(:type => citation_type, :output_file => output_file)
    save_article_citations(efetch_dict, config, verbose)
end

function export_citation(entrez_email, pmids::Vector{Int64}, citation_type, output_file,
    verbose=false)
    fetch_dic = Dict("db"=>"pubmed","tool" =>"BioJulia", "email" => entrez_email,
    "retmode" => "xml", "rettype"=>"null")
    efetch_response = efetch(fetch_dic, pmids)
    if verbose
        xmlASCII2file(efetch_response, "./efetch.xml")
    end
    efetch_dict = eparse(efetch_response)
    config = Dict(:type => citation_type, :output_file => output_file)
    save_article_citations(efetch_dict, config, verbose)
end
