require(ggplot2)
require(ggmcmc)
require(dplyr)

args=commandArgs(trailingOnly=TRUE)


model_data=args[1]
out_pdf=file.path(args[2])
#model_data="Fitted_rain_model.Rdata"
#out_pdf = "Figures/raneff_violin_foxes.pdf"
out_png=gsub("pdf", "png", out_pdf)

load(file.path(model_data))

sitelabs<-as.character(unique(spotlight$Site))

sitelabs[sitelabs=="Yarram/Woodside"]<-"Yarram"

raneff_result_fox<-data.frame(samp$sims.list$site.r.eff.centered)
    names(raneff_result_fox)<-sitelabs
    raneff_result_fox<-raneff_result_fox %>%
	gather() %>%
	mutate(Species="Fox")
    
raneff_result_rabbit<-data.frame(samp$sims.list$site.r.eff.rabbits.centered)
    names(raneff_result_rabbit)<-sitelabs
    raneff_result_rabbit<-raneff_result_rabbit %>%
    	gather() %>%
    	mutate(Species="Rabbit")

raneffs<-rbind(raneff_result_fox, raneff_result_rabbit)

#reorder sites in approximate order of mean monthly rainfall
siteorder<-c("Manangatang", "Cowangie", "Piambie", 
	    "Telopea Downs", "Black Range", "Dunluce",
	    "Landsborough", "Ararat", "Chatsworth",
	    "Spring Hill", "Swifts Creek", "Ingliston",
	    "Pentland Hills", "Rowsley", "Harcourt",
	    "Yarram", "Skipton", "Lancefield",
	    "Beechworth", "Yambuk", "Euroa")

#reorder sites with increasing rainfall
raneffs$key<-factor(raneffs$key, levels=siteorder)

raneff_summary<-raneffs %>%
	  group_by(Species, key) %>%
	  mutate(MEAN = mean(value), LWR=quantile(value, 0.025), UPP=quantile(value, 0.975))

ggplot(raneffs, aes(y=value, x=key, fill=Species)) +
	  	geom_violin(alpha=0.5, draw_quantiles = c(0.025, 0.5, 0.975))+
	  	facet_grid(Species~.)+
	geom_hline(yintercept=0, col="black", linetype = "longdash")+
	ylab(expression(paste(zeta[i])))+
	xlab("")+
	theme_bw()+
	scale_fill_manual(values=c("darkorange", "blue"))+
	theme(strip.background = element_blank(), 
		 strip.text.x=element_text(hjust=0.5),
		 panel.border = element_rect(colour = "black"))+
	theme(axis.text.x = element_text(angle = 90, hjust = 1, vjust=0.5))+
	guides(colour=FALSE, fill=FALSE)

ggsave(out_pdf, width=6, height=5)
