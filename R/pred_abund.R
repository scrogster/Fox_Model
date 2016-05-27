## ----pred_process2,  cache=FALSE, echo=FALSE, message=FALSE, dependson="heir_model"----
#pred 
require(ggmcmc)
require(dplyr)
require(rjags)

load("model_results.Rdata")

preds<-ggs(predsamp)
aa<-group_by(preds, Parameter)
pred_summary<-summarise(aa, post.mean = mean(value), 
				    post.med = median(value),
				    lwr =quantile(value, 0.025), 
				    upp=quantile(value, 0.975))
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
preddf$time.orig<-1998 +(preddf$Time-1)/2
#tabulation of site codes and names, adding site names to the dataframe for plot labelling
labelling_tab<-data.frame(
	"Site"=unique(obs_data$site))
row.names(labelling_tab)<-as.numeric(unique(obs_data$site))
preddf$Sitename<-labelling_tab$Site[preddf$Site]

## ----tidy_obs_data, cache=FALSE, echo=FALSE, message=FALSE---------------
tidy_obs<-data.frame(
	"fox.count"=obs_data$foxes.counted,
	"rabbit.count"=obs_data$rabbits.counted,
	"trans.length"=obs_data$trans.length,
	"Site"=as.numeric(obs_data$site),
	"Sitename"=obs_data$site,
	"Time"=disctime_shifted,
	"time.orig"=1998 +(disctime_shifted-1)/2
) 

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
	geom_ribbon(aes(ymin=lwr,ymax=upp, colour=NULL),alpha=0.65, fill="darkorange3")+
	ylab(expression(paste("Foxes k",m^{-1})))+
	xlab("Time")+
	xlim(1995, 2015)+
	geom_point(data=tidy_obs, aes(x=time.orig, y=fox.count/(trans.length/1000)), cex=1) +
	facet_wrap(~Sitename,  ncol=3, nrow=7, scales="free_y") +
	theme_classic() #classic 

ggsave("Figures/fox_abund.pdf", width=7, height=10)
ggsave("Figures/fox_abund.png", width=7, height=10, dpi=300)

## ----rabbit_pred_graph, cache=FALSE, echo=FALSE, message=FALSE, fig.height=9.5, fig.width=7.5, fig.cap='Predicted (line) and observed (points) relative abundances (spotlight counts per transect km) of rabbits at each of the 21 study sites over the course of the study. Solid line is the posterior median, and shaded polygons are the 95\\% credible intervals of the mean expected abundances.', fig.pos="p!"----
#plotting estimated trajectories of all rabbit populations.
require(dplyr)
preddf %>%
	filter(Param=="mu.rabbits") %>%
	ggplot(aes(x=time.orig, y=post.med))+
	geom_line(colour="black")+
	geom_ribbon(aes(ymin=lwr,ymax=upp, colour=NULL),alpha=0.65, fill="slategray3")+
	ylab(expression(paste("Rabbits k",m^{-1})))+
	xlab("Time")+
	xlim(1995, 2015)+
	geom_point(data=tidy_obs, aes(x=time.orig, y=rabbit.count/(trans.length/1000)), cex=1) +
	facet_wrap(~Sitename, ncol=3, nrow=7, scales="free_y")+
	theme_classic() #classic

ggsave("Figures/rabbit_abund.pdf", width=7, height=10)
ggsave("Figures/rabbit_abund.png", width=7, height=10, dpi=300)