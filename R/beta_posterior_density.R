## ----mcmc_plot_beta, echo=FALSE, cache=FALSE, fig.cap='Posterior distributions of the regression parameters ($\\beta$).', dependson="hier_model", fig.pos="p!", message=FALSE----
require(ggplot2)
require(ggmcmc)

load("model_results.Rdata")

beta_result<-ggs(samp, family="^beta|^r.mean")
ggplot(beta_result, aes(x=value, group=Parameter))+
	geom_density(fill="red", alpha=0.3)+
	xlab("")+
	ylab("")+
	facet_wrap(~Parameter)+
	geom_vline(xintercept=0, col="black", linetype = "longdash")+
	theme_classic()

ggsave("Figures/beta_posterior_density.pdf")
ggsave("Figures/beta_posterior_density.png")

