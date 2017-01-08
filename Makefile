
all: prepped_data.Rdata models figures paper


#metarule to fit the models
models: model_results_6_6.Rdata model_results_0_6.Rdata model_results_6_0.Rdata model_results_0_0.Rdata model_results_12_12.Rdata model_results_12_6.Rdata model_results_6_12.Rdata model_results_0_12.Rdata model_results_12_0.Rdata model_results_norain.Rdata DIC_results.Rdata

#metarule to make the figures
figures: Figures/raneff_violin_foxes.pdf Figures/beta_posterior_density.pdf Figures/sigma_posterior_density.pdf Figures/raneff_violin_rabbits.pdf  Figures/predicted_fox_r.pdf Figures/fox_abund.pdf Figures/rabbit_abund.pdf Figures/beta_traceplots.pdf Figures/rain_graph.pdf 

#metarule to make the paper
paper: Fox_model_paper.docx Fox_model_paper.pdf

###############################################################################	
#clean and tidy the data, and save to an Rdata file                           #
###############################################################################	
prepped_data.Rdata: Data/spotlight_data.csv Data/SOI.txt Data/TabulatedRainHalfYearly_updated.csv R/prep_data.R
	Rscript R/prep_data.R

###############################################################################	
#Run the state-space model and save the results                               #
###############################################################################
#12-month lag on foxes, 0-month lag on rabbits 
model_results_12_0.Rdata: R/run_model.R prepped_data.Rdata  R/GHR_12_0.txt 
	Rscript $^ $@    

#zero lag on foxes, 12-month lag on rabbits 
model_results_0_12.Rdata: R/run_model.R prepped_data.Rdata  R/GHR_0_12.txt 
	Rscript $^ $@    

#six-month lag on foxes, 12-month lag on rabbits 
model_results_6_12.Rdata: R/run_model.R prepped_data.Rdata  R/GHR_6_12.txt 
	Rscript $^ $@    

#twelve-month lag on foxes, six-month lag on rabbits 
model_results_12_6.Rdata: R/run_model.R prepped_data.Rdata  R/GHR_12_6.txt 
	Rscript $^ $@    

#twelve-month lag on foxes, twelve-month lag on rabbits 
model_results_12_12.Rdata: R/run_model.R prepped_data.Rdata  R/GHR_12_12.txt 
	Rscript $^ $@    

#six-month lag on foxes, six-month lag on rabbits
model_results_6_6.Rdata: R/run_model.R prepped_data.Rdata  R/GHR_6_6.txt 
	Rscript $^ $@    

#zero lag on foxes, six-month on rabbits
model_results_0_6.Rdata: R/run_model.R prepped_data.Rdata  R/GHR_6_0.txt 
	Rscript $^ $@    

#six-month lag on foxes, zero-lag on rabbits
model_results_6_0.Rdata: R/run_model.R prepped_data.Rdata  R/GHR_0_6.txt 
	Rscript $^ $@    

#zero-lag on rabbits, zero lag on foxes
model_results_0_0.Rdata: R/run_model.R prepped_data.Rdata  R/GHR_0_0.txt 
	Rscript $^ $@    
	
##No rain effect model.
model_results_norain.Rdata: R/run_model.R prepped_data.Rdata R/GHR_norain.txt
	Rscript $^ $@  

DIC_results.Rdata: R/get_dics.R model_results_12_0.Rdata
	Rscript $< $@

PREF_RESULT = model_results_6_12.Rdata
###############################################################################	
#generate the figures as pdfs, pngs done implicitly                           #
###############################################################################
Figures/beta_posterior_density.pdf: R/beta_posterior_density.R $(PREF_RESULT)
	Rscript $^ $@
	
Figures/sigma_posterior_density.pdf: R/sigma_posterior_density.R $(PREF_RESULT)
	Rscript $^ $@

Figures/raneff_violin_foxes.pdf: R/raneff_violin_foxes.R $(PREF_RESULT) 
	Rscript $^ $@

Figures/raneff_violin_rabbits.pdf: R/raneff_violin_rabbits.R $(PREF_RESULT) 
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
