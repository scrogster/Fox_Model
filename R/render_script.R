library(rmarkdown)

args = commandArgs(trailingOnly=TRUE)

#desired format for ouput paper
out_format=args[1]

#utility function to convert latex \begin{align} .. \end{align} blocks to $$..$$ so that they will work in conversion to docx (misses equation numbers though) 
convert_align<-function(infile, outfile){
	x <- readLines(infile)
	x<-stringr::str_replace(x, "\\\\begin\\{align\\}", "$$")
	x<-stringr::str_replace(x, "\\\\end\\{align\\}", "$$")
	x<-stringr::str_replace(x, "&=", "=")
	#x[grep("\begin\\\{align}", x)]<-"$$"
	#x[grep("\end\\\{align}", x)]<-"$$"
	cat(x, file=outfile, sep="\n") }

#Make the word documents...
if(out_format=="word_document"){
	convert_align("Fox_model_paper.Rmd", "Fox_model_paperW.Rmd")
	rmarkdown::render("Fox_model_paperW.Rmd", "word_document", "Fox_model_paper.docx")
	file.remove("Fox_model_paperW.Rmd")
}

if(out_format=="word_document"){render("Supporting_Information.Rmd", "word_document")}


if(out_format=="pdf_document") {render("Fox_model_paper.Rmd", "pdf_document")}
if(out_format=="pdf_document") {render("Supporting_Information.Rmd", "pdf_document")}

file.remove("Fox_model_paper.fff")