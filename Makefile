
all: prepped_data.Rdata model_results.Rdata figures

#metarule to make the figures
figures: Figures/beta_posterior_density.pdf Figures/sigma_posterior_density.pdf Figures/raneff_violin.pdf Figures/predicted_fox_r.pdf Figures/fox_abund.pdf Figures/beta_traceplots.pdf


###############################################################################	
#clean and tidy the data, and save to an Rdata file                           #
###############################################################################	
prepped_data.Rdata: Data/kasey.xls Data/SOI.txt Data/TabulatedRainHalfYearly.csv R/prep_data.R
	Rscript R/prep_data.R

###############################################################################	
#Run the state-space model and save the results                               #
###############################################################################
model_results.Rdata:   R/run_model.R prepped_data.Rdata  R/gompertz_heirarch_rain.txt 
	Rscript $<

###############################################################################	
#generate the figures as pdfs, pngs done implicitly                           #
###############################################################################
Figures/beta_posterior_density.pdf: R/beta_posterior_density.R model_results.Rdata 
	Rscript $<
	
Figures/sigma_posterior_density.pdf: R/sigma_posterior_density.R model_results.Rdata 
	Rscript $<

Figures/raneff_violin.pdf: R/raneff_violin.R model_results.Rdata 
	Rscript $<

Figures/predicted_fox_r.pdf: R/predicted_fox_r.R model_results.Rdata 
	Rscript $<
	
Figures/fox_abund.pdf: R/pred_abund.R model_results.Rdata 
	Rscript $<
	
Figures/rain_graph.pdf: R/rain_graph.R model_results.Rdata 
	Rscript $<

Figures/beta_traceplots.pdf: R/diagnostic_plots.R model_results.Rdata
	Rscript $<
