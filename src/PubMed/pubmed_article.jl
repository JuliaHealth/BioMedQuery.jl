using DataStructures
using Missings
using EzXML
using LightXML


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

    # Constructor from XMLDict heading element
    function Author(xml)

        this = new()

        this.first_name = get_if_exists(xml, "ForeName")
        this.initials = get_if_exists(xml, "Initials")
        this.last_name = get_if_exists(xml, "LastName")
        this.suffix = get_if_exists(xml, "Suffix")

        this.orc_id = missing
        if haskey(xml, "Identifier")
            if xml["Identifier"][:Source]=="ORCID"
                this.orc_id = parse_orcid(xml["Identifier"][""])
            end
        end

        this.collective = get_if_exists(xml, "Collective")

        this.affiliations = Vector{Union{Missing, String}}(0)
        if haskey(xml, "AffiliationInfo")
            if typeof(xml["AffiliationInfo"]) <: Array
                for aff in xml["AffiliationInfo"]
                    push!(this.affiliations, aff["Affiliation"])
                end
            else
                push!(this.affiliations, get_if_exists(xml["AffiliationInfo"], "Affiliation"))
            end
        end

        return this
    end

    # Constructor from EzXML heading element
    function Author(xml::EzXML.Node)

        this = new()

        this.first_name = missing
        this.initials = missing
        this.last_name = missing
        this.suffix = missing
        this.orc_id = missing
        this.collective = missing
        this.affiliations = Vector{String}()

        for names in eachelement(xml)
            names_name = nodename(names)
            if names_name == "LastName"
                lname = nodecontent(xml)
            elseif names_name == "ForeName"
                fname = nodecontent(names)
            elseif names_name == "Initials"
                inits = nodecontent(names)
            elseif names_name == "Suffix"
                suffix = nodecontent(names)
            elseif names_name == "Identifer" && names["Source"] == "ORCID"
                orcid = parse_orcid(nodecontent(names))
            elseif names_name == "CollectiveName"
                collective = nodecontent(names)
            elseif names_name == "AffiliationInfo"
                for affiliates in eachelement(names)
                    if nodename(affiliates) == "Affiliation"
                        push!(this.affiliations, nodecontent(affiliates))
                    end
                end
            end
        end

        return this
    end

    # Constructor from LightXML heading element
    function Author(xml::LightXML.XMLElement)

        this = new()

        this.first_name = missing
        this.initials = missing
        this.last_name = missing
        this.suffix = missing
        this.orc_id = missing
        this.collective = missing
        this.affiliations = Vector{String}()

        for names in child_elements(xml)
            names_name = name(names)
            if names_name == "LastName"
                lname = content(xml)
            elseif names_name == "ForeName"
                fname = content(names)
            elseif names_name == "Initials"
                inits = content(names)
            elseif names_name == "Suffix"
                suffix = content(names)
            elseif names_name == "Identifer" && names["Source"] == "ORCID"
                orcid = parse_orcid(content(names))
            elseif names_name == "CollectiveName"
                collective = content(names)
            elseif names_name == "AffiliationInfo"
                for affiliates in child_elements(names)
                    if name(affiliates) == "Affiliation"
                        push!(this.affiliations, content(affiliates))
                    end
                end
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
    date_desc::Union{String, Missing}

    # Constructor from XMLDict heading element
    function MedlineDate(xml)

        this = new()

        if haskey(xml, "MedlineDate")
            ystr, mstr = parse_MedlineDate(xml["MedlineDate"])
        else
            ystr = xml["Year"]
            if haskey(xml, "Month")
                mstr = xml["Month"]
            elseif haskey(xml, "Season")
                mstr = xml["Season"]
            else
                mstr = ""
            end
        end

        this.year = parse_year(ystr)
        this.month = parse_month(mstr)
        this.date_desc = ystr * (mstr == "" ? "" : " " * mstr)

        return this
    end

    # Constructor from EzXML heading element
    function MedlineDate(xml::EzXML.Node)

        this = new()

        ystr = ""
        mstr = ""
        for child in eachelement(xml)
            if nodename(child) == "MedlineDate"
                ystr, mstr = parse_MedlineDate(nodecontent(child))
            elseif nodename(child) == "Year"
                ystr = nodecontent(child)
            elseif nodename(child) == "Month" || nodename(child) == "Season"
                mstr = nodecontent(child)
            end
        end

        this.year = parse_year(ystr)
        this.month = parse_month(mstr)
        this.date_desc = ystr * (mstr == "" ? "" : " " * mstr)

        return this
    end

    # Constructor from LightXML heading element
    function MedlineDate(xml::LightXML.XMLElement)

        this = new()

        ystr = ""
        mstr = ""
        for child in child_elements(xml)
            if name(child) == "MedlineDate"
                ystr, mstr = parse_MedlineDate(content(child))
            elseif name(child) == "Year"
                ystr = content(child)
            elseif name(child) == "Month" || name(child) == "Season"
                mstr = content(child)
            end
        end

        this.year = parse_year(ystr)
        this.month = parse_month(mstr)
        this.date_desc = ystr * (mstr == "" ? "" : " " * mstr)

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

    # Constructor from XMLDict heading element
    function StructuredAbstract(xml)

        this = new()

        this.nlm_category = get_if_exists(xml, :NlmCategory)
        this.label = get_if_exists(xml, :Label)
        this.text = xml[""]

        return this
    end

    # Constructor from EzXML heading element
    function StructuredAbstract(xml::EzXML.Node)

        this = new()

        this.nlm_category = haskey(xml, "NlmCategory") ? xml["NlmCategory"] : missing
        this.label = haskey(xml, "Label") ? xml["Label"] : missing
        this.text = nodecontent(xml)

        return this
    end

    function StructuredAbstract(xml::LightXML.XMLElement)

        this = new()

        this.nlm_category = has_attribute(xml, "NlmCategory") ? attribute(xml,"NlmCategory") : missing
        this.label = has_attribute(xml, "Label") ? attribute(xml,"Label") : missing
        this.text = content(xml)

        return this
    end
end

"""
    PubType
Type that matches the NCBI-XML contents for a Publication Type
"""
mutable struct PubType
    uid::Union{Missing, Int64}
    name::Union{Missing, String}

    function PubType(xml)

        this = new()

        this.name = xml[""]
        ui = xml[:UI]
        this.uid = length(ui) > 1 ? parse(Int64, ui[2:end]) : missing

        return this
    end

    function PubType(xml::EzXML.Node)

        this = new()

        this.name = nodecontent(xml)
        ui = xml["UI"]
        this.uid = length(ui) > 1 ? parse(Int64, ui[2:end]) : missing

        return this
    end

    function PubType(xml::LightXML.XMLElement)

        this = new()

        this.name = content(xml)
        ui = attribute(xml,"UI")
        this.uid = length(ui) > 1 ? parse(Int64, ui[2:end]) : missing

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

    function MeshQualifier(xml)

        this = new()

        this.name = xml[""]
        ui = xml[:UI]
        this.uid = length(ui) > 1 ? parse(Int64, ui[2:end]) : missing

        return this
    end

    function MeshQualifier(xml::EzXML.Node)

        this = new()

        this.name = nodecontent(xml)
        ui = xml["UI"]
        this.uid = length(ui) > 1 ? parse(Int64, ui[2:end]) : missing

        return this
    end

    function MeshQualifier(xml::LightXML.XMLElement)

        this = new()

        this.name = content(xml)
        ui = attribute(xml, "UI")
        this.uid = length(ui) > 1 ? parse(Int64, ui[2:end]) : missing

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

    function MeshDescriptor(xml)

        this = new()

        this.name = xml[""]
        ui = xml[:UI]
        this.uid = length(ui) > 1 ? parse(Int64, ui[2:end]) : missing

        return this
    end

    function MeshDescriptor(xml::EzXML.Node)

        this = new()

        this.name = nodecontent(xml)
        ui = xml["UI"]
        this.uid = length(ui) > 1 ? parse(Int64, ui[2:end]) : missing

        return this
    end

    function MeshDescriptor(xml::LightXML.XMLElement)

        this = new()

        this.name = content(xml)
        ui = attribute(xml,"UI")
        this.uid = length(ui) > 1 ? parse(Int64, ui[2:end]) : missing

        return this
    end

end

"""
    MeshHeading
Type that matches the NCBI-XML contents for a MeshHeading
"""
mutable struct MeshHeading
    descriptor::MeshDescriptor
    descriptor_mjr::Int64
    qualifier::Vector{MeshQualifier}
    qualifier_mjr::Vector{Int64}

    #Constructor from XMLDict heading element
    function MeshHeading(xml)

        # A Mesh Heading is composed of ONE descriptor and 0/MANY qualifiers
        if !haskey(xml, "DescriptorName")
            error("Error: MeshHeading must have DescriptorName")
        end

        this = new()

        #Descriptor
        this.descriptor = MeshDescriptor(xml["DescriptorName"])
        this.descriptor_mjr = xml["DescriptorName"][:MajorTopicYN] == "Y" ? 1 : 0


        #Qualifier
        this.qualifier = Vector{MeshQualifier}()
        this.qualifier_mjr = Vector{Int64}()
        if haskey(xml,"QualifierName")
            qualifiers = xml["QualifierName"]
            if typeof(qualifiers) <: Array
                for qual in qualifiers
                    q = MeshQualifier(qual)
                    push!(this.qualifier, q)

                    qmjr = qual[:MajorTopicYN] == "Y" ? 1 : 0
                    push!(this.qualifier_mjr, qmjr)
                end
            else
                qual = MeshQualifier(qualifiers)
                push!(this.qualifier, qual)

                qmjr = qualifiers[:MajorTopicYN] == "Y" ? 1 : 0
                push!(this.qualifier_mjr, qmjr)
            end
        end

        return this
    end

    #Constructor from EzXML heading element
    function MeshHeading(xml::EzXML.Node)

        this = new()

        # Initialize Qualifier Vectorss
        this.qualifier = Vector{MeshQualifier}()
        this.qualifier_mjr = Vector{Int64}()

        for header in eachelement(xml)
            header_name = nodename(header)
            if header_name == "DescriptorName"
                this.descriptor = MeshDescriptor(header)
                this.descriptor_mjr = header["MajorTopicYN"] == "Y" ? 1 : 0
            elseif header_name == "QualifierName"
                push!(this.qualifier, MeshQualifier(header))
                push!(this.qualifier_mjr, (header["MajorTopicYN"] == "Y" ? 1 : 0))
            end
        end

        return this
    end

    #Constructor from LightXML heading element
    function MeshHeading(xml::LightXML.XMLElement)

        this = new()

        # Initialize Qualifier Vectorss
        this.qualifier = Vector{MeshQualifier}()
        this.qualifier_mjr = Vector{Int64}()

        for header in child_elements(xml)
            header_name = name(header)
            if header_name == "DescriptorName"
                this.descriptor = MeshDescriptor(header)
                this.descriptor_mjr = attribute(header,"MajorTopicYN") == "Y" ? 1 : 0
            elseif header_name == "QualifierName"
                push!(this.qualifier, MeshQualifier(header))
                push!(this.qualifier_mjr, (attribute(header,"MajorTopicYN") == "Y" ? 1 : 0))
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
    types::Vector{PubType}
    pmid::Union{Missing, Int64}
    url::Union{Missing, String}
    title::Union{Missing, String}
    auth_cite::Union{Missing, String}
    authors::Vector{Author}
    date::Union{Missing, MedlineDate}
    journal_title::Union{Missing, String}
    journal_iso_abbrv::Union{Missing, String}
    journal_issn::Union{Missing, String}
    volume::Union{Missing, String}
    issue::Union{Missing, String}
    abstract_full::Union{Missing, String}
    abstract_structured::Vector{StructuredAbstract}
    pages::Union{Missing, String}
    mesh::Vector{MeshHeading}

    #Constructor from XMLDict article element
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
        println("PMID: ",this.pmid)

        this.url = string("http://www.ncbi.nlm.nih.gov/pubmed/", this.pmid)

        status = haskey(medline_citation,:Status) ? medline_citation[:Status]:""

        if status != "MEDLINE"
            println("Warning: Article with PMID: ", this.pmid, " may have missing fields. MEDLINE status: ", status)
        end

        # Retrieve basic article info
        if haskey(medline_citation,"Article")
            medline_article = medline_citation["Article"]
            this.types = Vector{PubType}()
            if haskey(medline_article, "PublicationTypeList")
                    if typeof(medline_article["PublicationTypeList"]["PublicationType"]) <: Array
                        for pub_type_xml in medline_article["PublicationTypeList"]["PublicationType"]
                            push!(this.types, PubType(pub_type_xml))
                        end
                    else
                        push!(this.types, PubType(medline_article["PublicationTypeList"]["PublicationType"]))
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
            this.abstract_structured = Vector{StructuredAbstract}()
            if haskey(medline_article, "Abstract")
                text = medline_article["Abstract"]["AbstractText"]
                if typeof(text) <: Array
                    full_text = ""
                    for abs in text
                        struct_abs = StructuredAbstract(abs)
                        push!(this.abstract_structured, struct_abs)
                        full_text *= (ismissing(struct_abs.label) ? "NO LABEL" : struct_abs.label) * ": " * struct_abs.text * " "
                    end
                    this.abstract_full = full_text[1:end-1]
                elseif !(typeof(text) <: AbstractString)
                    this.abstract_full = text[""]
                    push!(this.abstract_structured, StructuredAbstract(text))
                else
                    this.abstract_full = text
                end
            else
                println("Warning: No Abstract Text found, PMID: ", this.pmid)
            end

            # Get authors
            this.authors = Vector{Author}()
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
        this.mesh = Vector{MeshHeading}()
        if haskey(medline_citation, "MeshHeadingList")
            if haskey(medline_citation["MeshHeadingList"], "MeshHeading")
                mesh_headings = medline_citation["MeshHeadingList"]["MeshHeading"]
                if typeof(mesh_headings) <: Array
                    for heading in mesh_headings
                        push!(this.mesh, MeshHeading(heading))
                    end
                else
                    push!(this.mesh, MeshHeading(mesh_headings))
                end
            end
        end

        return this

    end

    #Constructor from EzXML article element
    function PubMedArticle(xml::EzXML.Node)

        this = new()

        for tdat in eachelement(xml)
            if nodename(tdat) == "MedlineCitation"
                for el in eachelement(tdat)
                    el_name = nodename(el)

                    this.mesh = Vector{MeshHeading}()

                    if el_name == "PMID"
                        this.pmid = parse(Int, nodecontent(el))
                        this.url = string("http://www.ncbi.nlm.nih.gov/pubmed/", this.pmid)
                    elseif el_name == "Article"

                        # initialize vars to be collected in this loop
                        this.pages = missing
                        this.auth_cite = ""
                        this.authors = Vector{Author}()
                        this.types = Vector{PubType}()
                        this.abstract_full = missing
                        this.abstract_structured = Vector{StructuredAbstract}()

                        for child in eachelement(el)
                            child_name = nodename(child)
                            if child_name == "Journal"

                                # Initialize vars to be collected in this loop
                                this.journal_issn = missing
                                this.journal_title = missing
                                this.journal_iso_abbrv = missing

                                for journal in eachelement(child)
                                    journal_name = nodename(journal)
                                    if journal_name == "ISSN"
                                        this.journal_issn = nodecontent(journal)
                                    elseif journal_name == "JournalIssue"

                                        # Initialize vars to be collected in this loop
                                        this.volume = missing
                                        this.issue = missing

                                        for issue in eachelement(journal)
                                            issue_name = nodename(issue)
                                            # Assign & parse variables
                                            if issue_name == "Volume"
                                                this.volume = nodecontent(issue)
                                            elseif issue_name == "Issue"
                                                this.issue = nodecontent(issue)
                                            elseif issue_name == "PubDate"
                                                this.date = MedlineDate(issue)
                                            end
                                        end

                                    elseif journal_name == "Title"
                                        this.journal_title = nodecontent(journal)
                                    elseif journal_name == "ISOAbbreviation"
                                        this.journal_iso_abbrv = nodecontent(journal)
                                    end
                                end

                            elseif child_name == "ArticleTitle"
                                this.title = nodecontent(child)
                            elseif child_name == "Pagination"

                                start_page = ""
                                end_page = ""
                                journal_page = ""

                                for pages in eachelement(child)
                                    pages_name = nodename(pages)
                                    if pages_name == "StartPage"
                                        start_page = nodecontent(pages)
                                    elseif pages_name == "EndPage"
                                        end_page = nodecontent(pages)
                                    elseif pages_name == "MedlinePgn"
                                        journal_page = nodecontent(pages)
                                    end
                                end

                                this.pages = !ismissing(journal_page) ? journal_page : start_page * (end_page == "" ? "" : "-"*end_page)

                            elseif child_name == "Abstract"

                                this.abstract_full = ""
                                if nodename(lastelement(child)) == "CopyrightInformation" ? countelements(child) > 2 : countelements(child) > 1
                                    for txt in eachelement(child)
                                        if nodename(txt) == "AbstractText"
                                            struct_abs = StructuredAbstract(txt)
                                            push!(this.abstract_structured, struct_abs)
                                            this.abstract_full *= haskey(txt, "Label") ? txt["Label"] * ": " * struct_abs.text * " " : "NO LABEL: " * struct_abs.text * " "
                                        end
                                    end
                                    this.abstract_full = this.abstract_full[1:end-1]
                                else
                                    this.abstract_full = nodecontent(firstelement(child))
                                end

                            elseif child_name == "AuthorList"
                                for auth in eachelement(child)
                                    this_auth = Author(auth)
                                    push!(this.authors, this_auth)

                                    this.auth_cite *= !ismissing(this_auth.first_name) ? "$(this_auth.last_name), $(this_auth.first_name); " : (!ismissing(this_auth.last_name) ? "$(this_auth.last_name); " : "")
                                end
                                this.auth_cite = this.auth_cite[1:end-2]

                            elseif child_name == "PublicationTypeList"
                                for pubtype in eachelement(child)
                                    push!(this.types, PubType(pubtype))
                                end
                            end
                        end

                    elseif el_name == "MeshHeadingList"
                        for heading in eachelement(el)
                            push!(this.mesh, MeshHeading(heading))
                        end
                    end
                end
            end
        end

        return this

    end

    #Constructor from EzXML article element
    function PubMedArticle(xml::LightXML.XMLElement)

        this = new()

        for tdat in child_elements(xml)
            if name(tdat) == "MedlineCitation"
                for el in child_elements(tdat)
                    el_name = name(el)

                    this.mesh = Vector{MeshHeading}()

                    if el_name == "PMID"
                        this.pmid = parse(Int, content(el))
                        this.url = string("http://www.ncbi.nlm.nih.gov/pubmed/", this.pmid)
                    elseif el_name == "Article"

                        # initialize vars to be collected in this loop
                        this.pages = missing
                        this.auth_cite = ""
                        this.authors = Vector{Author}()
                        this.types = Vector{PubType}()
                        this.abstract_full = missing
                        this.abstract_structured = Vector{StructuredAbstract}()

                        for child in child_elements(el)
                            child_name = name(child)
                            if child_name == "Journal"

                                # Initialize vars to be collected in this loop
                                this.journal_issn = missing
                                this.journal_title = missing
                                this.journal_iso_abbrv = missing

                                for journal in child_elements(child)
                                    journal_name = name(journal)
                                    if journal_name == "ISSN"
                                        this.journal_issn = content(journal)
                                    elseif journal_name == "JournalIssue"

                                        # Initialize vars to be collected in this loop
                                        this.volume = missing
                                        this.issue = missing

                                        for issue in child_elements(journal)
                                            issue_name = name(issue)
                                            # Assign & parse variables
                                            if issue_name == "Volume"
                                                this.volume = content(issue)
                                            elseif issue_name == "Issue"
                                                this.issue = content(issue)
                                            elseif issue_name == "PubDate"
                                                this.date = MedlineDate(issue)
                                            end
                                        end

                                    elseif journal_name == "Title"
                                        this.journal_title = content(journal)
                                    elseif journal_name == "ISOAbbreviation"
                                        this.journal_iso_abbrv = content(journal)
                                    end
                                end

                            elseif child_name == "ArticleTitle"
                                this.title = content(child)
                            elseif child_name == "Pagination"

                                start_page = ""
                                end_page = ""
                                journal_page = ""

                                for pages in child_elements(child)
                                    pages_name = name(pages)
                                    if pages_name == "StartPage"
                                        start_page = content(pages)
                                    elseif pages_name == "EndPage"
                                        end_page = content(pages)
                                    elseif pages_name == "MedlinePgn"
                                        journal_page = content(pages)
                                    end
                                end

                                this.pages = !ismissing(journal_page) ? journal_page : start_page * (end_page == "" ? "" : "-"*end_page)

                            elseif child_name == "Abstract"

                                this.abstract_full = ""
                                if length(get_elements_by_tagname(child, "AbstractText")) >1
                                    for txt in child_elements(child)
                                        if name(txt) == "AbstractText"
                                            struct_abs = StructuredAbstract(txt)
                                            push!(this.abstract_structured, struct_abs)
                                            this.abstract_full *= has_attribute(txt, "Label") ? attribute(txt, "Label") * ": " * struct_abs.text * " " : "NO LABEL: " * struct_abs.text * " "
                                        end
                                    end
                                    this.abstract_full = this.abstract_full[1:end-1]
                                elseif has_attribute(find_element(child, "AbstractText"), "Label")
                                    struct_abs = StructuredAbstract(find_element(child, "AbstractText"))
                                    push!(this.abstract_structured, struct_abs)
                                    this.abstract_full = struct_abs.text
                                else
                                    this.abstract_full = content(find_element(child, "AbstractText"))
                                end

                            elseif child_name == "AuthorList"
                                for auth in child_elements(child)
                                    this_auth = Author(auth)
                                    push!(this.authors, this_auth)

                                    this.auth_cite *= !ismissing(this_auth.first_name) ? "$(this_auth.last_name), $(this_auth.first_name); " : (!ismissing(this_auth.last_name) ? "$(this_auth.last_name); " : "")
                                end
                                this.auth_cite = this.auth_cite[1:end-2]

                            elseif child_name == "PublicationTypeList"
                                for pubtype in child_elements(child)
                                    push!(this.types, PubType(pubtype))
                                end
                            end
                        end

                    elseif el_name == "MeshHeadingList"
                        for heading in child_elements(el)
                            push!(this.mesh, MeshHeading(heading))
                        end
                    end
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
