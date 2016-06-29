## ----mcmc_plot_beta, echo=FALSE, cache=FALSE, fig.cap='Posterior distributions of the regression parameters ($\\beta$).', dependson="hier_model", fig.pos="p!", message=FALSE----
require(ggplot2)
require(ggmcmc)
require(grid)
require(dplyr)

args=commandArgs(trailingOnly=TRUE)


model_data=args[1]
out_pdf=file.path(args[2])
out_png=gsub("pdf", "png", out_pdf)
	
load(file.path(model_data))

beta_result<-ggs(samp, family="^beta|^r.mean")

#code to put proper math notation in facet labels of plot
pname<-as_labeller(c(
	'beta[1]'="beta[1]",
	'beta[2]'="beta[2]",
	'beta[3]'="beta[3]",
	'beta[4]'="beta[4]",
	'beta[5]'="beta[5]",
	'beta[6]'="beta[6]",
	'beta[7]'="beta[7]",
	'r.mean'="bar(r)[fox]",
	'r.mean.rabbits'="bar(r)[rabbit]")
	, label_parsed
)

ggplot(beta_result, aes(x=value, group=Parameter))+
	geom_density(fill="green", alpha=0.3)+
	xlab("")+
	ylab("")+
	facet_wrap(~Parameter, labeller=pname)+
	geom_vline(xintercept=0, col="black", linetype = "longdash")+
	theme_classic()

ggsave(out_pdf)
ggsave(out_png)

