## ----mcmc_results_site_fox, eval=TRUE, echo=FALSE, cache=TRUE, fig.cap='Posterior densities of transect-level random effects ($\\zeta_{i}$) on rates-of-increase for foxes at the 21 transects.', dependson="hier_model",  fig.pos="p!"----
#ggs_caterpillar(mcmc_result, family = "site.r.eff")+ theme_classic()
require(ggplot2)
require(ggmcmc)
require(dplyr)

args=commandArgs(trailingOnly=TRUE)


model_data=args[1]
out_pdf=file.path(args[2])
out_png=gsub("pdf", "png", out_pdf)

load(file.path(model_data))

sitelabs<-as.character(unique(obs_data$site))

sitelabs[sitelabs=="Yarram/Woodside"]<-"Yarram"

raneff_result_fox<-ggs(samp, family="^site.r.eff.centered\\[")
param_names<-levels(raneff_result_fox$Parameter)

ggplot(raneff_result_fox, aes(factor(Parameter), value))+
	geom_violin(fill="darkorange3", alpha=0.65)+
	geom_hline(yintercept=0, col="black", linetype = "longdash")+
	ylab(expression(paste(zeta[i])))+
	scale_x_discrete(limits=levels(raneff_result_fox$Parameter), labels=sitelabs)+
	xlab("")+
	coord_flip()+
	theme_classic()

ggsave(out_pdf)
ggsave(out_png)