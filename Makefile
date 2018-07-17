
all: prepped_data.Rdata models figures  paper

clean:
	rm -f *.Rdata;\
	rm -f Figures/Figure_2.pdf Figures/Figure_3.pdf Figures/Figure_4.pdf Figures/raneff_violin.pdf  \
	Figures/Figure_S1.pdf Figures/Figure_S2.pdf Figures/Figure_S3.pdf Figures/Diagnostic_plots.pdf;\
	rm -f Fox_model_paper.pdf

#metarule to fit the models
models: Fitted_rain_model.Rdata

#metarule to make the figures
figures: Figures/Figure_2.pdf Figures/Figure_3.pdf Figures/Figure_4.pdf \
Figures/Figure_S1.pdf Figures/Figure_S2.pdf Figures/Figure_S3.pdf Figures/Diagnostic_plots.pdf

#metarule to make the paper
paper: Fox_model_paper.pdf

###############################################################################	
#clean and tidy the data, and save to an Rdata file                           #
###############################################################################	
prepped_data.Rdata: Data/spotlight_data.csv Data/AllRain.csv R/prep_data.R
	Rscript R/prep_data.R

###############################################################################	
#Run the state-space model and save the results                               #
###############################################################################
Fitted_rain_model.Rdata: R/run_model_rain.R prepped_data.Rdata  R/GHR_distlag_rain.txt 
	Rscript $^ $@    
	
###############################################################################	
#generate the figures as pdfs                                                 #
###############################################################################
  #Figure 2 --posterior densities
Figures/Figure_2.pdf: R/Figure_2.R Fitted_rain_model.Rdata  
	Rscript $^ $@
  #Figure 3 --predicted r for fox populations	
Figures/Figure_3.pdf: R/Figure_3.R Fitted_rain_model.Rdata
	Rscript $^ $@
  #Figure 4 --fox and rabbit abundances
Figures/Figure_4.pdf: R/Figure_4.R Fitted_rain_model.Rdata Data/ripping_data.csv
	Rscript $^ $@
	
###############################################################################	
#generate the supplementary figures as pdfs                                   #
###############################################################################
  #Figure S1 - rainfall time series
Figures/Figure_S1.pdf: R/Figure_S1.R Data/AllRain.csv
	Rscript $^ $@
  #Figure S2 - random effects density plots
Figures/Figure_S2.pdf: R/Figure_S2.R Fitted_rain_model.Rdata
	Rscript $^ $@
  #Figure S3 - Posterior Predictive Checks
Figures/Figure_S3.pdf: R/Figure_S3.R  Fitted_rain_model.Rdata
	Rscript $^
	
###############################################################################	
#generate the diagnostic plots                                                #
###############################################################################
Figures/Diagnostic_plots.pdf: R/diagnostic_plots.R Fitted_rain_model.Rdata
	Rscript $^

###############################################################################	
#generate the manuscript as a pdf document                                    #
###############################################################################
Fox_model_paper.pdf: R/render_script.R Fox_model_paper.Rmd rabbit_refs.bib models figures 
	Rscript R/render_script.R pdf_document
