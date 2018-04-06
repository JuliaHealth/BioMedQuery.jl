using DataStructures
using Missings


# Given a multidict and a key, this function returns either the
# (single) value for that key, or `nothing`. Thus, it assumes we
# want single element result, otherwise a warning is printed.
function get_if_exists(dict, k)
    return haskey(dict, k) ? dict[k] : missing
end

# Note: If needed it could be further refactored to to that author, journal is a type
"""
    PubMedArticle
Type that matches the NCBI-XML contents for a PubMedArticle
"""
mutable struct PubMedArticle
    types::Vector{Union{String, Missing}}
    pmid::Union{Missing, Int64}
    url::Union{Missing, String}
    title::Union{Missing, String}
    authors::Vector{Dict{Symbol,Union{Missing, String}}}
    year::Union{Missing, Int64}
    journal::Union{Missing, String}
    volume::Union{Missing, String}
    issue::Union{Missing, String}
    abstract_text::Union{Missing, String}
    pages::Union{Missing, String}
    mesh::Vector{Union{String, Missing}}
    affiliations::Vector{Union{String, Missing}}

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

        if ismissing(this.pmid)
            error("PMID not found")
        end

        this.url = string("http://www.ncbi.nlm.nih.gov/pubmed/", this.pmid)

        status = haskey(medline_citation,:Status) ? medline_citation[:Status]:""

        if status != "MEDLINE"
            println("Warning: Article with PMID: ", this.pmid, " may have missing fields. MEDLINE status: ", status)
        end

        # Retrieve basic article info
        if haskey(medline_citation,"Article")
            medline_article = medline_citation["Article"]
            this.types = Vector{Union{Missing, String}}(0)
            if haskey(medline_article, "PublicationTypeList")
                    if typeof(medline_article["PublicationTypeList"]["PublicationType"]) <: Array
                        for pub_type_xml in medline_article["PublicationTypeList"]["PublicationType"]
                            push!(this.types, pub_type_xml[""])
                        end
                    else
                        push!(this.types, medline_article["PublicationTypeList"]["PublicationType"][""])
                    end
            end

            this.title = get_if_exists(medline_article, "ArticleTitle")

            if haskey(medline_article, "Journal")
                this.journal = get_if_exists(medline_article["Journal"], "ISOAbbreviation")
                if haskey(medline_article["Journal"], "JournalIssue")
                    this.volume = get_if_exists(medline_article["Journal"]["JournalIssue"], "Volume")
                    this.issue = get_if_exists(medline_article["Journal"]["JournalIssue"], "Issue")
                end
            end


            if haskey(medline_article,"Pagination")
                this.pages = get_if_exists(medline_article["Pagination"], "MedlinePgn")
            end

            this.year = missing

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
                        println("Warning: No Date found, PMID: ", this.pmid)
                    end
                end
            end

            this.abstract_text = missing
            if haskey(medline_article, "Abstract")
                try
                    this.abstract_text = get_if_exists(medline_article["Abstract"], "AbstractText" )
                catch
                    text = ""
                    for abs in medline_article["Abstract"]["AbstractText"]
                        try
                           text = string(text, abs[:Label], ": ", abs[""], " ")
                        catch
                            println("Warning: No Abstract Text: ", abs, " - PMID: ", this.pmid)
                        end
                    end
                    this.abstract_text = text
                    # println(this.abstract_text)
                end
            else
                println("Warning: No Abstract Text found, PMID: ", this.pmid)
            end

            # Get authors
            this.authors = Vector{Dict{Symbol,Union{Missing,String}}}()
            this.affiliations = Vector{Union{Missing, String}}(0)
            if haskey(medline_article, "AuthorList")
                authors_list = medline_article["AuthorList"]["Author"]
                if typeof(authors_list) <: Array
                    for author in authors_list
                        if author[:ValidYN] == "N"
                            println("Skipping Author Valid:N: ", author)
                            continue
                        end
                        forname = get_if_exists(author, "ForeName")
                        initials = get_if_exists(author, "Initials")
                        lastname = get_if_exists(author, "LastName")
                        
                        if haskey(author, "AffiliationInfo")
                            if typeof(author["AffiliationInfo"]) <: Array
                                for aff in author["AffiliationInfo"]
                                    push!(this.affiliations, aff["Affiliation"])
                                end
                            else
                                push!(this.affiliations, get_if_exists(author["AffiliationInfo"], "Affiliation"))
                            end
                        end

                        if ismissing(lastname)
                            println("Skipping Author: ", author)
                            continue
                        end

                        push!(this.authors, Dict(:ForeName=> forname, :LastName=> lastname, :Initials=> initials))
                    end
                else           
                    author = authors_list
                    if author[:ValidYN] == "Y"                       
                        forname = author["ForeName"]
                        initials = get_if_exists(author, "Initials")
                        lastname = author["LastName"]
                        
                        if haskey(author, "AffiliationInfo")
                            if typeof(author["AffiliationInfo"]) <: Array
                                for aff in author["AffiliationInfo"]
                                    push!(this.affiliations, aff["Affiliation"])
                                end
                            else
                                push!(this.affiliations, get_if_exists(author["AffiliationInfo"], "Affiliation"))
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
        this.mesh = Vector{Union{Missing, String}}(0)
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
                    push!(this.mesh, descriptor_name)
                end
            end
        end
        
        return this
    
    end

end #struct


mutable struct MeshHeading
    descriptor_name::Union{Missing, String}
    descriptor_id::Union{Missing, Int64}
    descriptor_mjr::Union{Missing, String}
    qualifier_name::Vector{Union{Missing, String}}
    qualifier_id::Vector{Union{Missing, Int64}}
    qualifier_mjr::Vector{Union{Missing, String}}

    #Constructor from XML heading element
    function MeshHeading(NCBIXMLheading)

        # A Mesh Heading is composed of ONE descriptor and 0/MANY qualifiers
        if !haskey(NCBIXMLheading, "DescriptorName")
            error("Error: MeshHeading must have DescriptorName")
        end

        this = new()

        #Descriptor
        this.descriptor_name = NCBIXMLheading["DescriptorName"][""]


        # if !ismissing(descriptor_name)
        #     this.descriptor_name = normalize_string(descriptor_name, casefold=true)
        # end

        did = NCBIXMLheading["DescriptorName"][:UI]
        this.descriptor_id = parse(Int64, did[2:end])  #remove preceding D
        this.descriptor_mjr = NCBIXMLheading["DescriptorName"][:MajorTopicYN]


        #Qualifier
        this.qualifier_name = Vector{Union{Missing, String}}()
        this.qualifier_id = Vector{Union{Missing, Int64}}()
        this.qualifier_mjr = Vector{Union{Missing, String}}()
        if haskey(NCBIXMLheading,"QualifierName")
            qualifiers = NCBIXMLheading["QualifierName"]
            if typeof(qualifiers) <: Array
                for qual in qualifiers
                    qname = qual[""]
                    # qname = normalize_string(qname, casefold=true)
                    push!(this.qualifier_name, qname)
                    qid = qual[:UI]
                    qid = parse(Int64, qid[2:end])  #remove preceding Q
                    push!(this.qualifier_id, qid)
                    qmjr = qual[:MajorTopicYN]
                    push!(this.qualifier_mjr, qmjr)                   
                end
            else
                qual = NCBIXMLheading["QualifierName"]
                qname = qual[""]
                push!(this.qualifier_name, qname)
                
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
