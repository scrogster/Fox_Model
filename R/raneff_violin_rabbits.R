## ----mcmc_results_site_fox, eval=TRUE, echo=FALSE, cache=TRUE, fig.cap='Posterior densities of transect-level random effects ($\\zeta_{i}$) on rates-of-increase for foxes at the 21 transects.', dependson="hier_model",  fig.pos="p!"----
#ggs_caterpillar(mcmc_result, family = "site.r.eff")+ theme_classic()
require(ggplot2)
require(ggmcmc)
require(dplyr)

load("model_results.Rdata")

sitelabs<-as.character(unique(obs_data$site))

sitelabs[sitelabs=="Yarram/Woodside"]<-"Yarram"

raneff_result_rab<-ggs(samp, family="^site.r.eff.rabbits.centered")
param_names<-levels(raneff_result_rab$Parameter)

ggplot(raneff_result_rab, aes(factor(Parameter), value))+
	geom_violin(fill="slategray3", alpha=0.65)+
	geom_hline(yintercept=0, col="black", linetype = "longdash")+
	ylab(expression(paste(zeta[i])))+
	scale_x_discrete(limits=levels(raneff_result_rab$Parameter), labels=sitelabs)+
	xlab("")+
	coord_flip()+
	theme_classic()

ggsave("Figures/raneff_violin_rabbits.pdf")
ggsave("Figures/raneff_violin_rabbits.png")