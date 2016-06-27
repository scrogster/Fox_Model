require(rmarkdown)

args=commandArgs(trailingOnly=TRUE)

rmarkdown::render("Fox_model_paper.Rmd")

rmarkdown::render("Supporting_Information.Rmd")