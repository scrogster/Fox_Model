## ----mcmc_plot_beta, echo=FALSE, cache=FALSE, fig.cap='Posterior distributions of the regression parameters ($\\beta$).', dependson="hier_model", fig.pos="p!", message=FALSE----
require(ggplot2)
require(ggmcmc)
require(grid)
require(dplyr)

args=commandArgs(trailingOnly=TRUE)

model_data=args[1]
file_loc=args[2]
#model_data="Fitted_rain_model.Rdata"
#file_loc = "Figures/beta_posterior_density.pdf"
out_pdf=file.path(file_loc)
out_png=gsub("pdf", "png", out_pdf)
	
load(file.path(model_data))

beta_result<-data.frame(cbind(samp$sims.list$beta, 
						 samp$sims.list$r.mean.rabbits, 
						 samp$sims.list$r.mean )) %>%
	               rename('beta[1]'=X1, 'beta[2]'=X2, 'beta[3]'=X3, 'beta[4]'=X4,'beta[5]'=X5, 
	               	  'beta[6]'=X6,'beta[7]'=X7, 'beta[8]'=X8,
	               	  'bar(r)[rabbit]' =X9,
	               	  'bar(r)[fox]' = X10) %>%
					gather()	%>%
	                    rename(Parameter=key)
				

#code to put proper math notation in facet labels of plot
pname<-as_labeller(c(
	'beta[1]'="beta[1]",
	'beta[2]'="beta[2]",
	'beta[3]'="beta[3]",
	'beta[4]'="beta[4]",
	'beta[5]'="beta[5]",
	'beta[6]'="beta[6]",
	'beta[7]'="beta[7]",
	'bar(r)[rabbit]'="bar(r)[rabbit]",
	'bar(r)[fox]'="bar(r)[fox]")
	, label_parsed
)

SS<-beta_result %>%
	group_by(Parameter) %>%
	summarise(mean=mean(value), sd=sd(value), lwr=quantile(value, 0.025), upp=quantile(value, 0.975))

ggplot(SS, aes(x=mean, y=Parameter))+
	geom_point(size=2)+
	geom_errorbarh(aes(xmin=lwr, xmax=upp), height=0) +
	xlab("")+
	ylab("")+
	scale_y_discrete(labels=expression(bar(r)[fox], bar(r)[rabbit], beta[1], beta[2], beta[3], beta[4], beta[5], beta[6], beta[7], beta[8]))+
	geom_vline(xintercept=0, col="black", linetype = "longdash")+
	theme_bw()

ggsave(out_pdf)
ggsave(out_png)

