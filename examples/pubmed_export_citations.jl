
using BioMedQuery.Processes

results_dir = "./results"

 if !isdir(results_dir)
     mkdir(results_dir)
 end

pmid = 11748933
pmid_list = [24008025, 24170597];

enw_file=results_dir*"/11748933.enw"
export_citation(pmid, "endnote", enw_file)
enw_file = results_dir* "/pmid_list.enw"
export_citation(pmid_list, "endnote", enw_file);

println(readstring(enw_file))

bib_file=results_dir*"/11748933.bib"
export_citation(pmid, "bibtex", bib_file)
bib_file = results_dir* "/pmid_list.bib"
export_citation(pmid_list, "bibtex", bib_file);

println(readstring(bib_file))
