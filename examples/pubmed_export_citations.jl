# Example Julia to export EndNote/BibTex citations from a PMID or a list of
# PMIDs. If you need to search Entrez/PubMed and save the results as citations,
# refer to Examples/pubmed_search_and_save.jl
# Date: September 8, 2016
# Authors: Isabel Restrepo
# BCBI - Brown University
# Version: Julia 0.4.5

using BioMedQuery.Processes

#************************ LOCALS TO CONFIGURE!!!! **************************
results_dir = "./results"

 if !isdir(results_dir)
     mkdir(results_dir)
 end

email= ENV["NCBI_EMAIL"] #This is an enviroment variable that you need to setup
citation_type="endnote"
pmid = 11748933
output_file1=results_dir*"/11748933.enw"

pmid_list = [24008025, 24170597]
output_file2 = results_dir* "/pmid_list.enw"
verbose = false #extra debugging printouts and save efetch.xml



#***************************************************************************

export_citation(email, pmid, citation_type, output_file1, verbose)
export_citation(email, pmid_list, citation_type, output_file2, verbose)
