using NullableArrays
using DataStructures


# Given a multidict and a key, this function returns either the
# (single) value for that key, or `nothing`. Thus, it assumes we
# want single element result, otherwise a warning is printed.
function get_if_exists{T}(dict, k, default_val::Nullable{T})
    return haskey(dict, k) ? Nullable(dict[k]) : default_val
end

# Note: If needed it could be further refactored to to that author, journal is a type
"""
    PubMedArticle
Type that matches the NCBI-XML contents for a PubMedArticle
"""
mutable struct PubMedArticle
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

        medline_citation = NCBIXMLarticle["MedlineCitation"]

        if haskey(medline_citation,"PMID")
            this.pmid = parse(Int64, medline_citation["PMID"][""])
        end

        if isnull(this.pmid)
            error("PMID not found")
        end

        this.url = Nullable(string("http://www.ncbi.nlm.nih.gov/pubmed/", this.pmid.value))

        status = haskey(medline_citation,:Status) ? medline_citation[:Status]:""

        if status != "MEDLINE"
            println("Warning: Article with PMID: ", this.pmid.value, " may have missing fields. MEDLINE status: ", status)
        end

        # Retrieve basic article info
        if haskey(medline_citation,"Article")
            medline_article = medline_citation["Article"]
            this.types = NullableArray{String}(0)
            if haskey(medline_article, "PublicationTypeList")
                    if typeof(medline_article["PublicationTypeList"]["PublicationType"]) <: Array
                        for pub_type_xml in medline_article["PublicationTypeList"]["PublicationType"]
                            push!(this.types, pub_type_xml[""])
                        end
                    else
                        push!(this.types, medline_article["PublicationTypeList"]["PublicationType"][""])
                    end
            end

            this.title = get_if_exists(medline_article, "ArticleTitle", Nullable{String}())

            if haskey(medline_article, "Journal")
                this.journal = get_if_exists(medline_article["Journal"], "ISOAbbreviation", Nullable{String}())
                if haskey(medline_article["Journal"], "JournalIssue")
                    this.volume = get_if_exists(medline_article["Journal"]["JournalIssue"], "Volume", Nullable{String}())
                    this.issue = get_if_exists(medline_article["Journal"]["JournalIssue"], "Issue",  Nullable{String}())
                end
            end


            if haskey(medline_article,"Pagination")
                this.pages = get_if_exists(medline_article["Pagination"], "MedlinePgn",  Nullable{String}())
            end

            this.year = Nullable{Int64}()

            if haskey(medline_article, "ArticleDate")
                this.year = parse(Int64, medline_article["ArticleDate"]["Year"])
            else  #series of attempts to pull a publication year from alternative xml elements
                try
                    this.year  = parse(Int64, medline_article["Journal"]["JournalIssue"]["PubDate"]["Year"])
                catch
                    try
                        year = medline_article["Journal"]["JournalIssue"]["PubDate"]["MedlineDate"]
                        this.year = parse(Int64, year[1:4])

                    catch
                        println("Warning: No Date found, PMID: ", this.pmid.value)
                    end
                end
            end

            this.abstract_text = Nullable{String}()
            if haskey(medline_article, "Abstract")
                try
                    this.abstract_text = get_if_exists(medline_article["Abstract"], "AbstractText", Nullable{String}() )
                catch
                    text = ""
                    for abs in medline_article["Abstract"]["AbstractText"]
                        try
                           text = string(text, abs[:Label], ": ", abs[""], " ")
                        catch
                            println("Warning: No Abstract Text: ", abs, " - PMID: ", this.pmid.value)
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
                authors_list = medline_article["AuthorList"]["Author"]
                if typeof(authors_list) <: Array
                    for author in authors_list
                        if author[:ValidYN] == "N"
                            println("Skipping Author Valid:N: ", author)
                            continue
                        end
                        forname = get_if_exists(author, "ForeName", Nullable{String}())
                        initials = get_if_exists(author, "Initials", Nullable{String}())
                        lastname = get_if_exists(author, "LastName", Nullable{String}())
                        
                        if haskey(author, "AffiliationInfo")
                            if typeof(author["AffiliationInfo"]) <: Array
                                for aff in author["AffiliationInfo"]
                                    push!(this.affiliations, aff["Affiliation"])
                                end
                            else
                                push!(this.affiliations, get_if_exists(author["AffiliationInfo"], "Affiliation", Nullable{String}()))
                            end
                        end

                        if isnull(lastname)
                            println("Skipping Author: ", author)
                            continue
                        end

                        push!(this.authors, Dict(:ForeName=> forname, :LastName=> lastname, :Initials=> initials))
                    end
                else           
                    author = authors_list
                    if author[:ValidYN] == "Y"                       
                        forname = author["ForeName"]
                        initials = get_if_exists(author, "Initials", Nullable{String}())
                        lastname = author["LastName"]
                        
                        if haskey(author, "AffiliationInfo")
                            if typeof(author["AffiliationInfo"]) <: Array
                                for aff in author["AffiliationInfo"]
                                    push!(this.affiliations, aff["Affiliation"])
                                end
                            else
                                push!(this.affiliations, get_if_exists(author["AffiliationInfo"], "Affiliation", Nullable{String}()))
                            end
                        end
                        push!(this.authors, Dict(:ForeName=> forname, :LastName=> lastname, :Initials=> initials))
    
                    else
                        println("Skipping Author: ", author)                        
                    end
                end
            end
            
        end


        # Get MESH Descriptors
        this.mesh = NullableArray{String}(0)
        if haskey(medline_citation, "MeshHeadingList")
            if haskey(medline_citation["MeshHeadingList"], "MeshHeading")
                mesh_headings = medline_citation["MeshHeadingList"]["MeshHeading"]
                for heading in mesh_headings
                    if !haskey(heading,"DescriptorName")
                        error("MeshHeading must have DescriptorName")
                    end
                    #save descriptor
                    descriptor_name = heading["DescriptorName"][""]
                    # descriptor_name = normalize_string(descriptor_name, casefold=true)
                    push!(this.mesh, Nullable(descriptor_name))
                end
            end
        end
        
        return this
    
    end

end #struct


mutable struct MeshHeading
    descriptor_name::Nullable{String}
    descriptor_id::Nullable{Int64}
    descriptor_mjr::Nullable{String}
    qualifier_name::NullableArray{String, 1}
    qualifier_id::NullableArray{Int64, 1}
    qualifier_mjr::NullableArray{String, 1}

    #Constructor from XML heading element
    function MeshHeading(NCBIXMLheading)

        # A Mesh Heading is composed of ONE descriptor and 0/MANY qualifiers
        if !haskey(NCBIXMLheading, "DescriptorName")
            error("Error: MeshHeading must have DescriptorName")
        end

        this = new()

        #Descriptor
        this.descriptor_name = NCBIXMLheading["DescriptorName"][""]


        # if !isnull(descriptor_name)
        #     this.descriptor_name = normalize_string(descriptor_name.value, casefold=true)
        # end

        did = NCBIXMLheading["DescriptorName"][:UI]
        this.descriptor_id = parse(Int64, did[2:end])  #remove preceding D
        this.descriptor_mjr = NCBIXMLheading["DescriptorName"][:MajorTopicYN]


        #Qualifier
        this.qualifier_name = NullableArray{String, 1}()
        this.qualifier_id = NullableArray{Int64, 1}()
        this.qualifier_mjr = NullableArray{String, 1}()
        if haskey(NCBIXMLheading,"QualifierName")
            qualifiers = NCBIXMLheading["QualifierName"]
            if typeof(qualifiers) <: Array
                for qual in qualifiers
                    qname = qual[""]
                    # qname = normalize_string(qname.value, casefold=true)
                    push!(this.qualifier_name, Nullable(qname))
                    qid = qual[:UI]
                    qid = parse(Int64, qid[2:end])  #remove preceding Q
                    push!(this.qualifier_id, qid)
                    qmjr = qual[:MajorTopicYN]
                    push!(this.qualifier_mjr, qmjr)                   
                end
            else
                qual = NCBIXMLheading["QualifierName"]
                qname = qual[""]
                push!(this.qualifier_name, Nullable(qname))
                
                qid = qual[:UI]
                qid = parse(Int64, qid[2:end])  #remove preceding Q
                push!(this.qualifier_id, qid)

                qmjr = qual[:MajorTopicYN]
                push!(this.qualifier_mjr, qmjr)
            end
        end
        return this
    end
end


# Typealias for natural iteration
const MeshHeadingList =  Vector{MeshHeading}

#Constructor-Like method from XML article element
function MeshHeadingList(NCBIXMLarticle::T) where T <: Associative
    
    if !haskey(NCBIXMLarticle,"MedlineCitation")
        error("MedlineCitation not found")
    end

    # println("===========typeof================")
    # println(typeof(NCBIXMLarticle))

    this = MeshHeadingList()
    # println("===========typeof================")
    # println(typeof(this))
    medline_citation = NCBIXMLarticle["MedlineCitation"]
    if haskey(medline_citation, "MeshHeadingList")
        if haskey(medline_citation["MeshHeadingList"], "MeshHeading")
            xml_mesh_headings = medline_citation["MeshHeadingList"]["MeshHeading"]
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
