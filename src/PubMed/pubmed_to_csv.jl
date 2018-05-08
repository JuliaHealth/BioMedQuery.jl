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
    dict_to_array(dict::Dict)

Given a dictionary, returns a tuple of arrays with  keys and values.
"""
function dict_to_array(dict::Dict)
    keys = []
    vals = []

    for (key, val) in dict
        push!(keys, key)
        push!(vals, val)
    end

    return keys, vals
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
function parse_authors!(xml::LightXML.XMLElement, authors::Array, auth_cite::Array, iter::Int, pmid::Int64)

    this_auth_cite = ""

    for author in child_elements(xml)
        first_name = missing
        initials = missing
        last_name = missing
        suffix = missing
        orcid = missing
        collective = missing
        affiliations = missing

        affs = ""
        for names in child_elements(xml)
            names_name = name(names)
            if names_name == "LastName"
                last_name = content(xml)
            elseif names_name == "ForeName"
                first_name = content(names)
            elseif names_name == "Initials"
                initials = content(names)
            elseif names_name == "Suffix"
                suffix = content(names)
            elseif names_name == "Identifer" && atribute(names, "Source") == "ORCID"
                orcid = parse_orcid(content(names))
            elseif names_name == "CollectiveName"
                collective = content(names)
            elseif names_name == "AffiliationInfo"
                for affil_info in child_elements(names)
                    for affiliates in get_elements_by_tagname(affil_info, "Affiliation")
                        affs *= content(affiliates) * "; "
                    end
                end
            end
        end

        affs = affs == "" ? missing : affs[1:end-2]

        this_auth_cite *= !ismissing(first_name) ? "$last_name, $first_name; " : (!ismissing(last_name) ? "$last_name; " : "")
        authors = [authors ; [pmid last_name first_name initials suffix orcid collective affs]]
    end

    auth_cite[iter] = (this_auth_cite == "" ? missing : this_auth_cite[1:end-2])

    return authors, auth_cite
end

"""
    parse_abstracts!
Takes xml for abstracts, and updates arrays with new data
"""
function parse_abstracts!(xml::LightXML.XMLElement, struct_array::Array, full_array::Array, pmid::Int64)

    abstract_full_text = ""
    at_els = get_elements_by_tagname(xml, "AbstractText")
    if length(at_els) > 1
        for txt in at_els
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
        if length(quals) > 0
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
    tic()
    articles = get_elements_by_tagname(xml,"PubmedArticle")
    n_articles = length(articles)
    toc()

    tic()
    #basic
    pmid= Vector{Int64}(n_articles)
    # url::Union{Missing, String}
    title=Vector{String}(n_articles)
    auth_cite=Vector{Union{Missing, String}}(n_articles)
    pub_year=Vector{Union{Missing, Int64}}(n_articles)
    pub_month=Vector{Union{Missing, Int64}}(n_articles)
    pub_dt_desc=Vector{Union{Missing, String}}(n_articles)
    journal_title=Vector{Union{Missing, String}}(n_articles)
    journal_iso_abbrv=Vector{Union{Missing, String}}(n_articles)
    journal_issn=Vector{Union{Missing, String}}(n_articles)
    volume=Vector{Union{Missing, String}}(n_articles)
    issue=Vector{Union{Missing, String}}(n_articles)
    pages=Vector{Union{Missing, String}}(n_articles)

    mesh_qual=Dict{Int64, String}() #qid, qdesc
    mesh_desc=Dict{Int64, String}() #did, ddesc

    #author_ref
    au_pmid = Vector{Int64}()
    au_lname = Vector{Union{String,Missing}}()
    au_fname = Vector{Union{String,Missing}}()
    au_inits = Vector{Union{String,Missing}}()
    au_suffix = Vector{Union{String,Missing}}()
    au_orcid = Vector{Union{String,Missing}}()
    au_coll = Vector{Union{String,Missing}}()
    au_affs = Vector{Union{String,Missing}}()

    #pub_type
    pt_pmid = Vector{Int64}()
    pt_uid = Vector{Union{Int64,Missing}}()
    pt_name = Vector{String}()

    #abstract_full
    af_pmid = Vector{Int64}()
    af_text = Vector{String}()

    #abstract_structured
    as_pmid = Vector{Int64}()
    as_nlm = Vector{Union{String,Missing}}()
    as_label = Vector{Union{String,Missing}}()
    as_text = Vector{String}()

    #mesh_heading
    mh_pmid = Vector{Int64}()
    mh_did = Vector{Int64}()
    mh_dmaj = Vector{Int8}()
    mh_qid = Vector{Union{Int64,Missing}}()
    mh_qmaj = Vector{Union{Int8,Missing}}()



    toc()

    tic()
    for i = 1:n_articles
        tdat = find_element(articles[i], "MedlineCitation")

        if tdat == nothing
            error("Error: No Medline Citation")
        end

        # Initialize optional 1:1 article attributes
        this_issn = missing
        this_volume = missing
        this_issue = missing
        this_journal_title = missing
        this_iso_abbrv = missing
        this_pages = missing
        @inbounds auth_cite[i] = missing

        # find pmid first to make sure everything else doesn't break (shoudln't be a problem but if it did happen would be a big problem)
        this_pmid = parse(Int64, content(find_element(tdat, "PMID")))
        @inbounds pmid[i] = this_pmid

        for mc in child_elements(tdat)
            if name(mc) == "Article"
                for a_info in child_elements(mc)

                    # Journal
                    if name(a_info) == "Journal"
                        for j_info in child_elements(a_info)

                            # ISSN?
                            if name(j_info) == "ISSN"
                            this_issn = content(j_info)

                            # JournalIssue
                            elseif name(j_info) == "JournalIssue"
                                for j_issue in child_elements(j_info)

                                    # Volume?
                                    if name(j_issue) == "Volume"
                                        this_volume = content(j_issue)

                                    # Issue?
                                    elseif name(j_issue) == "Issue"
                                        this_issue = content(j_issue)

                                    # PubDate
                                    elseif name(j_issue) == "PubDate"
                                        ystr = ""
                                        mstr = ""
                                        for j_pub_dt in child_elements(j_issue)
                                            for dt_el in child_elements(j_pub_dt)
                                                if name(child) == "MedlineDate"
                                                    ystr, mstr = parse_MedlineDate(content(child))
                                                elseif name(child) == "Year"
                                                    ystr = content(child)
                                                elseif name(child) == "Month" || name(child) == "Season"
                                                    mstr = content(child)
                                                end
                                            end
                                        end
                                        @inbounds pub_year[i] = parse_year(ystr)
                                        @inbounds pub_month[i] = parse_month(mstr)
                                        @inbounds pub_dt_desc[i] = ystr * (mstr == "" ? "" : " " * mstr)
                                    end # JournalIssue if
                                end # JournalIssue For

                            # Title?
                            elseif name(j_info) == "Title"
                                this_journal_title = content(j_info)

                            # ISO Abbreviation?
                            elseif name(j_info) == "ISOAbbreviation"
                                this_iso_abbrv = content(j_info)
                            end #Journal If
                        end # Journal For

                    # Article Title
                    elseif name(a_info) == "ArticleTitle"
                        @inbounds title[i] = content(a_info)

                    # Pagination?
                    elseif name(a_info) == "Pagination"
                        ml_pgn = missing
                        start_page = missing
                        end_page = missing
                        for p_info in child_elements(a_info)
                            if name(p_info) == "MedlinePgn"
                                ml_pgn = content(p_info)
                            elseif name(p_info) == "StartPage"
                                start_page = content(p_info)
                            elseif name(p_info) == "EndPage"
                                end_page = content(p_info)
                            end # p_info if
                        end # p_info for

                        if !ismissing(ml_pgn)
                            this_pages = ml_pgn
                        else
                            this_pages = (!ismissing(end_page) ? (start_page * "-" * end_page) : start_page)
                        end

                    # Abstract?
                    elseif name(a_info) == "Abstract"
                        # AbstractText+
                        # parse_abstracts!(a_info, abstract_structured, abstract_full, this_pmid)
                        abstract_full_text = ""
                        at_els = get_elements_by_tagname(a_info, "AbstractText")
                        if length(at_els) > 1
                            for txt in at_els
                                if name(txt) == "AbstractText"
                                    label = attribute(txt, "Label")
                                    label = label == nothing ? missing : label
                                    nlm_category = attribute(txt, "NlmCategory")
                                    nlm_category = nlm_category == nothing ? missing : nlm_category
                                    abs_text = content(txt)
                                    push!(as_pmid, this_pmid)
                                    push!(as_nlm, nlm_category,)
                                    push!(as_label, label)
                                    push!(as_text, abs_text)
                                    abstract_full_text *= !ismissing(label) ? label * ": " * abs_text * " " : "NO LABEL: " * abs_text * " "
                                end
                            end
                            push!(af_pmid, this_pmid)
                            push!(af_text, abstract_full_text[1:end-1])
                        else
                            push!(af_pmid, this_pmid)
                            push!(af_text, content(at_els...))
                        end

                    # AuthorList?
                    elseif name(a_info) == "AuthorList"
                        # parse_authors!(a_info, authors, auth_cite, i, this_pmid)
                        this_auth_cite = ""

                        for author in child_elements(a_info)
                            first_name = missing
                            initials = missing
                            last_name = missing
                            suffix = missing
                            orcid = missing
                            collective = missing
                            affs = ""

                            for names in child_elements(author)
                                names_name = name(names)
                                if names_name == "LastName"
                                    last_name = content(names)
                                elseif names_name == "ForeName"
                                    first_name = content(names)
                                elseif names_name == "Initials"
                                    initials = content(names)
                                elseif names_name == "Suffix"
                                    suffix = content(names)
                                elseif names_name == "Identifer" && atribute(names, "Source") == "ORCID"
                                    orcid = parse_orcid(content(names))
                                elseif names_name == "CollectiveName"
                                    collective = content(names)
                                elseif names_name == "AffiliationInfo"
                                    for affil_info in child_elements(names)
                                        for affiliates in get_elements_by_tagname(affil_info, "Affiliation")
                                            affs *= content(affiliates) * "; "
                                        end
                                    end
                                end
                            end

                            affs = (affs == "" ? missing : affs[1:end-2])

                            this_auth_cite *= !ismissing(first_name) ? "$last_name, $first_name; " : (!ismissing(last_name) ? "$last_name; " : "")
                            push!(au_pmid, this_pmid)
                            push!(au_lname, last_name)
                            push!(au_fname, first_name)
                            push!(au_inits, initials)
                            push!(au_suffix, suffix)
                            push!(au_orcid, orcid)
                            push!(au_coll, collective)
                            push!(au_affs, affs)
                        end

                        @inbounds auth_cite[i] = (this_auth_cite == "" ? missing : this_auth_cite[1:end-2])

                    # PublicationTypeList
                    elseif name(a_info) == "PublicationTypeList"
                        #Publication Type+
                        # parse_pubtypes!(a_info, pub_type, this_pmid)
                        for pt in child_elements(a_info)
                            desc = content(pt)
                            ui = attribute(pt, "UI")
                            uid = length(ui) > 1 ? parse(Int64, ui[2:end]) : missing
                            push!(pt_pmid, this_pmid)
                            push!(pt_uid, uid)
                            push!(pt_name, desc)
                        end
                    end # Article If
                end # Article For

            # MeshHeadingList?
            elseif name(mc) == "MeshHeadingList"
                # parse_meshheadings!(mc, mesh_heading, mesh_desc, mesh_qual, this_pmid)
                for header in child_elements(mc)
                    # parse descriptor
                    desc = find_element(header, "DescriptorName")
                    desc_ui = attribute(desc, "UI")
                    desc_uid = length(desc_ui) > 1 ? parse(Int64, desc_ui[2:end]) : missing
                    desc_mjr = attribute(header,"MajorTopicYN") == "Y" ? 1 : 0

                    mesh_desc[desc_uid] = content(desc)

                    quals = header["QualifierName"]
                    if length(quals) > 0
                        for qual in quals
                            qual_ui = attribute(qual, "UI")
                            qual_uid = length(qual_ui) > 1 ? parse(Int64, qual_ui[2:end]) : missing
                            qual_mjr = attribute(qual, "MajorTopicYN") == "Y" ? 1 : 0

                            mesh_qual[qual_uid] = content(qual)

                            push!(mh_pmid, this_pmid)
                            push!(mh_did, desc_uid)
                            push!(mh_dmaj, desc_mjr)
                            push!(mh_qid, qual_uid)
                            push!(mh_qmaj, qual_mjr)

                        end
                    else
                        qual_uid = missing
                        qual_mjr = missing

                        push!(mh_pmid, this_pmid)
                        push!(mh_did, desc_uid)
                        push!(mh_dmaj, desc_mjr)
                        push!(mh_qid, qual_uid)
                        push!(mh_qmaj, qual_mjr)
                    end
                end
            end # MedlineCitation If
        end # MedlineCitation For

        @inbounds journal_issn[i] = this_issn
        @inbounds volume[i] = this_volume
        @inbounds issue[i] = this_issue
        @inbounds journal_title[i] = this_journal_title
        @inbounds journal_iso_abbrv[i] = this_iso_abbrv
        @inbounds pages[i] = this_pages
    end # Document For
    toc()

    tic()

    dfs = Dict{String,DataFrame}()

    dfs["basic"] = DataFrame(pmid = pmid,
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
        jouranl_iso_abbreviation = journal_iso_abbrv)
    # CSV.write(joinpath(csv_path,"$(csv_prefix)basic.csv"), DataFrame(pmid = pmid,
    #     pub_year = pub_year,
    #     pub_month = pub_month,
    #     pub_dt_desc = pub_dt_desc,
    #     title = title,
    #     authors = auth_cite,
    #     journal_title = journal_title,
    #     journal_ISSN = journal_issn,
    #     journal_volume = volume,
    #     journal_issue = issue,
    #     journal_pages = pages,
    #     jouranl_iso_abbreviation = journal_iso_abbrv))

    dfs["abstract_full"] = DataFrame(pmid = af_pmid,
        abstract_text = af_text)
    # CSV.write(joinpath(csv_path,"$(csv_prefix)abstract_full.csv"), DataFrame(pmid = af_pmid,
    #     abstract_text = af_text))

    dfs["abstract_structured"] = DataFrame(pmid = as_pmid,
        nlm_category = as_nlm,
        label = as_label,
        abstract_text = as_text)
    # CSV.write(joinpath(csv_path,"$(csv_prefix)abstract_structured.csv"), DataFrame(pmid = as_pmid,
    #     nlm_category = as_nlm,
    #     label = as_label,
    #     abstract_text = as_text))

    dfs["author_ref"] = DataFrame(pmid = au_pmid,
        last_name = au_lname,
        first_name = au_fname,
        initials = au_inits,
        suffix = au_suffix,
        orcid = au_orcid,
        collective = au_coll,
        affiliation = au_affs)
    # CSV.write(joinpath(csv_path,"$(csv_prefix)author_ref.csv"), DataFrame(pmid = au_pmid,
    #     last_name = au_lname,
    #     first_name = au_fname,
    #     initials = au_inits,
    #     suffix = au_suffix,
    #     orcid = au_orcid,
    #     collective = au_coll,
    #     affiliation = au_affs))

    dfs["mesh_heading"] = DataFrame(pmid = mh_pmid,
        desc_uid = mh_did,
        desc_maj_status = mh_dmaj,
        qual_uid = mh_qid,
        qual_maj_status = mh_qmaj)
    # CSV.write(joinpath(csv_path,"$(csv_prefix)mesh_heading.csv"), DataFrame(pmid = mh_pmid,
    #     desc_uid = mh_did,
    #     desc_maj_status = mh_dmaj,
    #     qual_uid = mh_qid,
    #     qual_maj_status = mh_qmaj))

    did, dname = dict_to_array(mesh_desc)
    dfs["mesh_desc"] = DataFrame(uid = did,
        name = dname)
    # CSV.write(joinpath(csv_path,"$(csv_prefix)mesh_desc.csv"), DataFrame(uid = did,
    #     name = dname))

    qid, qname = dict_to_array(mesh_qual)
    dfs["mesh_qual"] = DataFrame(uid = qid,
        name = qname)
    # CSV.write(joinpath(csv_path,"$(csv_prefix)mesh_qual.csv"), DataFrame(uid = qid,
    #     name = qname))

    dfs["pub_type"] = DataFrame(pmid = pt_pmid,
        uid = pt_uid,
        name = pt_name)
    # CSV.write(joinpath(csv_path,"$(csv_prefix)pub_type.csv"), DataFrame(pmid = pt_pmid,
    #     uid = pt_uid,
    #     name = pt_name))

    toc()
    return dfs
end

#Constructor from EzXML article element
function pubmed_to_csv(xml::EzXML.Node, csv_prefix::String, csv_path::String)
    tic()
    n_articles = countelements(xml)
    toc()

    tic()
    #basic
    pmid= Vector{Int64}(n_articles)
    # url::Union{Missing, String}
    title=Vector{String}(n_articles)
    auth_cite=Vector{Union{Missing, String}}(n_articles)
    pub_year=Vector{Union{Missing, Int64}}(n_articles)
    pub_month=Vector{Union{Missing, Int64}}(n_articles)
    pub_dt_desc=Vector{Union{Missing, String}}(n_articles)
    journal_title=Vector{Union{Missing, String}}(n_articles)
    journal_iso_abbrv=Vector{Union{Missing, String}}(n_articles)
    journal_issn=Vector{Union{Missing, String}}(n_articles)
    volume=Vector{Union{Missing, String}}(n_articles)
    issue=Vector{Union{Missing, String}}(n_articles)
    pages=Vector{Union{Missing, String}}(n_articles)

    mesh_qual=Dict{Int64, String}() #qid, qdesc
    mesh_desc=Dict{Int64, String}() #did, ddesc

    #author_ref
    au_pmid = Vector{Int64}()
    au_lname = Vector{Union{String,Missing}}()
    au_fname = Vector{Union{String,Missing}}()
    au_inits = Vector{Union{String,Missing}}()
    au_suffix = Vector{Union{String,Missing}}()
    au_orcid = Vector{Union{String,Missing}}()
    au_coll = Vector{Union{String,Missing}}()
    au_affs = Vector{Union{String,Missing}}()

    #pub_type
    pt_pmid = Vector{Int64}()
    pt_uid = Vector{Union{Int64,Missing}}()
    pt_name = Vector{String}()

    #abstract_full
    af_pmid = Vector{Int64}()
    af_text = Vector{String}()

    #abstract_structured
    as_pmid = Vector{Int64}()
    as_nlm = Vector{Union{String,Missing}}()
    as_label = Vector{Union{String,Missing}}()
    as_text = Vector{String}()

    #mesh_heading
    mh_pmid = Vector{Int64}()
    mh_did = Vector{Int64}()
    mh_dmaj = Vector{Int8}()
    mh_qid = Vector{Union{Int64,Missing}}()
    mh_qmaj = Vector{Union{Int8,Missing}}()
    toc()

    tic()
    i = 1 #initialize element couner
    for article in eachelement(xml)

        # Initialize optional 1:1 article attributes
        this_issn = missing
        this_volume = missing
        this_issue = missing
        this_journal_title = missing
        this_iso_abbrv = missing
        this_pages = missing
        @inbounds auth_cite[i] = missing

        this_pmid = 0

        for tdat in eachelement(article)
            if nodename(tdat) == "MedlineCitation"
                for mc in eachelement(tdat)
                    if nodename(mc) == "PMID"
                        this_pmid = parse(Int64, nodecontent(mc))
                        @inbounds pmid[i] = this_pmid
                    elseif nodename(mc) == "Article"
                        for a_info in eachelement(mc)

                            # Journal
                            if nodename(a_info) == "Journal"
                                for j_info in eachelement(a_info)

                                    # ISSN?
                                    if nodename(j_info) == "ISSN"
                                    this_issn = nodecontent(j_info)

                                    # JournalIssue
                                    elseif nodename(j_info) == "JournalIssue"
                                        for j_issue in eachelement(j_info)

                                            # Volume?
                                            if nodename(j_issue) == "Volume"
                                                this_volume = nodecontent(j_issue)

                                            # Issue?
                                            elseif nodename(j_issue) == "Issue"
                                                this_issue = nodecontent(j_issue)

                                            # PubDate
                                            elseif nodename(j_issue) == "PubDate"
                                                ystr = ""
                                                mstr = ""
                                                for j_pub_dt in eachelement(j_issue)
                                                    if nodename(j_pub_dt) == "MedlineDate"
                                                        ystr, mstr = parse_MedlineDate(nodecontent(j_pub_dt))
                                                    elseif nodename(j_pub_dt) == "Year"
                                                        ystr = nodecontent(j_pub_dt)
                                                    elseif nodename(j_pub_dt) == "Month" || nodename(j_pub_dt) == "Season"
                                                        mstr = nodecontent(j_pub_dt)
                                                    end
                                                end
                                                @inbounds pub_year[i] = parse_year(ystr)
                                                @inbounds pub_month[i] = parse_month(mstr)
                                                @inbounds pub_dt_desc[i] = ystr * (mstr == "" ? "" : " " * mstr)
                                            end # JournalIssue if
                                        end # JournalIssue For

                                    # Title?
                                    elseif nodename(j_info) == "Title"
                                        this_journal_title = nodecontent(j_info)

                                    # ISO Abbreviation?
                                    elseif nodename(j_info) == "ISOAbbreviation"
                                        this_iso_abbrv = nodecontent(j_info)
                                    end #Journal If
                                end # Journal For

                            # Article Title
                            elseif nodename(a_info) == "ArticleTitle"
                                @inbounds title[i] = nodecontent(a_info)

                            # Pagination?
                            elseif nodename(a_info) == "Pagination"
                                ml_pgn = missing
                                start_page = missing
                                end_page = missing
                                for p_info in eachelement(a_info)
                                    if nodename(p_info) == "MedlinePgn"
                                        ml_pgn = nodecontent(p_info)
                                    elseif nodename(p_info) == "StartPage"
                                        start_page = nodecontent(p_info)
                                    elseif nodename(p_info) == "EndPage"
                                        end_page = nodecontent(p_info)
                                    end # p_info if
                                end # p_info for

                                if !ismissing(ml_pgn)
                                    this_pages = ml_pgn
                                else
                                    this_pages = (!ismissing(end_page) ? (start_page * "-" * end_page) : start_page)
                                end

                            # Abstract?
                            elseif nodename(a_info) == "Abstract"
                                # AbstractText+
                                # parse_abstracts!(a_info, abstract_structured, abstract_full, this_pmid)
                                abstract_full_text = ""
                                abs_is_struct = false
                                for abs in eachelement(a_info)
                                    if nodename(abs) == "AbstractText"
                                        if !abs_is_struct && countattributes(abs) > 0
                                            abs_is_struct = true
                                        end

                                        if abs_is_struct
                                            label = haskey(abs, "Label")
                                            label = label ? abs["Label"] : missing
                                            nlm_category = haskey(abs, "NlmCategory")
                                            nlm_category = nlm_category ? abs["NlmCategory"] : missing
                                            abs_text = nodecontent(abs)
                                            push!(as_pmid, this_pmid)
                                            push!(as_nlm, nlm_category,)
                                            push!(as_label, label)
                                            push!(as_text, abs_text)
                                            abstract_full_text *= !ismissing(label) ? label * ": " * abs_text * " " : "NO LABEL: " * abs_text * " "
                                        else
                                            abstract_full_text *= nodecontent(abs) * " "
                                        end
                                    end #abstract if
                                end #abstract for
                                push!(af_pmid, this_pmid)
                                push!(af_text, abstract_full_text[1:end-1])


                            # AuthorList?
                            elseif nodename(a_info) == "AuthorList"
                                # parse_authors!(a_info, authors, auth_cite, i, this_pmid)
                                this_auth_cite = ""

                                for author in eachelement(a_info)
                                    first_name = missing
                                    initials = missing
                                    last_name = missing
                                    suffix = missing
                                    orcid = missing
                                    collective = missing
                                    affs = ""

                                    for names in eachelement(author)
                                        names_name = nodename(names)
                                        if names_name == "LastName"
                                            last_name = nodecontent(names)
                                        elseif names_name == "ForeName"
                                            first_name = nodecontent(names)
                                        elseif names_name == "Initials"
                                            initials = nodecontent(names)
                                        elseif names_name == "Suffix"
                                            suffix = nodecontent(names)
                                        elseif names_name == "Identifer" && atribute(names, "Source") == "ORCID"
                                            orcid = parse_orcid(nodecontent(names))
                                        elseif names_name == "CollectiveName"
                                            collective = nodecontent(names)
                                        elseif names_name == "AffiliationInfo"
                                            for affil_info in eachelement(names)
                                                if nodename(affil_info) == "Affiliation"
                                                    affs *= nodecontent(affil_info) * "; "
                                                end
                                            end
                                        end
                                    end

                                    affs = (affs == "" ? missing : affs[1:end-2])

                                    this_auth_cite *= !ismissing(first_name) ? "$last_name, $first_name; " : (!ismissing(last_name) ? "$last_name; " : "")
                                    push!(au_pmid, this_pmid)
                                    push!(au_lname, last_name)
                                    push!(au_fname, first_name)
                                    push!(au_inits, initials)
                                    push!(au_suffix, suffix)
                                    push!(au_orcid, orcid)
                                    push!(au_coll, collective)
                                    push!(au_affs, affs)
                                end

                                @inbounds auth_cite[i] = (this_auth_cite == "" ? missing : this_auth_cite[1:end-2])

                            # PublicationTypeList
                            elseif nodename(a_info) == "PublicationTypeList"
                                #Publication Type+
                                # parse_pubtypes!(a_info, pub_type, this_pmid)
                                for pt in eachelement(a_info)
                                    desc = nodecontent(pt)
                                    ui = pt["UI"]
                                    uid = length(ui) > 1 ? parse(Int64, ui[2:end]) : missing
                                    push!(pt_pmid, this_pmid)
                                    push!(pt_uid, uid)
                                    push!(pt_name, desc)
                                end
                            end # Article If
                        end # Article For

                    # MeshHeadingList?
                    elseif nodename(mc) == "MeshHeadingList"
                        for heading in eachelement(mc)
                        # parse_meshheadings!(mc, mesh_heading, mesh_desc, mesh_qual, this_pmid)
                            desc_uid = -1
                            desc_maj = -1
                            qual = missing

                            for header in eachelement(heading)
                                header_name = nodename(header)
                                if header_name == "DescriptorName"
                                    desc = nodecontent(header)
                                    desc_maj = header["MajorTopicYN"] == "Y" ? 1 : 0
                                    desc_uid = parse(Int, header["UI"][2:end])
                                    mesh_desc[desc_uid] = desc
                                elseif header_name == "QualifierName"
                                    qual = nodecontent(header)
                                    qual_maj = header["MajorTopicYN"] == "Y" ? 1 : 0
                                    qual_uid = parse(Int, header["UI"][2:end])

                                    mesh_qual[qual_uid] = qual

                                    push!(mh_pmid, this_pmid)
                                    push!(mh_did, desc_uid)
                                    push!(mh_dmaj, desc_maj)
                                    push!(mh_qid, qual_uid)
                                    push!(mh_qmaj, qual_maj)
                                end
                            end

                            if ismissing(qual)
                                qual_uid = missing
                                qual_maj = missing

                                push!(mh_pmid, this_pmid)
                                push!(mh_did, desc_uid)
                                push!(mh_dmaj, desc_maj)
                                push!(mh_qid, qual_uid)
                                push!(mh_qmaj, qual_maj)
                            end
                        end # heading for
                    end # MedlineCitation If
                end # medline citation if
            end # if nodename == MedlineCitation
        end # tdat For

        @inbounds journal_issn[i] = this_issn
        @inbounds volume[i] = this_volume
        @inbounds issue[i] = this_issue
        @inbounds journal_title[i] = this_journal_title
        @inbounds journal_iso_abbrv[i] = this_iso_abbrv
        @inbounds pages[i] = this_pages

        i += 1
    end # Document For
    toc()

    tic()

    dfs = Dict{String,DataFrame}()

    dfs["basic"] = DataFrame(pmid = pmid,
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
        jouranl_iso_abbreviation = journal_iso_abbrv)
    # CSV.write(joinpath(csv_path,"$(csv_prefix)basic.csv"), DataFrame(pmid = pmid,
    #     pub_year = pub_year,
    #     pub_month = pub_month,
    #     pub_dt_desc = pub_dt_desc,
    #     title = title,
    #     authors = auth_cite,
    #     journal_title = journal_title,
    #     journal_ISSN = journal_issn,
    #     journal_volume = volume,
    #     journal_issue = issue,
    #     journal_pages = pages,
    #     jouranl_iso_abbreviation = journal_iso_abbrv))

    dfs["abstract_full"] = DataFrame(pmid = af_pmid,
        abstract_text = af_text)
    # CSV.write(joinpath(csv_path,"$(csv_prefix)abstract_full.csv"), DataFrame(pmid = af_pmid,
    #     abstract_text = af_text))

    dfs["abstract_structured"] = DataFrame(pmid = as_pmid,
        nlm_category = as_nlm,
        label = as_label,
        abstract_text = as_text)
    # CSV.write(joinpath(csv_path,"$(csv_prefix)abstract_structured.csv"), DataFrame(pmid = as_pmid,
    #     nlm_category = as_nlm,
    #     label = as_label,
    #     abstract_text = as_text))

    dfs["author_ref"] = DataFrame(pmid = au_pmid,
        last_name = au_lname,
        first_name = au_fname,
        initials = au_inits,
        suffix = au_suffix,
        orcid = au_orcid,
        collective = au_coll,
        affiliation = au_affs)
    # CSV.write(joinpath(csv_path,"$(csv_prefix)author_ref.csv"), DataFrame(pmid = au_pmid,
    #     last_name = au_lname,
    #     first_name = au_fname,
    #     initials = au_inits,
    #     suffix = au_suffix,
    #     orcid = au_orcid,
    #     collective = au_coll,
    #     affiliation = au_affs))

    dfs["mesh_heading"] = DataFrame(pmid = mh_pmid,
        desc_uid = mh_did,
        desc_maj_status = mh_dmaj,
        qual_uid = mh_qid,
        qual_maj_status = mh_qmaj)
    # CSV.write(joinpath(csv_path,"$(csv_prefix)mesh_heading.csv"), DataFrame(pmid = mh_pmid,
    #     desc_uid = mh_did,
    #     desc_maj_status = mh_dmaj,
    #     qual_uid = mh_qid,
    #     qual_maj_status = mh_qmaj))

    did, dname = dict_to_array(mesh_desc)
    dfs["mesh_desc"] = DataFrame(uid = did,
        name = dname)
    # CSV.write(joinpath(csv_path,"$(csv_prefix)mesh_desc.csv"), DataFrame(uid = did,
    #     name = dname))

    qid, qname = dict_to_array(mesh_qual)
    dfs["mesh_qual"] = DataFrame(uid = qid,
        name = qname)
    # CSV.write(joinpath(csv_path,"$(csv_prefix)mesh_qual.csv"), DataFrame(uid = qid,
    #     name = qname))

    dfs["pub_type"] = DataFrame(pmid = pt_pmid,
        uid = pt_uid,
        name = pt_name)
    # CSV.write(joinpath(csv_path,"$(csv_prefix)pub_type.csv"), DataFrame(pmid = pt_pmid,
    #     uid = pt_uid,
    #     name = pt_name))

    toc()
    return dfs
end
