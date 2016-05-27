
all: prepped_data.Rdata model_results.Rdata figures paper

#metarule to make the figures
figures: Figures/beta_posterior_density.pdf Figures/sigma_posterior_density.pdf Figures/raneff_violin_rabbits.pdf Figures/raneff_violin_foxes.pdf Figures/predicted_fox_r.pdf Figures/fox_abund.pdf Figures/rabbit_abund.pdf Figures/beta_traceplots.pdf Figures/rain_graph.pdf

paper: Fox_model_paper.docx  Supporting_Information.docx

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

Figures/raneff_violin_foxes.pdf: R/raneff_violin_foxes.R model_results.Rdata 
	Rscript $<

Figures/raneff_violin_rabbits.pdf: R/raneff_violin_rabbits.R model_results.Rdata 
	Rscript $<

Figures/predicted_fox_r.pdf: R/predicted_fox_r.R model_results.Rdata 
	Rscript $<
	
Figures/fox_abund.pdf Figures/rabbit_abund.pdf: R/pred_abund.R model_results.Rdata 
	Rscript $<
	
Figures/rain_graph.pdf: R/rain_graph.R model_results.Rdata 
	Rscript $<

Figures/beta_traceplots.pdf: R/diagnostic_plots.R model_results.Rdata
	Rscript $<

###############################################################################	
#generate the paper as a word document                                        #
###############################################################################
Fox_model_paper.docx Supporting_Information.docx: R/render_script.R Fox_model_paper.Rmd Supporting_Information.Rmd rabbit_refs.bib Template.docx figures
	Rscript $<
