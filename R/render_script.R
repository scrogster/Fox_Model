library(rmarkdown)

args = commandArgs(trailingOnly=TRUE)

#desired format for ouput paper
out_format=args[1]



if(out_format=="pdf_document") {render("Fox_model_paper.Rmd", "pdf_document"); file.remove("Fox_model_paper.fff")}
if(out_format=="pdf_document") {render("Table_S1.Rmd", "pdf_document")}
if(out_format=="pdf_document") {render("Table_S2.Rmd", "pdf_document")}
if(out_format=="pdf_document") {render("Appendix_S1.Rmd", "pdf_document")}


if(out_format=="pdf_document") {render("Figure_S1_withCaption.Rmd", "pdf_document")}
if(out_format=="pdf_document") {render("Figure_S2_withCaption.Rmd", "pdf_document")}