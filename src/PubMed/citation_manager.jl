
"""
    CitationOutput
Structure to hold the format and file location to store citations
"""
mutable struct CitationOutput
    format::String
    file::String

    function CitationOutput(format::String, file::String, overwrite::Bool)
        this = new()
        this.format = format
        
        if overwrite
            if isfile(file)
                rm(file)
            end
        end

        this.file = file

        return this
    end
end

"""
    citations_endnote(article::PubMedArticle, verbose=false)

Transforms a PubMedArticle into text corresponding to its endnote citation
"""
function citations_endnote(article::PubMedArticle, verbose=false)

    # println("***Types: ", article.types)
    jrnl_art = find(x->(x=="Journal Article"), skipmissing(article.types))

    if length(jrnl_art)!= 1
        error("EndNote can only export Journal Articles")
    end

    lines::Vector{String} = ["%0 Journal Article"]
    for au in article.authors
        if ismissing(au[:Initials]) && ismissing(au[:LastName])
            println("Skipping author, null field: ", au)
            continue
        end
        author = string(au[:LastName], ", ", au[:Initials])
        push!(lines, "%A $author")
    end

    !ismissing(article.year) && push!(lines, "%D $(article.year)")
    !ismissing(article.title) && push!(lines, "%T $(article.title)")
    !ismissing(article.journal) && push!(lines, "%J $(article.journal)")
    !ismissing(article.volume) && push!(lines, "%V $(article.volume)")
    !ismissing(article.issue) && push!(lines, "%N $(article.issue)")
    !ismissing(article.pages) && push!(lines, "%P $(article.pages)")
    !ismissing(article.pmid) && push!(lines, "%M $(article.pmid)")
    !ismissing(article.url) && push!(lines, "%U $(article.url)")
    !ismissing(article.abstract_text) && push!(lines, "%X $(article.abstract_text)")


    for term in article.mesh
        !ismissing(term) && push!(lines, "%K $(term)")
    end

    if !isempty(article.affiliations)
        affiliations_str = join(skipmissing(article.affiliations), ", ")
        push!(lines, "%+ $affiliations_str")
    end
    # for m in mesh_terms
    #     push!(lines, "%K $m")
    # end
    return join(lines, "\n")
end

"""
    citations_bibtex(article::PubMedArticle, verbose=false)

Transforms a PubMedArticle into text corresponding to its bibtex citation
"""
function citations_bibtex(article::PubMedArticle, verbose=false)
    jrnl_art = find(x->(x=="Journal Article"), skipmissing(article.types))

    if length(jrnl_art)!= 1
        error("EndNote can only export Journal Articles")
    end

    lines::Vector{String} = ["@article {PMID:$(article.pmid),"]
    authors_str = []
    for au in article.authors
        if ismissing(au[:Initials]) && ismissing(au[:LastName])
            println("Skipping author, null field: ", au)
            continue
        end
        author = string(au[:LastName], ", ", au[:Initials])
        push!(authors_str, "$author")
    end
    all_authors_str = join(authors_str, " and ")
    push!(lines, "  author  = {$all_authors_str},")
    !ismissing(article.title)   && push!(lines, "  title   = {$(article.title)},")
    !ismissing(article.journal) && push!(lines, "  journal = {$(article.journal)},")
    !ismissing(article.year)    && push!(lines, "  year    = {$(article.year)},")
    !ismissing(article.volume)  && push!(lines, "  volume  = {$(article.volume)},")
    !ismissing(article.issue)   && push!(lines, "  number  = {$(article.issue)},")
    !ismissing(article.pages)   && push!(lines, "  pages   = {$(article.pages)},")
    !ismissing(article.url)     && push!(lines, "  url     = {$(article.url)},")
    push!(lines, "}\n")
    return join(lines, "\n")
end

"""
    save_efetch!(output::CitationOutput, efetch_dict, verbose=false)

Save the results of a Entrez efetch to a bibliography file, with format and 
file path given by `output::CitationOutput`
"""
function save_efetch!(output::CitationOutput, efetch_dict, verbose=false)
   
    output_file = output.file

    if output.format == "bibtex"
        citation_func = citations_bibtex
    elseif output.format == "endnote"
        citation_func = citations_endnote
    else
        error("Reference type not supported")
    end

    #Decide type of article based on structrure of efetch
    if haskey(efetch_dict, "PubmedArticle")
        TypeArticle = PubMedArticle
        articles = efetch_dict["PubmedArticle"]
    else
        error("Saving citations is only supported for PubMed searches")
    end

    println("Saving citation for " , length(articles) ,  " articles")

    fout = open(output_file, "a")
    nsuccess=0
    if typeof(articles) <: Array
        for xml_article in articles
            article = TypeArticle(xml_article)
            try
                citation = citation_func(article, verbose)
                print(fout, citation)
                println(fout) #two empty lines
                println(fout)
                nsuccess+=1
            catch error
                println("Citation failed for article: ", article)
                println(error)
                continue
            end
        end
    else
        article = TypeArticle(articles)
        try
            citation = citation_func(article, verbose)
            print(fout, citation)
            println(fout) #two empty lines
            println(fout)
            nsuccess+=1
        catch error
            println("Citation failed for article: ", article)
            println(error)
        end
    end
    close(fout)
    return nsuccess
end
