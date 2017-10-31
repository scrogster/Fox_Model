require(ggmcmc)
require(dplyr)
require(readr)
require(lubridate)

args=commandArgs(trailingOnly=TRUE)

model_data=args[1]
out_pdf=file.path(args[3])
rip_data=file.path(args[2])

#model_data="Fitted_rain_model.Rdata"
#out_pdf = "Figures/fox_abund.pdf"
#rip_data=file.path("Data/ripping_data.csv")
out_png=gsub("pdf", "png", out_pdf)

rip_dat<-read_csv(rip_data) %>%
	rename(Sitename=MonitorSite) %>%
	mutate(Time=year(RippedDate) + month(RippedDate)/12)

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
preddf$Sitename<-factor(tempsites)

tempsites<-as.character(tidy_obs$Sitename)
tempsites[tempsites=="Yarram/Woodside"]<-"Yarram"
tidy_obs$Sitename<-factor(tempsites)

## ----fox_pred_graph, cache=FALSE, echo=FALSE, fig.height=9.5, fig.width=7.5, fig.cap='Predicted (line) and observed (points) relative abundances (spotlight counts per transect km) of foxes at each of the 21 study sites over the course of the study. Solid line is the posterior median, and shaded polygons are the 95\\% credible intervals of the mean expected abundances.', fig.pos="p!"----
#plotting estimated trajectories of all fox populations.
preddf %>%
	filter(Param=="mu.fox") %>%
	ggplot(aes(x=time.orig, y=post.med))+
	geom_line(colour="black")+
	geom_ribbon(aes(ymin=q5,ymax=q95, colour=NULL),alpha=0.25, fill="darkorange3")+
	geom_ribbon(aes(ymin=q10,ymax=q90, colour=NULL),alpha=0.45, fill="darkorange3")+
	geom_ribbon(aes(ymin=q25,ymax=q75, colour=NULL),alpha=0.65, fill="darkorange3")+
	ylab(expression(paste(log[10],"(Foxes k",m^{-1},")")))+
	xlab("Time")+
	scale_y_log10(breaks=c(0.01, 0.1, 1, 10), lim=c(0.001, 10.1))+
	scale_x_continuous(breaks=seq(1995, 2017, 5), minor_breaks=seq(1995, 2016, 1), lim=c(1995, 2017) )+
	geom_point(data=tidy_obs, aes(x=Time, y=fox.count/(trans.length/1000)), cex=0.5) +
	geom_vline(data=rip_dat, aes(xintercept=Time), col="black", lwd=0.8)+
	facet_wrap(~Sitename,  ncol=3, nrow=7) +
	theme_bw()+
	theme(strip.background = element_blank(), 
		 strip.text.x=element_text(hjust=0.05),
		 panel.border = element_rect(colour = "black"),
		 panel.grid.major=element_line(colour="grey50", size=0.15),
		 panel.grid.minor=element_line(colour="grey80", size=0.05))


ggsave(out_pdf, width=7, height=9)
ggsave(out_png, width=7, height=9, dpi=300)

## ----rabbit_pred_graph, cache=FALSE, echo=FALSE, message=FALSE, fig.height=9.5, fig.width=7.5, fig.cap='Predicted (line) and observed (points) relative abundances (spotlight counts per transect km) of rabbits at each of the 21 study sites over the course of the study. Solid line is the posterior median, and shaded polygons are the 95\\% credible intervals of the mean expected abundances.', fig.pos="p!"----
#plotting estimated trajectories of all rabbit populations.
preddf %>%
	filter(Param=="mu.rabbits") %>%
	ggplot(aes(x=time.orig, y=post.med))+
	geom_line(colour="black")+
	geom_ribbon(aes(ymin=q5,ymax=q95, colour=NULL),alpha=0.25, fill="slategray3")+
	geom_ribbon(aes(ymin=q10,ymax=q90, colour=NULL),alpha=0.45, fill="slategray3")+
	geom_ribbon(aes(ymin=q25,ymax=q75, colour=NULL),alpha=0.65, fill="slategray3")+
	ylab(expression(paste(log[10],"(Rabbits k",m^{-1},")")))+
	xlab("Time")+
	scale_y_log10(breaks=c(0.1, 1, 10, 100), lim=c(0.003, NA))+
	scale_x_continuous(breaks=seq(1995, 2017, 5), minor_breaks=seq(1995, 2016, 1), lim=c(1995, 2017) )+
	geom_point(data=tidy_obs, aes(x=Time, y=rabbit.count/(trans.length/1000)), cex=0.8) +
	geom_vline(data=rip_dat, aes(xintercept=Time), col="black", lwd=1.5)+
	facet_wrap(~Sitename, ncol=3, nrow=7)+
	theme_bw()+
	theme(strip.background = element_blank(), 
		 strip.text.x=element_text(hjust=0.05),
		 panel.border = element_rect(colour = "black"),
		 panel.grid.major=element_line(colour="grey50", size=0.15),
		 panel.grid.minor=element_line(colour="grey80", size=0.05))

rabbit_pdf<-gsub("fox", "rabbit", out_pdf)
rabbit_png<-gsub("fox", "rabbit", out_png)

ggsave(rabbit_pdf, width=7, height=9)
ggsave(rabbit_png, width=7, height=9, dpi=300)