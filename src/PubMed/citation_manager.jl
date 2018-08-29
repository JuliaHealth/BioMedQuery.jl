
using DataFrames

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
    citations_endnote(article::Dict{String,DataFrame}, verbose=false)

Transforms a Dictionary of pubmed dataframes into text corresponding to its endnote citation
"""
function citations_endnote(article::Dict{String,DataFrame}, row::Int, verbose=false)


    # println("***Types: ", article.types)
    jrnl_art = findall((article["pub_type"][:name].=="Journal Article") .& (article["pub_type"][:pmid] .== article["basic"][row,:pmid]))

    if length(jrnl_art)!= 1
        println(article["pub_type"])
        @error "EndNote can only export Journal Articles" exception=ErrorException
    end

    lines::Vector{String} = ["%0 Journal Article"]
    affiliation_str = ""
    auth_art = article["author_ref"][findall(article["author_ref"][:pmid] .== article["basic"][row,:pmid]),:]
    for au = 1:size(auth_art)[1]
        if ismissing(auth_art[au,:initials]) && ismissing(auth_art[au,:last_name])
            println("Skipping author, null field: ", au)
            continue
        end
        author = string(auth_art[au,:last_name], ", ", auth_art[au,:initials])
        if !(ismissing(auth_art[au,:affiliation]))
            affiliation_str *= auth_art[au,:affiliation] * "; "
        end
        push!(lines, "%A $author")
    end


    !ismissing(article["basic"][row,:pub_year]) && push!(lines, "%D $(article["basic"][row,:pub_year])")
    !ismissing(article["basic"][row,:title]) && push!(lines, "%T $(article["basic"][row,:title])")
    !ismissing(article["basic"][row,:journal_iso_abbreviation]) && push!(lines, "%J $(article["basic"][row,:journal_iso_abbreviation])") # Does this need to be ISO abbreviation?
    !ismissing(article["basic"][row,:journal_volume]) && push!(lines, "%V $(article["basic"][row,:journal_volume])")
    !ismissing(article["basic"][row,:journal_issue]) && push!(lines, "%N $(article["basic"][row,:journal_issue])")
    !ismissing(article["basic"][row,:journal_pages]) && push!(lines, "%P $(article["basic"][row,:journal_pages])")
    !ismissing(article["basic"][row,:pmid]) && push!(lines, "%M $(article["basic"][row,:pmid])")
    !ismissing(article["basic"][row,:url]) && push!(lines, "%U $(article["basic"][row,:url])")

    abstract_full = article["abstract_full"][findall(article["abstract_full"][:pmid] .== article["basic"][row,:pmid]), :abstract_text]
    length(abstract_full) == 1 && push!(lines, "%X $(abstract_full)")

    mesh_headings = article["mesh_heading"][(findall(article["mesh_heading"][:pmid] .== article["basic"][row,:pmid])),:]
    mesh_descs = join(mesh_headings, article["mesh_desc"], on = (:desc_uid, :uid), kind=:inner)

    for i in 1:size(mesh_descs)[1]
        !ismissing(mesh_descs[i,:name]) && push!(lines, "%K $(mesh_descs[i,:name])")
    end

    !(affiliation_str == "") && push!(lines, "%+ $(affiliation_str[1:end-2])")

    return join(lines, "\n")
end

"""
    citations_bibtex(article::Dict{String,DataFrame}, verbose=false)

Transforms a Dictionary of pubmed dataframes into text corresponding to its bibtex citation
"""
function citations_bibtex(article::Dict{String,DataFrame}, row::Int, verbose=false)

    jrnl_art = findall((article["pub_type"][:name].=="Journal Article") .& (article["pub_type"][:pmid] .== article["basic"][row,:pmid]))

    if length(jrnl_art)!= 1
        error("BibTex can only export Journal Articles")
    end

    lines::Vector{String} = ["@article {PMID:$(article["basic"][row,:pmid]),"]
    authors_str = []
    auth_art = article["author_ref"][(findall(article["author_ref"][:pmid] .== article["basic"][row,:pmid])),:]
    for au = 1:size(auth_art)[1]
        if ismissing(auth_art[au,:initials]) && ismissing(auth_art[au,:last_name])
            println("Skipping author, null field: ", au)
            continue
        end
        author = string(auth_art[au,:last_name], ", ", auth_art[au,:initials])
        push!(authors_str, "$author")
    end
    all_authors_str = join(authors_str, " and ")
    push!(lines, "  author  = {$all_authors_str},")
    !ismissing(article["basic"][row,:title])   && push!(lines, """  title   = {$(article["basic"][row,:title])},""")
    !ismissing(article["basic"][row,:journal_iso_abbreviation]) && push!(lines, """  journal = {$(article["basic"][row,:journal_iso_abbreviation])},""")
    !ismissing(article["basic"][row,:pub_year])    && push!(lines, """  year    = {$(article["basic"][row,:pub_year])},""")
    !ismissing(article["basic"][row,:journal_volume])  && push!(lines, """  volume  = {$(article["basic"][row,:journal_volume])},""")
    !ismissing(article["basic"][row,:journal_issue])   && push!(lines, """  number  = {$(article["basic"][row,:journal_issue])},""")
    !ismissing(article["basic"][row,:journal_pages])   && push!(lines, """  pages   = {$(article["basic"][row,:journal_pages])},""")
    !ismissing(article["basic"][row,:url])     && push!(lines, """  url     = {$(article["basic"][row,:url])},""")
    push!(lines, "}\n")
    return join(lines, "\n")
end

"""
    save_efetch!(output::CitationOutput, efetch_dict, verbose=false)

Save the results of a Entrez efetch to a bibliography file, with format and
file path given by `output::CitationOutput`
"""
function save_efetch!(output::CitationOutput, articles::LightXML.XMLElement, verbose=false, cleanup = false)

    output_file = output.file

    if output.format == "bibtex"
        citation_func = citations_bibtex
    elseif output.format == "endnote"
        citation_func = citations_endnote
    else
        error("Reference type not supported")
    end

    n_articles = length(collect(child_elements(articles)))

    #Decide type of article based on structrure of efetch
    if name(articles) != "PubmedArticleSet"
        println(articles)
        error("Save efetch is only supported for PubMed searches")
    end

    println("Saving citation for " , n_articles ,  " articles")

    fout = open(output_file, "a")
    nsuccess=0

    articles_df = PubMed.parse_articles(articles)

    for i = 1:n_articles
        try
            citation = citation_func(articles_df, i, verbose)
            print(fout, citation)
            println(fout) #two empty lines
            println(fout)
            nsuccess+=1
        catch error
            println("Citation failed for article: ", articles_df["basic"][i,:pmid])
            println(error)
            continue
        end

    end

    close(fout)
    return nsuccess
end
