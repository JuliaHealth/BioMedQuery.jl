
using NullableArrays


# Given a multidict and a key, this function returns either the
# (single) value for that key, or `nothing`. Thus, it assumes we
# want single element result, otherwise a warning is printed.
function get_if_exists{T}(mdict, k, default_val::Nullable{T}, i = 1)
    if haskey(mdict, k)
        if length(mdict[k]) == 1
            res = Nullable(mdict[k][1])
        else
            error("`$k` for location $i has mulitple values")
        end
    else
        res = default_val
    end
    return res
end

type PubMedArticle
    types::NullableArray{UTF8String, 1}
    pmid::Nullable{Int64}
    url::Nullable{UTF8String}
    title::Nullable{UTF8String}
    authors::Vector{Dict{Symbol,Nullable{UTF8String}}}
    year::Nullable{Int64}
    journal::Nullable{UTF8String}
    volume::Nullable{Int64}
    issue::Nullable{ASCIIString}
    abstract_text::Nullable{UTF8String}
    pages::Nullable{ASCIIString}
    mesh::NullableArray{UTF8String, 1}
    affiliations::NullableArray{UTF8String, 1}

    function PubMedArticle(NCBIXMLarticle)

        if !haskey(NCBIXMLarticle,"MedlineCitation")
            error("MedlineCitation not found")
        end

        this = new()

        medline_citation = NCBIXMLarticle["MedlineCitation"][1]
        if haskey(medline_citation,"PMID")
            this.pmid = get_if_exists(medline_citation["PMID"][1], "PMID", Nullable{Int64}())
        end
        if isnull(this.pmid)
            error("PMID not found - cannot be nothing")
        end

        this.url = Nullable(string("http://www.ncbi.nlm.nih.gov/pubmed/", this.pmid.value))
        # Retrieve basic article info
        if haskey(medline_citation,"Article")
            medline_article = medline_citation["Article"][1]
            this.types = NullableArray{UTF8String}(0)
            if haskey(medline_article,"PublicationTypeList")
                if haskey(medline_article["PublicationTypeList"][1],"PublicationType")
                    for pub_type_xml in medline_article["PublicationTypeList"][1]["PublicationType"]
                        pub_type = get_if_exists(pub_type_xml, "PublicationType",Nullable{UTF8String}())
                        push!(this.types, pub_type)
                    end
                end
            end
            this.title = get_if_exists(medline_article, "ArticleTitle", Nullable{UTF8String}())

            if haskey(medline_article, "Journal")
                this.journal = get_if_exists(medline_article["Journal"][1], "ISOAbbreviation", Nullable{UTF8String}())
                if haskey(medline_article["Journal"][1], "JournalIssue")
                    this.volume = get_if_exists(medline_article["Journal"][1]["JournalIssue"][1], "Volume",Nullable{Int64}())
                    #Issue comes as a number others as a string e.g issue=4 or "4-6"
                    issue = get_if_exists(medline_article["Journal"][1]["JournalIssue"][1], "Issue",Nullable{ASCIIString}())
                    if isa(issue, Nullable{Int64})
                        this.issue = string(issue.value)
                    else
                        this.issue = issue
                    end
                end
            end


            if haskey(medline_article,"Pagination")
                pages = get_if_exists(medline_article["Pagination"][1], "MedlinePgn",Nullable{ASCIIString}())
                if isa(pages, Nullable{Int64})
                    this.pages = string(pages.value)
                else
                    this.pages = pages
                end
            end

            this.year = Nullable{Int64}()
            if haskey(medline_article, "ArticleDate")
                this.year = get_if_exists(medline_article["ArticleDate"][1], "Year",Nullable{Int64}())
            else  #series of attempts to pull a publication year from alternative xml elements
                try
                    this.year  = medline_article["Journal"][1]["JournalIssue"][1]["PubDate"][1]["Year"][1]
                catch
                    try
                        year = medline_article["Journal"][1]["JournalIssue"][1]["PubDate"][1]["MedlineDate"][1]
                        this.year = parse(Int64, year[1:4])

                    catch
                        println("Warning: No Date found, PMID: ", this.pmid.value)
                    end
                end
            end

            this.abstract_text = Nullable{UTF8String}()
            # println(medline_article)
            if haskey(medline_article, "Abstract")
                # println("Has Abstract")
                # println(medline_article["Abstract"][1])
                try
                    this.abstract_text = get_if_exists(medline_article["Abstract"][1], "AbstractText",Nullable{UTF8String}() )
                catch
                    text = ""
                    for abs in medline_article["Abstract"][1]["AbstractText"]
                        # println(abs)
                        text = string(text, abs["Label"][1], ": ", abs["AbstractText"][1], "\n")
                    end
                    this.abstract_text = Nullable(text)
                end
            else
                println("Warning: No Abstract Text found, PMID: ", this.pmid.value)
            end

            # Get authors
            this.authors = Vector{Dict{Symbol,Nullable{UTF8String}}}()
            this.affiliations = NullableArray{UTF8String}(0)
            if haskey(medline_article, "AuthorList")
                xml_authors = medline_article["AuthorList"][1]["Author"]
                for author in xml_authors

                    if haskey(author, "ValidYN")
                        if author["ValidYN"][1] == "N"
                            println("Skipping Author Valid:N: ", author)
                            continue
                        end
                    end
                    forname = get_if_exists(author, "ForeName", Nullable{UTF8String}())
                    initials = get_if_exists(author, "Initials", Nullable{UTF8String}())
                    lastname = get_if_exists(author, "LastName", Nullable{UTF8String}())
                    if haskey(author, "AffiliationInfo")
                        println("here1")
                        if haskey(author["AffiliationInfo"][1], "Affiliation")
                            for aff in author["AffiliationInfo"][1]["Affiliation"]
                                println("here2  ")
                                push!(this.affiliations, aff)
                            end
                        end
                    end

                    if isnull(lastname)
                        println("Skipping Author: ", author)
                        continue
                    end

                    push!(this.authors, Dict(:ForeName=> forname, :LastName=> lastname, :Initials=> initials))

                end
            end

        end


        # Get MESH Descriptors
        this.mesh = NullableArray{UTF8String}(0)
        if haskey(medline_citation, "MeshHeadingList")
            if haskey(medline_citation["MeshHeadingList"][1], "MeshHeading")
                mesh_headings = medline_citation["MeshHeadingList"][1]["MeshHeading"]
                for heading in mesh_headings
                    if !haskey(heading,"DescriptorName")
                        error("MeshHeading must have DescriptorName")
                    end
                    #save descriptor
                    descriptor_name = heading["DescriptorName"][1]["DescriptorName"][1]
                    # descriptor_name = normalize_string(descriptor_name, casefold=true)
                    push!(this.mesh, Nullable(descriptor_name))
                end
            end
        end
        return this
    end
end
