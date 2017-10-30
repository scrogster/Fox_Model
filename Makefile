
all: prepped_data.Rdata models figures  paper

clean:
	rm -f *.Rdata;\
	rm -f Figures/raneff_violin_foxes.pdf Figures/beta_posterior_density.pdf Figures/sigma_posterior_density.pdf Figures/raneff_violin_rabbits.pdf  Figures/predicted_fox_r.pdf Figures/fox_abund.pdf Figures/rabbit_abund.pdf Figures/beta_traceplots.pdf Figures/rain_graph.pdf;\
	rm -f Fox_model_paper.docx Fox_model_paper.pdf

#metarule to fit the models
models: Fitted_SOI_model.Rdata Fitted_rain_model.Rdata

#metarule to make the figures
figures: Figures/beta_posterior_density.pdf Figures/sigma_posterior_density.pdf Figures/raneff_violin.pdf  Figures/fox_abund.pdf Figures/rabbit_abund.pdf #Figures/predicted_fox_r.pdf Figures/beta_traceplots.pdf Figures/rain_graph.pdf 

#metarule to make the paper
paper: Fox_model_paper.docx Fox_model_paper.pdf

###############################################################################	
#clean and tidy the data, and save to an Rdata file                           #
###############################################################################	
prepped_data.Rdata: Data/spotlight_data.csv Data/TabulatedRainHalfYearly_updated.csv R/prep_data.R
	Rscript R/prep_data.R

###############################################################################	
#Run the state-space models and save the results                               #
###############################################################################
Fitted_rain_model.Rdata: R/run_model_rain.R prepped_data.Rdata  R/GHR_distlag_rain.txt 
	Rscript $^ $@    
	
PREF_RESULT = Fitted_rain_model.Rdata
###############################################################################	
#generate the figures as pdfs, pngs done implicitly                           #
###############################################################################
Figures/beta_posterior_density.pdf: R/beta_posterior_density.R $(PREF_RESULT)
	Rscript $^ $@
	
Figures/sigma_posterior_density.pdf: R/sigma_posterior_density.R $(PREF_RESULT)
	Rscript $^ $@

Figures/raneff_violin.pdf: R/raneff_violin.R $(PREF_RESULT) 
	Rscript $^ $@

Figures/predicted_fox_r.pdf: R/predicted_fox_r.R $(PREF_RESULT) 
	Rscript $^ $@
	
Figures/fox_abund.pdf Figures/rabbit_abund.pdf: R/pred_abund.R $(PREF_RESULT) 
	Rscript $^ $@
	
Figures/rain_graph.pdf: R/rain_graph.R $(PREF_RESULT)
	Rscript $^ $@

Figures/beta_traceplots.pdf: R/diagnostic_plots.R $(PREF_RESULT)
	Rscript $^

###############################################################################	
#generate the paper as a word document                                        #
###############################################################################
Fox_model_paper.docx: R/render_script.R Fox_model_paper.Rmd rabbit_refs.bib models figures 
	Rscript R/render_script.R word_document
Fox_model_paper.pdf: R/render_script.R Fox_model_paper.Rmd rabbit_refs.bib models figures 
	Rscript R/render_script.R pdf_document
