library(rmarkdown)

args = commandArgs(trailingOnly=TRUE)

#desired format for ouput paper
out_format=args[1]

if(out_format=="word_document"){render("Fox_model_paper.Rmd", "word_document")}
if(out_format=="word_document"){render("Supporting_Information.Rmd", "word_document")}

if(out_format=="pdf_document") {render("Fox_model_paper.Rmd", "pdf_document")}
if(out_format=="pdf_document") {render("Supporting_Information.Rmd", "pdf_document")}