require(ggplot2)

load("model_results.Rdata")

mean_rain<-(mean(stack(rain_dat)[,1])-250)/100
low_rain<-(quantile(stack(rain_dat)[,1], 0.1)-250)/100
high_rain<-(quantile(stack(rain_dat)[,1], 0.9)-250)/100

#posterior means
post.means<-colMeans(as.matrix(samp))
#parameter estimates

#function to predict r for foxes from rabbit, fox abund, rain and season.
predFOX_r<-function(R, F, rr, ww){
	r.fox<- (log(R)* post.means["beta[1]"])+ #numerical response
		(log(F)* post.means["beta[2]"])+ #dense depend.
		(rr    * post.means["beta[3]"])+ #rain effect of r.
		(ww*post.means["beta[4]"]) +  #effect of winter on r
		(post.means["r.mean"])  # grand mean of site.r.eff[k]  
	return(r.fox)
}

#test cases
#print(predFOX_r(R=1, F=0.1, rr=mean_rain, ww=0) )
#print(predFOX_r(R=1, F=5, rr=mean_rain, ww=0) )

#print(predFOX_r(R=50, F=0.1, rr=mean_rain, ww=0) )
#print(predFOX_r(R=50, F=5, rr=mean_rain, ww=0) )


rab_levels<-seq(0.01, 30, by=0.1)
fox_levels<-seq(0.01, 1, by=0.01)
rain_levels<-c(low_rain, mean_rain, high_rain)
winter_levels=c(0, 1)

#vectorise predictions using apply
preddf<-expand.grid(rab_levels, fox_levels, rain_levels, winter_levels)
names(preddf)<-c("Rabbits", "Foxes", "Rainfall", "Winter")
pred.r<-apply(preddf, 1, 
		    function(x) {predFOX_r(R=x[1], F=x[2], rr=x[3], ww=x[4])})
preddf<-data.frame(preddf, "r"=pred.r)

preddf$Rain[preddf$Rainfall==low_rain] <- "Low"
preddf$Rain[preddf$Rainfall==mean_rain] <- "Mean"
preddf$Rain[preddf$Rainfall==high_rain] <- "High"

preddf$Rain <- factor(preddf$Rain, levels = c("Low", "Mean", "High"))

preddf$Rainfall<-preddf$Rain


preddf$Season[preddf$Winter==1] <-"Winter"
preddf$Season[preddf$Winter==0] <-"Summer"

b <- c(-1.5,-1,-0.5, 0, 0.5, 1, 1.5)
ggplot(preddf, aes(x=Foxes, y=Rabbits, fill=r, z=r))+
	facet_grid(Rainfall ~ Season, labeller="label_both") +
	geom_raster(interpolate = TRUE) +
	stat_contour(breaks=c(0), lty=2)+  #contour where r=0
	scale_fill_gradientn(limits = c(-1.7,1.7),
					 colours=c("firebrick","red", "orange", "yellow2",
					 		"white", 
					 		"green", "limegreen", "chartreuse4", "darkgreen"),
					 breaks=b,labels=format(b))+
	labs(x = expression(paste("Foxes km",phantom(0)^{-1})), 
		y = expression(paste("Rabbits km",phantom(0)^{-1}))) +
	theme_classic() +
	theme(axis.text.x=element_text(angle=90, vjust=0.5, hjust=0)) +
	theme(legend.title.align=0.5, legend.title=element_text(face="italic"))
	

ggsave("Figures/predicted_fox_r.pdf")
ggsave("Figures/predicted_fox_r.png", dpi=300)