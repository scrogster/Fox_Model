library(rmarkdown)

args = commandArgs(trailingOnly=TRUE)

#desired format for ouput paper
out_format=args[1]


#render the manuscript
if(out_format=="pdf_document") {render("Fox_model_paper.Rmd", "pdf_document")}

#Render the supporting information
dir.create("SupportingInformation", showWarnings = FALSE)
#render the supplementary tables
if(out_format=="pdf_document") {render("Table_S1.Rmd", "pdf_document", "SupportingInformation/JAEscroggieST1.pdf")}
if(out_format=="pdf_document") {render("Table_S2.Rmd", "pdf_document", "SupportingInformation/JAEscroggieST2.pdf")}

#render the supplementary figures
if(out_format=="pdf_document") {render("Figure_S1_withCaption.Rmd", "pdf_document", "SupportingInformation/JAEscroggieSF1.pdf")}
if(out_format=="pdf_document") {render("Figure_S2_withCaption.Rmd", "pdf_document", "SupportingInformation/JAEscroggieSF2.pdf")}


#render the appendix
if(out_format=="pdf_document") {render("Appendix_S1.Rmd", "pdf_document", "SupportingInformation/JAEscroggieSA1.pdf")}