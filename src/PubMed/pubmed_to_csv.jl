using DataStructures
using Missings
using EzXML
using LightXML
using CSV


# Given a multidict and a key, this function returns either the
# (single) value for that key, or `nothing`. Thus, it assumes we
# want single element result, otherwise a warning is printed.
function get_if_exists(dict::Dict, k)
    return haskey(dict, k) ? dict[k] : missing
end

function get_if_exists(xml::LightXML.XMLElement, el::String)
    el_val= find_element(xml, el)
    return el_val == nothing ? missing : content(el_val)
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
        warn("Couldn't fully parse date: ", ml_dt)
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
    parse_abstracts!
Takes xml for authors, and updates arrays with new data
"""
function parse_authors!(xml::LightXML.XMLElement, authors::Array, auth_cite::Array, pmid::Int64)

    this_auth_cite = ""

    for author in child_elements(xml)
        lname = get_if_exists(author, "LastName")
        fname = get_if_exists(author, "ForeName")
        inits = get_if_exists(author, "Initials")
        suffix = get_if_exists(author, "Suffix")
        collective = get_if_exists(author, "CollectiveName")

        orcid = missing
        for ids in get_elements_by_tagname(author, "Identifier")
            if attribute(ids, "Source") == "ORCID"
                orcid = parse_orcid(content(ids))
            end
        end

        affs = ""
        for affil_info in get_elements_by_tagname(author, "AffiliationInfo")
            for affiliates in get_elements_by_tagname(affil_info, "Affiliation")
                affs *= content(affiliates) * "; "
            end
        end
        affs = affs == "" ? missing : affs[1:end-2]

        this_auth_cite *= !ismissing(fname) ? "$lname, $fname; " : (!ismissing(lname) ? "$lname; " : "")
        authors = [authors ; [pmid lname fname inits suffix orcid collective affs]]
    end

    push!(auth_cite, (this_auth_cite == "" ? missing : this_auth_cite[1:end-2]))

    return authors, auth_cite
end

"""
    parse_abstracts!
Takes xml for abstracts, and updates arrays with new data
"""
function parse_abstracts!(xml::LightXML.XMLElement, struct_array::Array, full_array::Array, pmid::Int64)

    abstract_full_text = ""
    if length(get_elements_by_tagname(xml, "AbstractText")) >1
        for txt in child_elements(xml)
            if name(txt) == "AbstractText"
                label = attribute(txt, "Label")
                label = label == nothing ? missing : label
                nlm_category = attribute(txt, "NlmCategory")
                nlm_category = nlm_category == nothing ? missing : nlm_category
                abs_text = content(txt)
                struct_array = [struct_array ; [pmid nlm_category label abs_text]]
                abstract_full_text *= !ismissing(label) ? label * ": " * abs_text * " " : "NO LABEL: " * abs_text * " "
            end
        end
        full_array = [full_array ; [pmid abstract_full_text[1:end-1]]]
    else
        full_array = [full_array ; [pmid content(find_element(xml, "AbstractText"))]]
    end

    return struct_array, full_array
end

"""
    parse_pubtypes!
Takes xml for pubtypes, and updates array with new data
"""
function parse_pubtypes!(xml::LightXML.XMLElement, pt_array::Array, pmid::Int64)

    for pt in child_elements(xml)
        desc = content(pt)
        ui = attribute(pt, "UI")
        uid = length(ui) > 1 ? parse(Int64, ui[2:end]) : missing
        pt_array = [pt_array ; [pmid uid desc]]
    end

    return pt_array
end

function parse_meshheadings!(xml::LightXML.XMLElement, mh_arr::Array, md_arr::Array, mq_arr::Array, pmid::Int64)

    for header in child_elements(xml)
        # parse descriptor
        desc = find_element(header, "DescriptorName")
        desc_ui = attribute(desc, "UI")
        desc_uid = length(desc_ui) > 1 ? parse(Int64, desc_ui[2:end]) : missing
        desc_name = content(desc)
        desc_mjr = attribute(header,"MajorTopicYN") == "Y" ? 1 : 0
        # add to mesh descriptor array
        md_arr = [md_arr ; [desc_uid desc_name]]

        quals = header["QualifierName"]
        if quals != nothing
            for qual in quals
                qual_ui = attribute(qual, "UI")
                qual_uid = length(qual_ui) > 1 ? parse(Int64, qual_ui[2:end]) : missing
                qual_name = content(qual)
                qual_mjr = attribute(qual, "MajorTopicYN") == "Y" ? 1 : 0

                mh_arr = [mh_arr ; [pmid desc_uid desc_mjr qual_uid qual_mjr]]
                mq_arr = [mq_arr ; [qual_uid qual_name]]
            end
        else
            qual_uid = missing
            qual_mjr = missing
            mh_arr = [mh_arr ; [pmid desc_uid desc_mjr qual_uid qual_mjr]]
        end
    end

    return mh_arr, md_arr, mq_arr
end

# Note: If needed it could be further refactored to to that author, journal is a type
"""
    PubMedArticle
Type that matches the NCBI-XML contents for a PubMedArticle
"""



#Constructor from EzXML article element
function pubmed_to_csv(xml::LightXML.XMLElement, csv_prefix::String, csv_path::String)
    pub_type= Array{Any}(0,3) #pmid, uid, desc
    pmid= Vector{Int64}()
    # url::Union{Missing, String}
    title=Vector{String}()
    auth_cite=Vector{Union{Missing, String}}()
    authors=Array{String}(0,8) #pmid, lname, fname, inits, suffix, orcid, collective, affs
    pub_year=Vector{Union{Missing, Int64}}()
    pub_month=Vector{Union{Missing, Int64}}()
    pub_dt_desc=Vector{Union{Missing, String}}()
    journal_title=Vector{Union{Missing, String}}()
    journal_iso_abbrv=Vector{Union{Missing, String}}()
    journal_issn=Vector{Union{Missing, String}}()
    volume=Vector{Union{Missing, String}}()
    issue=Vector{Union{Missing, String}}()
    abstract_full=Array{Any}(0,2) #pmid, text
    abstract_structured=Array{Any}(0,4) #pmid, nlm_category, label, text
    pages=Vector{Union{Missing, String}}()
    mesh_heading=Array{Any}(0,5) #pmid, did, dmaj, qid, qmaj
    mesh_qual=Array{Any}(0,2) #qid, qdesc
    mesh_desc=Array{Any}(0,2) #did, ddesc

    for article in child_elements(xml)
        tdat = find_element(article, "MedlineCitation")

        if tdat == nothing
            error("Error: No Medline Citation")
        end

        # PMID
        this_pmid = parse(Int64, content(find_element(tdat, "PMID")))
        push!(pmid, this_pmid)

        # ARTICLE
        a_info = find_element(tdat, "Article")

            # Journal
            j_info = find_element(a_info, "Journal")

                # ISSN?
                push!(journal_issn, get_if_exists(j_info, "ISSN"))

                # JournalIssue
                j_issue = find_element(j_info, "JournalIssue")

                    # Volume?
                    push!(volume, get_if_exists(j_issue, "Volume"))

                    # Issue?
                    push!(issue, get_if_exists(j_issue, "Issue"))

                    # PubDate
                    j_pub_dt = find_element(j_issue, "PubDate")
                    ml_date = find_element(j_pub_dt, "MedlineDate")
                    if ml_date != nothing
                        ystr, mstr = parse_MedlineDate(content(ml_date))
                    else
                        ystr = content(find_element(j_pub_dt, "Year"))
                        month = find_element(j_pub_dt, "Month")
                        season = find_element(j_pub_dt, "Season")
                        if month != nothing
                            mstr = content(month)
                        elseif season != nothing
                            mstr = content(season)
                        else
                            mstr = ""
                        end
                    end
                    push!(pub_year, parse_year(ystr))
                    push!(pub_month, parse_month(mstr))
                    push!(pub_dt_desc, ystr * (mstr == "" ? "" : " " * mstr))

                # Title?
                push!(journal_title, get_if_exists(j_info, "Title"))

                # ISO Abbreviation?
                push!(journal_iso_abbrv, get_if_exists(j_info, "ISOAbbreviation"))

            # Article Title
            push!(title, content(find_element(a_info, "ArticleTitle")))

            # Pagination
            p_info = find_element(a_info, "Pagination")
            if p_info != nothing
                ml_pgn = find_element(p_info, "MedlinePgn")
                if ml_pgn != nothing
                    push!(pages, content(ml_pgn))
                else
                    start_page = content(find_element(p_info, "StartPage"))
                    end_page = find_element(p_info, "EndPage")
                    push!(pages, (end_page != nothing ? (start_page * "-" * content(end_page)) : start_page))
                end
            else
                push!(pages, missing)
            end

            # Abstract?
            abs_info = find_element(a_info, "Abstract")

                # AbstractText+
                if abs_info != nothing
                    parse_abstracts!(abs_info, abstract_structured, abstract_full, this_pmid)
                end

            # AuthorList?
            auth_info = find_element(a_info, "AuthorList")

                # Author+
                if auth_info!= nothing
                    parse_authors!(auth_info, authors, auth_cite, this_pmid)
                else
                    push!(auth_cite, missing)
                end

            # PublicationTypeList
            pt_info = find_element(a_info, "PublicationTypeList")

                #Publication Type+
                parse_pubtypes!(pt_info, pub_type, this_pmid)

        # MeshHeadingList?
        mh_info = find_element(tdat, "MeshHeadingList")

            # MeshHeading+
            if mh_info != nothing
                parse_meshheadings!(mh_info, mesh_heading, mesh_desc, mesh_qual, this_pmid)
            end
    end

    CSV.write(joinpath(csv_path,"$(csv_prefix)basic.csv"), DataFrame(pmid = pmid,
        pub_year = pub_year,
        pub_month = pub_month,
        pub_dt_desc = pub_dt_desc,
        title = title,
        authors = auth_cite,
        journal_title = journal_title,
        journal_ISSN = journal_issn,
        journal_volume = volume,
        journal_issue = issue,
        journal_pages = pages,
        jouranl_iso_abbreviation = journal_iso_abbrv))

    CSV.write(joinpath(csv_path,"$(csv_prefix)abstract_full.csv"), DataFrame(pmid = abstract_full[:,1],
        abstract_text = abstract_full[:,1]))

    CSV.write(joinpath(csv_path,"$(csv_prefix)abstract_structured.csv"), DataFrame(pmid = abstract_structured[:,1],
        nlm_category = abstract_structured[:,2],
        label = abstract_structured[:,3],
        abstract_text = abstract_structured[:,4]))

    CSV.write(joinpath(csv_path,"$(csv_prefix)author_ref.csv"), DataFrame(pmid = authors[:,1],
        last_name = authors[:,2],
        first_name = authors[:,3],
        initials = authors[:,4],
        suffix = authors[:,5],
        orcid = authors[:,6],
        collective = authors[:,7],
        affiliation = authors[:,8]))

    CSV.write(joinpath(csv_path,"$(csv_prefix)mesh_desc.csv"), DataFrame(uid = mesh_desc[:,1],
        name = mesh_desc[:,2]))

    CSV.write(joinpath(csv_path,"$(csv_prefix)mesh_heading.csv"), DataFrame(pmid = mesh_heading[:,1],
        desc_uid = mesh_heading[:,2],
        desc_maj_status = mesh_heading[:,3],
        qual_uid = mesh_heading[:,4],
        qual_maj_status = mesh_heading[:,5]))

    CSV.write(joinpath(csv_path,"$(csv_prefix)mesh_qual.csv"), DataFrame(uid = mesh_qual[:,1],
        name = mesh_qual[:,2]))

    CSV.write(joinpath(csv_path,"$(csv_prefix)pub_type.csv"), DataFrame(pmid = pub_type[:,1],
        uid = pub_type[:,2],
        name = pub_type[:,3]))

    return nothing
end
