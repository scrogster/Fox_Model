## ----mcmc_plot_beta, echo=FALSE, cache=FALSE, fig.cap='Posterior distributions of the regression parameters ($\\beta$).', dependson="hier_model", fig.pos="p!", message=FALSE----
require(ggplot2)
require(ggmcmc)
require(grid)

load("model_results.Rdata")

beta_result<-ggs(samp, family="^beta|^r.mean")


ggplot(beta_result, aes(x=value, group=Parameter))+
	geom_density(fill="red", alpha=0.3)+
	xlab("")+
	ylab("")+
	facet_wrap(~Parameter)+
	geom_vline(xintercept=0, col="black", linetype = "longdash")+
	theme_classic()

#http://stackoverflow.com/questions/11979017/changing-facet-label-to-math-formula-in-ggplot2
for(ii in 1:7){
	grid.gedit(gPath(paste0("strip_t-", ii), "strip.text"), 
			 grep=TRUE, label=bquote(beta[.(ii)]))}
grid.gedit(gPath(paste0("strip_t-", 8), "strip.text"), 
		 grep=TRUE, label=bquote(bar(r)[fox]))
grid.gedit(gPath(paste0("strip_t-", 9), "strip.text"), 
		 grep=TRUE, label=bquote(bar(r)[rabbit]))

ggsave("Figures/beta_posterior_density.pdf")
ggsave("Figures/beta_posterior_density.png")

