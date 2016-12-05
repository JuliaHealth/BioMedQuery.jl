using NullableArrays
using DataStructures


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

# Note: If needed it could be further refactored to to that author, journal is a type
"""
    PubMedArticle
Type that matches the NCBI-XML contents for a PubMedArticle
"""
type PubMedArticle
    types::NullableArray{String, 1}
    pmid::Nullable{Int64}
    url::Nullable{String}
    title::Nullable{String}
    authors::Vector{Dict{Symbol,Nullable{String}}}
    year::Nullable{Int64}
    journal::Nullable{String}
    volume::Nullable{String}
    issue::Nullable{String}
    abstract_text::Nullable{String}
    pages::Nullable{String}
    mesh::NullableArray{String, 1}
    affiliations::NullableArray{String, 1}

    #Constructor from XML article element
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
            this.types = NullableArray{String}(0)
            if haskey(medline_article,"PublicationTypeList")
                if haskey(medline_article["PublicationTypeList"][1],"PublicationType")
                    for pub_type_xml in medline_article["PublicationTypeList"][1]["PublicationType"]
                        pub_type = get_if_exists(pub_type_xml, "PublicationType",Nullable{String}())
                        push!(this.types, pub_type)
                    end
                end
            end
            this.title = get_if_exists(medline_article, "ArticleTitle", Nullable{String}())

            if haskey(medline_article, "Journal")
                this.journal = get_if_exists(medline_article["Journal"][1], "ISOAbbreviation", Nullable{String}())
                if haskey(medline_article["Journal"][1], "JournalIssue")
                    #Issues and volumesn may be a number or a string e.g issue=4 or "4-6"
                    volume = get_if_exists(medline_article["Journal"][1]["JournalIssue"][1], "Volume",Nullable{String}())
                    if isa(volume, Nullable{Int64})
                        this.volume = string(volume.value)
                    else
                        this.volume = volume
                    end
                    issue = get_if_exists(medline_article["Journal"][1]["JournalIssue"][1], "Issue",Nullable{String}())
                    if isa(issue, Nullable{Int64})
                        this.issue = string(issue.value)
                    else
                        this.issue = issue
                    end
                end
            end


            if haskey(medline_article,"Pagination")
                pages = get_if_exists(medline_article["Pagination"][1], "MedlinePgn",Nullable{String}())
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

            this.abstract_text = Nullable{String}()
            if haskey(medline_article, "Abstract")
                try
                    this.abstract_text = get_if_exists(medline_article["Abstract"][1], "AbstractText",Nullable{String}() )
                catch
                    text = ""
                    for abs in medline_article["Abstract"][1]["AbstractText"]
                        if (haskey(abs, "Label"))
                           text = string(text, abs["Label"][1], ": ", abs["AbstractText"][1], " ")
                        end
                    end
                    this.abstract_text = Nullable(text)
                    # println(this.abstract_text)
                end
            else
                println("Warning: No Abstract Text found, PMID: ", this.pmid.value)
            end

            # Get authors
            this.authors = Vector{Dict{Symbol,Nullable{String}}}()
            this.affiliations = NullableArray{String}(0)
            if haskey(medline_article, "AuthorList")
                xml_authors = medline_article["AuthorList"][1]["Author"]
                for author in xml_authors

                    if haskey(author, "ValidYN")
                        if author["ValidYN"][1] == "N"
                            println("Skipping Author Valid:N: ", author)
                            continue
                        end
                    end
                    forname = get_if_exists(author, "ForeName", Nullable{String}())
                    initials = get_if_exists(author, "Initials", Nullable{String}())
                    lastname = get_if_exists(author, "LastName", Nullable{String}())
                    if haskey(author, "AffiliationInfo")
                        if haskey(author["AffiliationInfo"][1], "Affiliation")
                            for aff in author["AffiliationInfo"][1]["Affiliation"]
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
        this.mesh = NullableArray{String}(0)
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


type MeshHeading
    descriptor_name::Nullable{String}
    descriptor_id::Nullable{Int64}
    descriptor_mjr::Nullable{String}
    qualifier_name::NullableArray{String, 1}
    qualifier_id::NullableArray{Int64, 1}
    qualifier_mjr::NullableArray{String, 1}

    #Constructor from XML heading element
    function MeshHeading(NCBIXMLheading)

        # A Mesh Heading is composed of ONE descriptor and 0/MANY qualifiers

        if !haskey(NCBIXMLheading,"DescriptorName")
            error("Error: MeshHeading must have DescriptorName")
        end

        this = new()


        this.descriptor_name = Nullable{String}()
        this.descriptor_id = Nullable{Int64}()

        #Descriptor
        descriptor_name = get_if_exists(NCBIXMLheading["DescriptorName"][1], "DescriptorName", Nullable{String}())

        if !isnull(descriptor_name)
            this.descriptor_name = normalize_string(descriptor_name.value, casefold=true)
        end

        did = get_if_exists(NCBIXMLheading["DescriptorName"][1], "UI", Nullable{String}())

        if !isnull(did)
            this.descriptor_id = parse(Int64, did.value[2:end])  #remove preceding D
        end

        this.descriptor_mjr = get_if_exists(NCBIXMLheading["DescriptorName"][1], "MajorTopicYN", Nullable{String}())


        #Qualifier
        this.qualifier_name = NullableArray{String, 1}()
        this.qualifier_id = NullableArray{Int64, 1}()
        this.qualifier_mjr = NullableArray{String, 1}()
        if haskey(NCBIXMLheading,"QualifierName")
            qualifiers = NCBIXMLheading["QualifierName"]
            for qual in qualifiers

                qname = get_if_exists(qual, "QualifierName", Nullable{String}())

                if !isnull(qname)
                    qname = normalize_string(qname.value, casefold=true)
                    push!(this.qualifier_name, Nullable(qname))

                    qid = get_if_exists(qual, "UI", Nullable{String}())

                    if !isnull(qid)
                        qid = parse(Int64, qid.value[2:end])  #remove preceding Q
                        push!(this.qualifier_id, Nullable(qid))
                    end


                    qmjr = get_if_exists(qual, "MajorTopicYN", Nullable{String}())
                    push!(this.qualifier_mjr, qmjr)

                end
            end
        end
        return this
    end
end


# Typealias for natural iteration
typealias MeshHeadingList Vector{MeshHeading}

#Constructor-Like method from XML article element
function MeshHeadingList(NCBIXMLarticle::DataStructures.MultiDict{Any,Any})
    if !haskey(NCBIXMLarticle,"MedlineCitation")
        error("MedlineCitation not found")
    end

    # println("===========typeof================")
    # println(typeof(NCBIXMLarticle))

    this = MeshHeadingList()
    # println("===========typeof================")
    # println(typeof(this))
    medline_citation = NCBIXMLarticle["MedlineCitation"][1]
    if haskey(medline_citation, "MeshHeadingList")
        if haskey(medline_citation["MeshHeadingList"][1], "MeshHeading")
            xml_mesh_headings = medline_citation["MeshHeadingList"][1]["MeshHeading"]
            for xml_heading in xml_mesh_headings
                # println("===========push================")
                # println(xml_heading)
                heading = MeshHeading(xml_heading)
                # show(heading)
                push!(this, MeshHeading(xml_heading))
            end
        end
    end

    return this
end
