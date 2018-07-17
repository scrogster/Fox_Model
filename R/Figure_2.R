require(ggplot2)
require(ggmcmc)
require(grid)
require(gridExtra)
require(dplyr)
dir.create("Figures", showWarnings = FALSE)

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
	               rename('beta[5]'=X1, 
	               	  'beta[6]'=X2, 
	               	  'beta[7]'=X3, 
	               	  'beta[8]'=X4,
	               	  'beta[1]'=X5, 
	               	  'beta[2]'=X6,
	               	  'beta[3]'=X7, 
	               	  'beta[4]'=X8
	               	  ) %>%
					gather()	%>%
	                    rename(Parameter=key) %>%
	   mutate()

beta_result$species[grep("[1234]", beta_result$Parameter)]<-"Rabbit"
beta_result$species[grep("[5678]", beta_result$Parameter)]<-"Fox"

SS<-beta_result %>%
	group_by(Parameter) %>%
	summarise(mean=mean(value), sd=sd(value), lwr=quantile(value, 0.025), upp=quantile(value, 0.975))

beta_graph<-ggplot(beta_result, aes(x=Parameter, y=value, fill=species)) +
	geom_violin(scale="width", alpha=0.6, draw_quantiles = c(0.025, 0.5, 0.975)) +
	scale_x_discrete(labels=expression(atop(beta[1], DD(rabbit)), 
								atop(beta[2], rain(rabbit)), 
								atop(beta[3], winter(rabbit)), 
								atop(beta[4], ripping(rabbit)), 
								atop(beta[5], NR(fox)), 
								atop(beta[6], DD(fox)), 
								atop(beta[7], rain(fox)),
								atop(beta[8], winter(fox))))+
	scale_fill_manual(values=c("darkorange3", "blue"))+
	geom_hline(yintercept=0, col="black", linetype = "longdash")+
	xlab("")+
	ylab("Parameter value")+
	ggtitle("A")+
	theme_bw()+
	theme(legend.position="none")+
	theme(axis.text.x=element_text(size=8))+ 
	theme(plot.title = element_text(lineheight=1.8, face="bold"))

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

lag_result$Parameter<-factor(lag_result$Parameter, levels=c("k[rabbit]", "k[fox]", "k[NR]"))

ann_text<-lag_result %>%
	group_by(Parameter) %>%
	summarize(Param=first(Parameter)) %>%ungroup() %>%
	select(Parameter) %>%
	mutate(value=c(1L, 1L, 1L), species=c("Rabbit", "Fox", "Fox")) %>%
	mutate(Param2=c("italic(k[rabbit])", "italic(k[fox])", "italic(k[NR])"))

lag_graph<-ggplot(lag_result, aes(x=value, fill=species)) +
	geom_histogram(alpha=0.6, binwidth=1) +
	facet_grid(.~Parameter, labeller=label_parsed)+
	geom_text(data=ann_text, aes(x=15, y=3000, label=Param2), fontface="italic", parse = TRUE)+
	scale_fill_manual(values=c("darkorange3", "blue"))+
	xlab("Maximum lag period (months)")+
	ylab("")+
	ggtitle("B")+
	theme_bw()+
	theme(legend.position="none")+	
	theme(strip.background = element_blank(), 
		 strip.text.x=element_blank(), 
	      panel.border = element_rect(colour = "black"),
		axis.text.x=element_text(angle=0, vjust=0.5, hjust=0.5))+ 
	theme(plot.title = element_text(lineheight=1.8, face="bold")) 


pdf(paste(out_pdf), width=160/25.4, height=160/25.4)
grid.arrange(beta_graph, lag_graph, ncol=1, nrow=2)
dev.off()



