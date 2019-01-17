using LightXML
using CSV
using DataFrames

"""
    dict_to_array(dict::Dict)

Given a dictionary, returns a tuple of arrays with the keys and values.
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
    strip_newline(val::String)

Replaces new line characters with spaces.
"""
function strip_newline(val::String)
    res = replace(val, "\n" => " ")
    res = replace(res, "\r" => " ")
    return res
end
strip_newline(::Missing) = missing

"""
    parse_MedlineDate(ml_dt::String)

Parses the contents of the MedlineDate element and returns a tuple of the year and month.
"""
function parse_MedlineDate(ml_dt::String)
    year = ""
    month = ""
    matches = split(ml_dt, " ", limit = 2)
    try
        year = matches[1]
        month = matches[2]
    catch
        @debug "Couldn't fully parse date: $ml_dt"
    end

    return year, month
end

"""
    parse_year(yr::String)

Parses the string year and returns an integer with the first year in range.
"""
function parse_year(yr::AbstractString)
    try
        Base.parse(Int64, yr[1:4])
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
    if occursin(r"^[0-9]{16}$", raw_orc)
        return "$(raw_orc[1:4])-$(raw_orc[5:8])-$(raw_orc[9:12])-$(raw_orc[13:16])"
    else
        reg = match(r"^.*([0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9a-zA-Z]{4}).*$", raw_orc)

        return reg == nothing ? "PARSE_ERROR" : reg.captures[1]
    end
end

"""
    parse_author

Takes xml for author, and returns parsed elements
"""
function parse_author(xml::LightXML.XMLElement)

    first_name = missing :: Union{Missing,String}
    initials = missing :: Union{Missing,String}
    last_name = missing :: Union{Missing,String}
    suffix = missing :: Union{Missing,String}
    orcid = missing :: Union{Missing,String}
    collective = missing :: Union{Missing,String}
    affs = ""

    for names in child_elements(xml)
        names_name = name(names)
        if names_name == "LastName"
            last_name = content(names)
        elseif names_name == "ForeName"
            first_name = content(names)
        elseif names_name == "Initials"
            initials = content(names)
        elseif names_name == "Suffix"
            suffix = content(names)
        elseif names_name == "Identifier" && attribute(names, "Source") == "ORCID"
            orcid = parse_orcid(content(names))
        elseif names_name == "CollectiveName"
            collective = content(names)
        elseif names_name == "AffiliationInfo"
            for affil_info in child_elements(names)
                if name(affil_info) == "Affiliation"
                    affs *= content(affil_info) * "; "
                end
            end
        end
    end

    affil_str = (affs == "" ? missing : affs[1:prevind(affs,lastindex(affs),2)])

    return last_name, first_name, initials, suffix, orcid, collective, affil_str
end

# Note: If needed it could be further refactored to to that author, journal is a type
"""
    parse_articles(xml)

Parses a PubMedArticleSet that matches the NCBI-XML format
"""
function parse_articles(xml::LightXML.XMLElement)

    articles = get_elements_by_tagname(xml,"PubmedArticle")
    n_articles = length(articles)

    #basic
    pmid = Vector{Int64}(undef, n_articles)
    url = Vector{Union{Missing, String}}(undef, n_articles)
    title = Vector{String}(undef, n_articles)
    auth_cite = Vector{Union{Missing, String}}(undef, n_articles)
    pub_year = Vector{Union{Missing, Int64}}(undef, n_articles)
    pub_month = Vector{Union{Missing, Int64}}(undef, n_articles)
    pub_dt_desc = Vector{String}(undef, n_articles)
    journal_title = Vector{Union{Missing, String}}(undef, n_articles)
    journal_iso_abbrv = Vector{Union{Missing, String}}(undef, n_articles)
    journal_issn = Vector{Union{Missing, String}}(undef, n_articles)
    volume = Vector{Union{Missing, String}}(undef, n_articles)
    issue = Vector{Union{Missing, String}}(undef, n_articles)
    pages = Vector{Union{Missing, String}}(undef, n_articles)

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
    pt_uid = Vector{Int64}()
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
    mh_qmaj = Vector{Union{Int64,Missing}}()

    i = 1 ::Int64
    for article in articles

        # Initialize optional 1:1 article attributes
        this_issn = missing :: Union{Missing,String}
        this_volume = missing :: Union{Missing,String}
        this_issue = missing :: Union{Missing,String}
        this_journal_title = missing :: Union{Missing,String}
        this_iso_abbrv = missing :: Union{Missing,String}
        this_pages = missing :: Union{Missing,String}
        @inbounds auth_cite[i] = missing

        this_pmid = 0

        for tdat in child_elements(article)
            if name(tdat) == "MedlineCitation"
                for mc in child_elements(tdat)
                    if name(mc) == "PMID"
                        this_pmid = Base.parse(Int64, content(mc)) ::Int64
                        @inbounds url[i] = string("http://www.ncbi.nlm.nih.gov/pubmed/", this_pmid)
                        @inbounds pmid[i] = this_pmid
                    elseif name(mc) == "Article"
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
                                                ystr = "" :: String
                                                mstr = "" :: String
                                                for j_pub_dt in child_elements(j_issue)
                                                    if name(j_pub_dt) == "MedlineDate"
                                                        ystr, mstr = parse_MedlineDate(content(j_pub_dt))
                                                    elseif name(j_pub_dt) == "Year"
                                                        ystr = content(j_pub_dt)
                                                    elseif name(j_pub_dt) == "Month" || name(j_pub_dt) == "Season"
                                                        mstr = content(j_pub_dt)
                                                    end
                                                end
                                                @inbounds pub_year[i] = parse_year(ystr)
                                                @inbounds pub_month[i] = parse_month(mstr)
                                                @inbounds pub_dt_desc[i] = ystr * (mstr == "" ? "" : " " * mstr)
                                            end # JournalIssue if
                                        end # JournalIssue For

                                    # Title?
                                    elseif name(j_info) == "Title"
                                        this_journal_title = strip_newline(content(j_info))

                                    # ISO Abbreviation?
                                    elseif name(j_info) == "ISOAbbreviation"
                                        this_iso_abbrv = content(j_info)
                                    end #Journal If
                                end # Journal For

                            # Article Title
                            elseif name(a_info) == "ArticleTitle"
                                @inbounds title[i] = strip_newline(content(a_info))

                            # Pagination?
                            elseif name(a_info) == "Pagination"
                                ml_pgn = missing :: Union{Missing,String}
                                start_page = missing :: Union{Missing,String}
                                end_page = missing :: Union{Missing,String}
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
                                abstract_full_text = "" :: String
                                abs_is_struct = false :: Bool
                                for abs in child_elements(a_info)
                                    if name(abs) == "AbstractText"
                                        if !abs_is_struct && has_attributes(abs)
                                            abs_is_struct = true
                                        end

                                        if abs_is_struct
                                            label = has_attribute(abs, "Label") ? attribute(abs,"Label") : missing :: Union{Missing,String}
                                            nlm_category = has_attribute(abs, "NlmCategory") ? attribute(abs, "NlmCategory") : missing :: Union{Missing,String}
                                            abs_text = strip_newline(content(abs))
                                            push!(as_pmid, this_pmid)
                                            push!(as_nlm, nlm_category)
                                            push!(as_label, label)
                                            push!(as_text, abs_text)
                                            abstract_full_text *= !ismissing(label) ? label * ": " * abs_text * " " : "NO LABEL: " * abs_text * " "
                                        else
                                            abstract_full_text *= strip_newline(content(abs)) * " "
                                        end
                                    end #abstract if
                                end #abstract for
                                push!(af_pmid, this_pmid)
                                push!(af_text, strip(abstract_full_text))


                            # AuthorList?
                            elseif name(a_info) == "AuthorList"
                                # parse_authors!(a_info, authors, auth_cite, i, this_pmid)
                                this_auth_cite = "" :: String

                                for author in child_elements(a_info)
                                    last_name, first_name, initials, suffix, orcid, collective, affs = parse_author(author)

                                    this_auth_cite *= !ismissing(first_name) ? "$last_name, $first_name; " : (!ismissing(last_name) ? "$last_name; " : "")

                                    push!(au_pmid, this_pmid)
                                    push!(au_lname, last_name)
                                    push!(au_fname, first_name)
                                    push!(au_inits, initials)
                                    push!(au_suffix, suffix)
                                    push!(au_orcid, orcid)
                                    push!(au_coll, collective)
                                    push!(au_affs, strip_newline(affs))
                                end

                                @inbounds auth_cite[i] = (this_auth_cite == "" ? missing : this_auth_cite[1:prevind(this_auth_cite,lastindex(this_auth_cite),2)])

                            # PublicationTypeList
                            elseif name(a_info) == "PublicationTypeList"
                                #Publication Type+
                                # parse_pubtypes!(a_info, pub_type, this_pmid)
                                for pt in child_elements(a_info)
                                    desc = content(pt) :: String
                                    ui = attribute(pt, "UI") :: String
                                    uid = length(ui) > 1 ? Base.parse(Int64, ui[2:end]) : -1
                                    push!(pt_pmid, this_pmid)
                                    push!(pt_uid, uid)
                                    push!(pt_name, desc)
                                end
                            end # Article If
                        end # Article For

                    # MeshHeadingList?
                    elseif name(mc) == "MeshHeadingList"
                        for heading in child_elements(mc)
                        # parse_meshheadings!(mc, mesh_heading, mesh_desc, mesh_qual, this_pmid)
                            desc_uid = -1
                            desc_maj = -1
                            qual = missing :: Union{Missing,String}

                            for header in child_elements(heading)
                                header_name = name(header) :: String
                                if header_name == "DescriptorName"
                                    desc = content(header) :: String
                                    desc_maj = attribute(header, "MajorTopicYN") == "Y" ? 1 : 0
                                    desc_ui = attribute(header, "UI")
                                    desc_uid = length(desc_ui) > 1 ? Base.parse(Int, desc_ui[2:end]) : -1
                                    mesh_desc[desc_uid] = desc
                                elseif header_name == "QualifierName"
                                    qual = content(header)
                                    qual_maj = attribute(header, "MajorTopicYN") == "Y" ? 1 : 0 :: Int
                                    qual_ui = attribute(header, "UI")
                                    qual_uid = length(qual_ui) > 1 ? Base.parse(Int, qual_ui[2:end]) : -1

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
        journal_iso_abbreviation = journal_iso_abbrv,
        url = url)

    dfs["abstract_full"] = DataFrame(pmid = af_pmid,
        abstract_text = af_text)

    dfs["abstract_structured"] = DataFrame(pmid = as_pmid,
        nlm_category = as_nlm,
        label = as_label,
        abstract_text = as_text)

    dfs["author_ref"] = DataFrame(pmid = au_pmid,
        last_name = au_lname,
        first_name = au_fname,
        initials = au_inits,
        suffix = au_suffix,
        orcid = au_orcid,
        collective = au_coll,
        affiliation = au_affs)

    dfs["mesh_heading"] = DataFrame(pmid = mh_pmid,
        desc_uid = mh_did,
        desc_maj_status = mh_dmaj,
        qual_uid = mh_qid,
        qual_maj_status = mh_qmaj)

    did, dname = dict_to_array(mesh_desc)
    dfs["mesh_desc"] = DataFrame(uid = did,
        name = dname)

    qid, qname = dict_to_array(mesh_qual)
    dfs["mesh_qual"] = DataFrame(uid = qid,
        name = qname)

    dfs["pub_type"] = DataFrame(pmid = pt_pmid,
        uid = pt_uid,
        name = pt_name)

    return dfs
end

"""
    dfs_to_csv(dfs::Dict, path::String, [file_prefix::String])
Takes output of toDataFrames and writes to CSV files at the provided path and with the file prefix.
"""
function dfs_to_csv(dfs::Dict{String,DataFrame}, path::String, file_prefix::String="")
    [CSV.write(joinpath(path,"$file_prefix$k.csv"),v, missingstring = "NULL") for (k, v) in dfs]
    return nothing
end

"""
    remove_csvs(dfs, path, file_prefix)
Removes all of the CSV files associated with a dictionary of dataframes
"""
function remove_csvs(dfs::Dict{String,DataFrame}, path::String, file_prefix::String="")
    [rm(joinpath(path,"$(file_prefix)$k.csv"), force=true) for (k,v) in dfs]
    return nothing
end

"""
    remove_csvs(paths::Vector)
Removes all of the CSV files associated with an array of paths
"""
function remove_csvs(paths::Vector{String})
    [rm(path, force=true) for path in paths]
    return nothing
end
