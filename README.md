![zenodo doi badge](https://zenodo.org/badge/DOI/10.5281/zenodo.1313890.svg)

Data and code from: 

Scroggie, M.P., Forsyth, D.F., McPhee, S., Matthews, J., Stuart, I.G., Stamation, K.A., Lindeman, M. & Ramsey, D.S.L. (2018) Invasive prey controlling invasive predators? European rabbit abundance does not determine red fox population dynamics. *Journal of Applied Ecology*

This repository contains all data and code necessary to replicate the results of the analysis presented in the paper. 

The model is fitted using *R* and *JAGS* so installation of current versions of those software packages will be necessary, along with several *R* packages such as *dplyr, ggplot2, ggmcmc, gridExtra, knitr, rmarkdown, readr, tidyr, stringr, rjags and jagsUI*.

The manuscript is compiled to a pdf from Rmarkdown using pandoc and latex, so these will be required also.

**Notes** 

*25 June 2019* This version implements a minor bugfix: an error in the indexing of covariate values related to season and warren ripping has been corrected, leading to some minor changes in some parameter estimates, but no change to the overall conclusions of the analysis. Thanks to Nick Golding for detecting this error. 
