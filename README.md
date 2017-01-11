
# Testing the numerical response of Red Fox populations to Rabbit abundance

This repository contains all data and code necessary to replicate the results of the analysis. 

The models are fitted using *R* and *JAGS* so installation of current versions of those software packages will be necessary, along with several *R* packages such as *dplyr, ggplot2, knitr, rmarkdown, readr, tidyr, stringr, rjags and ggmcmc*. 

If *R* reports a missing package, just install what's missing from CRAN and try again.

To fit the models and generate other associated outputs (figures, tables, manuscript) take the following steps:
## 1. Clone the repository

	git clone https://github.com/scrogster/Fox_Model

## 2. Run the analysis 
The -j10 directive tells *make* to run the 10 candidate models in parallel on a multicore system. This will take quite some time. Running the multiple models in parallel on my machine took over 8 hrs.

    cd Fox_Model
	make -j10

*Make* will format the data, fit the 10 models using JAGS, generate a variety of graphs (stored in /Figures), and generate .pdf and .docx versions of a manuscript documenting the results.