require(rmarkdown)

args=commandArgs(trailingOnly=TRUE)

paper=file.path(args[1])
supp=file.path(args[2])

rmarkdown::render("Fox_model_paper.Rmd")

rmarkdown::render("Supporting_Information.Rmd")