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

beta_result<-data.frame(cbind(samp$sims.list$beta
						)) %>%
	               rename('beta[1]'=X1, 
	               	  'beta[2]'=X2, 
	               	  'beta[3]'=X3, 
	               	  'beta[4]'=X4,
	               	  'beta[5]'=X5, 
	               	  'beta[6]'=X6,
	               	  'beta[7]'=X7, 
	               	  'beta[8]'=X8
	               	  ) %>%
					gather()	%>%
	                    rename(Parameter=key) %>%
	   mutate()

beta_result$species[grep("[1234]", beta_result$Parameter)]<-"Fox"
beta_result$species[grep("[5678]", beta_result$Parameter)]<-"Rabbit"
				
SS<-beta_result %>%
	group_by(Parameter) %>%
	summarise(mean=mean(value), sd=sd(value), lwr=quantile(value, 0.025), upp=quantile(value, 0.975))

beta_graph<-ggplot(beta_result, aes(x=Parameter, y=value, fill=species)) +
	geom_violin(scale="width", alpha=0.6) +
	scale_x_discrete(labels=expression(atop(beta[1], NR(fox)), 
								atop(beta[2], DD(fox)), 
								atop(beta[3], rain(fox)), 
								atop(beta[4], winter(fox)), 
								atop(beta[5], DD(rabbit)), 
								atop(beta[6], rain(rabbit)), 
								atop(beta[7], winter(rabbit)), 
								atop(beta[8], ripping(rabbit))))+
	scale_fill_manual(values=c("darkorange3", "blue"))+
	geom_hline(yintercept=0, col="black", linetype = "longdash")+
	xlab("")+
	ylab("Parameter value")+
	theme_bw()+
	theme(legend.position="none")+
	theme(axis.text.x=element_text(size=9))

##############################################################################################################
#lag graph
lag_result<-data.frame(cbind(samp$sims.list$fox.lag, 
						samp$sims.list$rabbit.lag, 
						samp$sims.list$food.lag*6
     )) %>%
	rename('k[fox]'=X1, 
		  'k[rabbit]'=X2, 
		  'k[NR]'=X3
	) %>%
	gather()	%>%
	rename(Parameter=key)

lag_result$species[grep("fox", lag_result$Parameter)]<-"Fox"
lag_result$species[grep("rabbit", lag_result$Parameter)]<-"Rabbit"

lag_graph<-ggplot(lag_result, aes(x=value, fill=species)) +
	geom_histogram(alpha=0.6, binwidth=1) +
	facet_grid(.~Parameter, labeller=label_parsed)+
	scale_fill_manual(values=c("darkorange3", "blue"))+
	xlab("Maximum lag period (months)")+
	ylab("")+
	theme_bw()+
	theme(legend.position="none")+	
	theme(strip.background = element_blank(), strip.text.x=element_text(hjust=0.1),
								  panel.border = element_rect(colour = "black"),
								  axis.text.x=element_text(angle=0, vjust=0.5, hjust=0)) 


pdf(paste(out_pdf), width=8, height=8)
grid.arrange(beta_graph, lag_graph, ncol=1, nrow=2)
dev.off()

png(paste(out_png), width=8, height=8, units="in", res=300)
grid.arrange(beta_graph, lag_graph, ncol=1, nrow=2)
dev.off()



