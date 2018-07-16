
# Testing the numerical response of Red Fox populations to Rabbit abundance

This repository contains all data and code necessary to replicate the results of the analysis. 

The models are fitted using *R* and *JAGS* so installation of current versions of those software packages will be necessary, along with several *R* packages such as *dplyr, ggplot2, ggmcmc, gridExtra, knitr, rmarkdown, readr, tidyr, stringr, rjags and jagsUI*.

To fit the models and generate other associated outputs (figures, tables, manuscript) take the following steps:
## 1. Clone the repository

	git clone https://github.com/scrogster/Fox_Model

## 2. Run the analysis 


    cd Fox_Model
	make

*make* will format the data, fit the model using JAGS, generate a variety of graphs (stored in /Figures), and generate .pdf manuscript documenting the results.