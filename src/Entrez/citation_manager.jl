# Extract citation in endnote format for a given PMID
# 08/31/2016

#using Requests
using NullableArrays


function citations_endnote(article::PubMedArticle, verbose=false)

    types_idx = find(x->!x, article.types.isnull)
    jrnl_art = find(x->(x=="Journal Article"), article.types.values[types_idx])

    if length(jrnl_art)!= 1
        error("EndNote can only export Journal Articles")
    end

    lines::Vector{UTF8String} = ["%0 Journal Article"]
    for au in article.authors
        if isnull(au[:Initials]) && isnull(au[:LastName])
            println("Skipping author, null field: ", au)
            continue
        end
        author = string(au[:LastName].value, ", ", au[:Initials].value)
        push!(lines, "%A $author")
    end

    !isnull(article.year) && push!(lines, "%D $(article.year.value)")
    !isnull(article.title) && push!(lines, "%T $(article.title.value)")
    !isnull(article.journal) && push!(lines, "%J $(article.journal.value)")
    !isnull(article.volume) && push!(lines, "%V $(article.volume.value)")
    !isnull(article.issue) && push!(lines, "%N $(article.issue.value)")
    !isnull(article.pages) && push!(lines, "%P $(article.pages.value)")
    !isnull(article.pmid) && push!(lines, "%M $(article.pmid.value)")
    !isnull(article.url) && push!(lines, "%U $(article.url.value)")
    !isnull(article.abstract_text) && push!(lines, "%X $(article.abstract_text.value)")


    for term in article.mesh
        !isnull(term) && push!(lines, "%K $(term.value)")
    end

    if !isempty(article.affiliations)
        idx = find(x->!x, article.affiliations.isnull)
        affiliations_str = join(article.affiliations.values[idx], ", ")
        push!(lines, "%+ $affiliations_str")
    end
    # for m in mesh_terms
    #     push!(lines, "%K $m")
    # end
    return join(lines, "\n")
end

function citations_bibtex(article::PubMedArticle, verbose=false)
    types_idx = find(x->!x, article.types.isnull)
    jrnl_art = find(x->(x=="Journal Article"), article.types.values[types_idx])

    if length(jrnl_art)!= 1
        error("EndNote can only export Journal Articles")
    end

    lines::Vector{UTF8String} = ["@article {PMID:$(article.pmid.value),"]
    authors_str = []
    for au in article.authors
        if isnull(au[:Initials]) && isnull(au[:LastName])
            println("Skipping author, null field: ", au)
            continue
        end
        author = string(au[:LastName].value, ", ", au[:Initials].value)
        push!(authors_str, "$author")
    end
    all_authors_str = join(authors_str, " and ")
    push!(lines, "  author  = {$all_authors_str},")
    !isnull(article.title)   && push!(lines, "  title   = {$(article.title.value)},")
    !isnull(article.journal) && push!(lines, "  journal = {$(article.journal.value)},")
    !isnull(article.year)    && push!(lines, "  year    = {$(article.year.value)},")
    !isnull(article.volume)  && push!(lines, "  volume  = {$(article.volume.value)},")
    !isnull(article.issue)   && push!(lines, "  number  = {$(article.issue.value)},")
    !isnull(article.pages)   && push!(lines, "  pages   = {$(article.pages.value)},")
    !isnull(article.url)     && push!(lines, "  url     = {$(article.url.value)},")
    push!(lines, "}\n")
    return join(lines, "\n")
end

function save_article_citations(efetch_dict, config, verbose=false)
    if !(haskey(config, :type) && haskey(config, :output_file) && haskey(config, :overwrite))
        error("Saving citations requires correct dictionary configuration")
    end
    output_file = config[:output_file]

    if config[:overwrite]
        if isfile(output_file)
            rm(output_file)
        end
    end

    if config[:type] == "bibtex"
        citation_func = citations_bibtex
    elseif config[:type] == "endnote"
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
    for xml_article in articles
        article = TypeArticle(xml_article)
        try
            citation = citation_func(article, verbose)
            print(fout, citation)
            println(fout) #two empty lines
            println(fout)
        catch
            println("Citation failed for PMDI: ", article.pmid)
            continue
        end
    end
    close(fout)
end
