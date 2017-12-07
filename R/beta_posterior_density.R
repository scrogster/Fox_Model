## ----mcmc_plot_beta, echo=FALSE, cache=FALSE, fig.cap='Posterior distributions of the regression parameters ($\\beta$).', dependson="hier_model", fig.pos="p!", message=FALSE----
require(ggplot2)
require(ggmcmc)
require(grid)
require(gridExtra)
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
						 samp$sims.list$r.mean
						)) %>%
	               rename('beta[1]'=X1, 
	               	  'beta[2]'=X2, 
	               	  'beta[3]'=X3, 
	               	  'beta[4]'=X4,
	               	  'beta[5]'=X5, 
	               	  'beta[6]'=X6,
	               	  'beta[7]'=X7, 
	               	  'beta[8]'=X8,
	               	  'bar(r)[rabbit]' =X9,
	               	  'bar(r)[fox]' = X10
	               	  ) %>%
					gather()	%>%
	                    rename(Parameter=key)
				

#code to put proper math notation in facet labels of plot
#pname<-as_labeller(c(
#	'beta[1]'="beta[1]",   #NR rabbit density
#	'beta[2]'="beta[2]",   #DD fox
#	'beta[3]'="beta[3]",   #rain fox
#	'beta[4]'="beta[4]",   #winter fox
#	'beta[5]'="beta[5]",   #DD rabbit
#	'beta[6]'="beta[6]",   #rain rabbit
#	'beta[7]'="beta[7]",   #winter rabbit
#	'beta[8]'="beta[8]",   #ripping rabbit
#	'bar(r)[rabbit]'="bar(r)[rabbit]",
#	'bar(r)[fox]'="bar(r)[fox]")
#	, label_parsed
#)

SS<-beta_result %>%
	group_by(Parameter) %>%
	summarise(mean=mean(value), sd=sd(value), lwr=quantile(value, 0.025), upp=quantile(value, 0.975))

beta_graph<-ggplot(beta_result, aes(x=Parameter, y=value)) +
	geom_violin(scale="width", fill=gray(0.7)) +
	scale_x_discrete(labels=expression(bar(r)[fox], 
								bar(r)[rabbit], 
								atop(beta[1], NR(fox)), 
								atop(beta[2], DD(fox)), 
								atop(beta[3], rain(fox)), 
								atop(beta[4], winter(fox)), 
								atop(beta[5], DD(rabbit)), 
								atop(beta[6], rain(rabbit)), 
								atop(beta[7], winter(rabbit)), 
								atop(beta[8], ripping(rabbit))))+
	geom_hline(yintercept=0, col="black", linetype = "longdash")+
	xlab("")+
	ylab("Parameter value")+
	theme_bw()+
	theme(axis.text.x=element_text(size=9))

##############################################################################################################
#lag graph
lag_result<-data.frame(cbind(samp$sims.list$fox.lag, 
						samp$sims.list$rabbit.lag, 
						samp$sims.list$food.lag*6
     )) %>%
	rename('rain(fox)'=X1, 
		  'rain(rabbit)'=X2, 
		  'NR(fox)'=X3
	) %>%
	gather()	%>%
	rename(Parameter=key)

lag_graph<-ggplot(lag_result, aes(x=value)) +
	geom_histogram( fill=gray(0.3)) +
	facet_grid(Parameter~.)+
	xlab("Maximum lag period (months)")+
	ylab("")+
	theme_bw()


pdf(paste(out_pdf), width=9, height=8)
grid.arrange(beta_graph, lag_graph, ncol=1, nrow=2)
dev.off()

png(paste(out_png), width=9, height=8, units="in", res=300)
grid.arrange(beta_graph, lag_graph, ncol=1, nrow=2)
dev.off()



