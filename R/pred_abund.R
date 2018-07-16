require(ggmcmc)
require(dplyr)
require(readr)
require(lubridate)
dir.create("Figures", showWarnings = FALSE)

args=commandArgs(trailingOnly=TRUE)

model_data=args[1]
out_pdf=file.path(args[3])
rip_data=file.path(args[2])

#model_data="Fitted_rain_model.Rdata"
#out_pdf = "Figures/fox_abund.pdf"
#rip_data=file.path("Data/ripping_data.csv")
out_png=gsub("pdf", "png", out_pdf)

#preferred ordering of sites (increasing rainfall)
siteorder<-c("Manangatang", "Cowangie", "Piambie", 
		   "Telopea Downs", "Black Range", "Dunluce",
		   "Landsborough", "Ararat", "Chatsworth",
		   "Spring Hill", "Swifts Creek", "Ingliston",
		   "Pentland Hills", "Rowsley", "Harcourt",
		   "Yarram", "Skipton", "Lancefield",
		   "Beechworth", "Yambuk", "Euroa")

rip_dat<-read_csv(rip_data) %>%
	rename(Sitename=MonitorSite) %>%
	mutate(Time=year(RippedDate) + month(RippedDate)/12)

rip_dat$Sitename<-factor(rip_dat$Sitename, levels=siteorder)

load(file.path(model_data))

preds<-ggs(samp$samples) %>%
	   filter(grepl("mu", Parameter))
aa<-group_by(preds, Parameter)
pred_summary<-summarise(aa, post.mean = mean(value), 
				    post.med = median(value),
				    q5 =quantile(value, 0.05),
				    q10 =quantile(value, 0.1),
				    q25 =quantile(value, 0.25),
				    q75=quantile(value, 0.75),
				    q90 =quantile(value, 0.9),
				    q95=quantile(value, 0.95))
splitter<-function(x){
	bb<-unlist(strsplit(as.character(x), '[\\[,\\]'))
	cc<-unlist(strsplit(bb[3], '\\]'))
	out<-c(bb[1], as.numeric(as.character(bb[2])), as.numeric(as.character(cc)))
	out
}
vars<-t(sapply(as.character(pred_summary$Parameter), splitter))
vars<-data.frame(vars)
names(vars)<-c("Param", "Time", "Site")
vars$Time<-as.numeric(as.character(vars$Time))
vars$Site<-as.numeric(as.character(vars$Site))
preddf<-data.frame(pred_summary, vars)
preddf$time.orig<-1996 +(preddf$Time-1)/2
#tabulation of site codes and names, adding site names to the dataframe for plot labelling
labelling_tab<-data.frame(
	"Site"=unique(spotlight$Site))
row.names(labelling_tab)<-as.numeric(factor(unique(spotlight$Site)))
preddf$Sitename<-labelling_tab$Site[preddf$Site]

## ----tidy_obs_data, cache=FALSE, echo=FALSE, message=FALSE---------------
tidy_obs<-data.frame(
	"fox.count"=spotlight$Foxes,
	"rabbit.count"=spotlight$Rabbits,
	"trans.length"=spotlight$TransectLength,
	"Site"=as.numeric(factor(spotlight$Site)),
	"Sitename"=factor(spotlight$Site),
	"Time"=spotlight$ytime_disc  ,
 	"PostRipped"=spotlight$PostRipped
) 

tidy_obs<-tidy_obs %>%
	mutate(fox.count=ifelse(fox.count==0, 0.05, fox.count),rabbit.count=ifelse(rabbit.count==0, 0.05, rabbit.count))

#recode "Yarram/Woodside" to just "Yarram" in preddf and tidy_obs
tempsites<-as.character(preddf$Sitename)
tempsites[tempsites=="Yarram/Woodside"]<-"Yarram"
preddf$Sitename<-factor(tempsites, levels=siteorder)

tempsites<-as.character(tidy_obs$Sitename)
tempsites[tempsites=="Yarram/Woodside"]<-"Yarram"
tidy_obs$Sitename<-factor(tempsites, levels=siteorder)


preddf %>%
	filter(Param=="mu.fox") %>%
	ggplot(aes(x=time.orig, y=post.med))+
	annotate("rect", xmin=2001, xmax=2010, ymin=0, ymax=Inf, fill="gray",alpha=0.5)+
	geom_line(colour="black")+
	geom_point(data=tidy_obs %>% filter(rabbit.count>0.01), aes(x=Time, y=rabbit.count/(trans.length/1000), size=0.2), cex=0.8, shape=16) +
	geom_point(data=tidy_obs %>% filter(fox.count>0.01), aes(x=Time, y=fox.count/(trans.length/1000), size=0.2), cex=0.8, shape=2) +
	geom_ribbon(aes(ymin=q5,ymax=q95, colour=NULL),alpha=0.25, fill="darkorange3")+
	geom_ribbon(aes(ymin=q10,ymax=q90, colour=NULL),alpha=0.45, fill="darkorange3")+
	geom_ribbon(aes(ymin=q25,ymax=q75, colour=NULL),alpha=0.65, fill="darkorange3")+
	geom_line(data=preddf %>% filter(Param=="mu.rabbits"), aes(x=time.orig, y=post.med), colour="black")+
	geom_ribbon(data=preddf %>% filter(Param=="mu.rabbits"), aes(ymin=q5,ymax=q95, colour=NULL),alpha=0.25, fill="blue")+
	geom_ribbon(data=preddf %>% filter(Param=="mu.rabbits"), aes(ymin=q10,ymax=q90, colour=NULL),alpha=0.45, fill="blue")+
	geom_ribbon(data=preddf %>% filter(Param=="mu.rabbits"), aes(ymin=q25,ymax=q75, colour=NULL),alpha=0.65, fill="blue")+
	scale_y_log10(breaks=c(0.1, 1, 10, 100))+
	scale_x_continuous(breaks=seq(1995, 2017, 5), minor_breaks=seq(1995, 2016, 1), lim=c(1995, 2017) )+
	geom_vline(data=rip_dat, aes(xintercept=Time), col="black", lwd=0.5, lty="dashed")+
	labs(y=expression(Number~km^{-1}), x=expression(Time))+
	facet_wrap(~Sitename,  ncol=3, nrow=7) +
	theme_bw()+
	theme(strip.background = element_blank(), 
		 strip.text.x=element_text(hjust=0.05, size=8),
		 strip.text.y=element_text( size=8),
		 axis.text.x=element_text( size=8),
		 axis.text.y=element_text( size=8),
		 axis.title.x=element_text( size=8),
		 axis.title.y=element_text( size=8),
		 panel.border = element_rect(colour = "black"),
		 panel.spacing.x=unit(0.5, "mm"),
		 panel.spacing.y=unit(0, "mm"),
		 panel.grid.major=element_line(colour="grey50", size=0.15),
		 panel.grid.minor=element_line(colour="grey80", size=0.05))
ggsave(out_pdf, width=160/25.4, height=8)

