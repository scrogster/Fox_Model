
# Testing the numerical response of Red Fox populations to Rabbit abundance

This repository contains all data and code necessary to replicate the results of the analysis. 

The models are fitted using *R* and *JAGS* so installation of current versions of those software packages will be necessary, along with several *R* packages such as *dplyr, ggplot2, gridExtra, knitr, rmarkdown, readr, tidyr, stringr, rjags and jagsUI*.

If *R* reports a missing package, just install what's missing from CRAN and try again.

To fit the models and generate other associated outputs (figures, tables, manuscript) take the following steps:
## 1. Clone the repository

	git clone https://github.com/scrogster/Fox_Model

## 2. Run the analysis 


    cd Fox_Model
	make

*make* will format the data, fit the model using JAGS, generate a variety of graphs (stored in /Figures), and generate .pdf and .docx versions of a manuscript documenting the results. Fitting the model is quite time-consuming. On my system, it took approximately 8 hours to fit the model, running 4 MCMC chains in parallel.