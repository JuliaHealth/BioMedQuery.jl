using DataStructures
using Missings


# Given a multidict and a key, this function returns either the
# (single) value for that key, or `nothing`. Thus, it assumes we
# want single element result, otherwise a warning is printed.
function get_if_exists(dict, k)
    return haskey(dict, k) ? dict[k] : missing
end


"""
    parse_MedlineDate(ml_dt::String)
Parses the contents of the MedlineDate element and returns a tuple of the year and month.
"""
function parse_MedlineDate(ml_dt::String)
    year = ""
    month = ""
    matches = split(ml_dt, " ", limit = 2) # WORKING ON GETTING THIS TO WORK WHEN NO MONTH PRESENT
    try
        year = matches[1]
        month = matches[2]
    catch
        println("Couldn't fully parse date: ", ml_dt)
    end

    return year, month
end

"""
    parse_year(yr::String)
Parses the string year and returns an integer with the first year in range.
"""
function parse_year(yr::AbstractString)
    try
        parse(Int64, yr[1:4])
    catch
        missing
    end

end

"""
    parse_month(mon::String)
Parses the string month (month or season) and returns an integer with the first month in range.
"""
function parse_month(mon::AbstractString)
    try
        trim_mon = lowercase(mon[1:3])

        if trim_mon == "jan" || trim_mon == "win"
            1
        elseif trim_mon == "feb"
            2
        elseif trim_mon == "mar"
            3
        elseif trim_mon == "apr" || trim_mon == "spr"
            4
        elseif trim_mon == "may"
            5
        elseif trim_mon == "jun"
            6
        elseif trim_mon == "jul" || trim_mon == "sum"
            7
        elseif trim_mon == "aug"
            8
        elseif trim_mon == "sep"
            9
        elseif trim_mon == "oct" || trim_mon == "fal"
            10
        elseif trim_mon == "nov"
            11
        elseif trim_mon == "dec"
            12
        else
            missing
        end

    catch
        missing
    end

end

"""
    parse_orcid(raw_orc::String)
Takes a string containing an ORC ID (url, 16 digit string) and returns a formatted ID (0000-1111-2222-3333).
"""
function parse_orcid(raw_orc::String)
    if ismatch(r"^[0-9]{16}$", raw_orc)
        return "$(raw_orc[1:4])-$(raw_orc[5:8])-$(raw_orc[9:12])-$(raw_orc[13:16])"
    else
        reg = match(r"^.*([0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{4}).*$", raw_orc)

        return reg.match == nothing ? "PARSE_ERROR" : reg.captures[1]
    end
end

"""
    Author
Type that matches the NCBI-XML contents for an Author
"""
mutable struct Author
    last_name::Union{Missing, String}
    first_name::Union{Missing, String}
    initials::Union{Missing, String}
    suffix::Union{Missing, String}
    orc_id::Union{Missing, String}
    collective::Union{Missing, String}
    affiliations::Vector{Union{Missing, String}}

    # Constructor from XML heading element
    function Author(NCBIXMLheading)

        this = new()

        this.first_name = get_if_exists(NCBIXMLheading, "ForeName")
        this.initials = get_if_exists(NCBIXMLheading, "Initials")
        this.last_name = get_if_exists(NCBIXMLheading, "LastName")
        this.suffix = get_if_exists(NCBIXMLheading, "Suffix")

        this.orc_id = missing
        if haskey(NCBIXMLheading, "Identifier")
            if NCBIXMLheading["Identifier"][:Source]=="ORCID"
                this.orc_id = parse_orcid(NCBIXMLheading["Identifier"])
            end
        end

        this.collective = get_if_exists(NCBIXMLheading, "Collective")

        this.affiliations = Vector{Union{Missing, String}}(0)
        if haskey(NCBIXMLheading, "AffiliationInfo")
            if typeof(NCBIXMLheading["AffiliationInfo"]) <: Array
                for aff in NCBIXMLheading["AffiliationInfo"]
                    push!(this.affiliations, aff["Affiliation"])
                end
            else
                push!(this.affiliations, get_if_exists(NCBIXMLheading["AffiliationInfo"], "Affiliation"))
            end
        end

        return this
    end
end

"""
    MedlineDate
Type that matches the NCBI-XML contents for a PubDate
"""
mutable struct MedlineDate
    year::Union{Int64, Missing}
    month::Union{Int64, Missing}
    desc::Union{String, Missing}

    # Constructor from XML heading element
    function MedlineDate(NCBIXMLheading)

        this = new()

        if haskey(NCBIXMLheading, "MedlineDate")
            ystr, mstr = parse_MedlineDate(NCBIXMLheading["MedlineDate"])
        else
            ystr = NCBIXMLheading["Year"]
            if haskey(NCBIXMLheading, "Month")
                mstr = NCBIXMLheading["Month"]
            elseif haskey(NCBIXMLheading, "Season")
                mstr = NCBIXMLheading["Season"]
            else
                mstr = ""
            end
        end

        this.year = parse_year(ystr)
        this.month = parse_month(mstr)
        this.desc = ystr * (mstr == "" ? "" : " " * mstr)

        return this
    end
end

"""
    StructuredAbstract
Type that matches the NCBI-XML contents for a structured abstract (abstract that has label or nlm category)
"""
mutable struct StructuredAbstract
    nlm_category::Union{String, Missing}
    label::Union{String, Missing}
    text::Union{String, Missing}

    # Constructor from XML heading element
    function StructuredAbstract(NCBIXMLheading)

        this = new()

        this.nlm_category = get_if_exists(NCBIXMLheading, :NlmCategory)
        this.label = get_if_exists(NCBIXMLheading, :Label)
        this.text = get_if_exists(NCBIXMLheading, "")

        return this
    end
end

"""
    MeshQualifier
Type that matches the NCBI-XML contents for a MeSH Qualifier
"""
mutable struct MeshQualifier
    uid::Union{Missing, Int64}
    name::Union{Missing, String}

    function MeshQualifier(NCBIXMLheading)

        this = new()

        this.name = NCBIXMLheading[""]
        ui = NCBIXMLheading[:UI]
        this.uid = parse(Int64, ui[2:end])

        return this
    end
end

"""
    MeshDescriptor
Type that matches the NCBI-XML contents for a MeSH Descriptor
"""
mutable struct MeshDescriptor
    uid::Union{Missing, Int64}
    name::Union{Missing, String}

    function MeshDescriptor(NCBIXMLheading)

        this = new()

        this.name = NCBIXMLheading[""]
        ui = NCBIXMLheading[:UI]
        this.uid = parse(Int64, ui[2:end])

        return this
    end

end

"""
    MeshHeading
Type that matches the NCBI-XML contents for a MeshHeading
"""
mutable struct MeshHeading
    descriptor::Union{Missing, MeshDescriptor}
    descriptor_mjr::Union{Missing, String}
    qualifier::Vector{Union{Missing, MeshQualifier}}
    qualifier_mjr::Vector{Union{Missing, String}}

    #Constructor from XML heading element
    function MeshHeading(NCBIXMLheading)

        # A Mesh Heading is composed of ONE descriptor and 0/MANY qualifiers
        if !haskey(NCBIXMLheading, "DescriptorName")
            error("Error: MeshHeading must have DescriptorName")
        end

        this = new()

        #Descriptor
        this.descriptor = MeshDescriptor(NCBIXMLheading["DescriptorName"])
        this.descriptor_mjr = NCBIXMLheading["DescriptorName"][:MajorTopicYN]


        #Qualifier
        this.qualifier = Vector{Union{Missing, MeshQualifier}}()
        this.qualifier_mjr = Vector{Union{Missing, String}}()
        if haskey(NCBIXMLheading,"QualifierName")
            qualifiers = NCBIXMLheading["QualifierName"]
            if typeof(qualifiers) <: Array
                for qual in qualifiers
                    q = MeshQualifier(qual)
                    push!(this.qualifier, q)

                    qmjr = qual[:MajorTopicYN]
                    push!(this.qualifier_mjr, qmjr)
                end
            else
                qual = MeshQualifier(qualifiers)
                push!(this.qualifier, qual)

                qmjr = qualifiers[:MajorTopicYN]
                push!(this.qualifier_mjr, qmjr)
            end
        end

        return this
    end
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
    auth_cite::Union{Missing, String}
    authors::Vector{Union{Author, Missing}}
    date::Union{Missing, MedlineDate}
    journal_title::Union{Missing, String}
    journal_iso_abbrv::Union{Missing, String}
    journal_issn::Union{Missing, String}
    volume::Union{Missing, String}
    issue::Union{Missing, String}
    abstract_full::Union{Missing, String}
    abstract_structured::Vector{Union{Missing, StructuredAbstract}}
    pages::Union{Missing, String}
    mesh::Vector{Union{MeshHeading, Missing}}

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
                this.journal_iso_abbrv = get_if_exists(medline_article["Journal"], "ISOAbbreviation")
                this.journal_title = get_if_exists(medline_article["Journal"], "Title")
                if haskey(medline_article["Journal"], "ISSN")
                    this.journal_issn = medline_article["Journal"]["ISSN"][""]
                else
                    this.journal_issn = missing
                end
                if haskey(medline_article["Journal"], "JournalIssue")
                    this.volume = get_if_exists(medline_article["Journal"]["JournalIssue"], "Volume")
                    this.issue = get_if_exists(medline_article["Journal"]["JournalIssue"], "Issue")
                    this.date = MedlineDate(medline_article["Journal"]["JournalIssue"]["PubDate"])
                end
            end


            if haskey(medline_article,"Pagination")
                if haskey(medline_article["Pagination"], "MedlinePgn")
                    this.pages = get_if_exists(medline_article["Pagination"], "MedlinePgn")
                else
                    this.pages = medline_article["Pagination"]["StartPage"]
                    end_pg = get_if_exists(medline_article["Pagination"], "EndPage")
                    !ismissing(end_pg) ? this.pages = this.pages * "-" * end_pg : nothing
                end
            end



            this.abstract_full = missing
            this.abstract_structured = missing
            if haskey(medline_article, "Abstract")
                try
                    this.abstract_full = get_if_exists(medline_article["Abstract"], "AbstractText" )
                catch
                    text = ""
                    for abs in medline_article["Abstract"]["AbstractText"]
                        struct_abs = StructuredAbstract(abs)
                        push!(abstract_structured, struct_abs)
                        text *= (ismissing(struct_abs.label) ? "NO LABEL" : sturct_abs.label) * ": " * struct_abs.text * " "
                    end
                    this.abstract_full = text[1:end-1]
                    # println(this.abstract_text)
                end
            else
                println("Warning: No Abstract Text found, PMID: ", this.pmid)
            end

            # Get authors
            this.authors = Vector{Union{Author, Missing}}()
            this.auth_cite = missing
            if haskey(medline_article, "AuthorList")
                authors_list = medline_article["AuthorList"]["Author"]
                auth_cite = ""
                if typeof(authors_list) <: Array
                    for author in authors_list
                        if author[:ValidYN] == "Y"
                            auth = Author(author)
                            push!(this.authors, auth)
                            auth_cite *= (!ismissing(auth.first_name) ? "$(auth.last_name), $(auth.first_name); " : (!ismissing(auth.last_name) ? "$(auth.last_name); " : ""))
                        else
                            println("Skipping Author: ", author)
                        end
                    end
                else
                    author = authors_list
                    if author[:ValidYN] == "Y"
                        auth = Author(author)
                        push!(this.authors, auth)
                        auth_cite *= (!ismissing(auth.first_name) ? "$(auth.last_name), $(auth.first_name); " : (!ismissing(auth.last_name) ? "$(auth.last_name); " : ""))
                    else
                        println("Skipping Author: ", author)
                    end
                end
                this.auth_cite = length(auth_cite) == 0 ? missing : auth_cite[1:end-2]
            end

        end


        # Get MESH Headings (descriptors, qualifiers, major status)
        this.mesh = Vector{Union{Missing, MeshHeading}}(0)
        if haskey(medline_citation, "MeshHeadingList")
            if haskey(medline_citation["MeshHeadingList"], "MeshHeading")
                mesh_headings = medline_citation["MeshHeadingList"]["MeshHeading"]
                for heading in mesh_headings
                    push!(this.mesh, MeshHeading(heading))
                end
            end
        end

        return this

    end

end #struct


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
