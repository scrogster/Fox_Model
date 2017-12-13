require(ggplot2)

args=commandArgs(trailingOnly=TRUE)

model_data=args[1]
out_pdf=file.path(args[2])
out_png=gsub("pdf", "png", out_pdf)

load(file.path(model_data))

mean_rain=25/10  #30 mm a month
low_rain=10/10   #10 mm a month
high_rain=50/10  #50 mm a month

#posterior means of the betas
post.means.beta<-colMeans(samp$sims.list$beta)
post.means.intercept<-mean(samp$sims.list$r.mean)

#function to predict r for foxes from rabbit, fox abund, rain and season.
predFOX_r<-function(R, F, rr, ww){
	r.fox<- (log(R)* post.means.beta[1])+ #numerical response
		(log(F)* post.means.beta[2])+ #dense depend.
		(rr    * post.means.beta[3])+ #rain effect of r.
		(ww*post.means.beta[4]) +  #effect of winter on r
		(post.means.intercept)  # grand mean of site.r.eff[k]  
	return(r.fox)
}

#test cases
#print(predFOX_r(R=1, F=0.1, rr=mean_rain, ww=0) )
#print(predFOX_r(R=1, F=5, rr=mean_rain, ww=0) )

#print(predFOX_r(R=50, F=0.1, rr=mean_rain, ww=0) )
#print(predFOX_r(R=50, F=5, rr=mean_rain, ww=0) )


rab_levels<-seq(0.01, 20, length.out=100)
fox_levels<-seq(0.01, 0.5, length.out=100)
rain_levels<-c(low_rain, mean_rain, high_rain)
winter_levels=c(0, 1)

#vectorise predictions using apply
preddf<-expand.grid(rab_levels, fox_levels, rain_levels, winter_levels)
names(preddf)<-c("Rabbits", "Foxes", "Rainfall", "Winter")
pred.r<-apply(preddf, 1, 
		    function(x) {predFOX_r(R=x[1], F=x[2], rr=x[3], ww=x[4])})
preddf<-data.frame(preddf, "r"=pred.r)

preddf$Rain[preddf$Rainfall==low_rain] <- "10 mm"
preddf$Rain[preddf$Rainfall==mean_rain] <- "25 mm"
preddf$Rain[preddf$Rainfall==high_rain] <- "50 mm"

preddf$Rain <- factor(preddf$Rain, levels = c("10 mm", "25 mm", "50 mm"))

preddf$Rainfall<-preddf$Rain


preddf$Season[preddf$Winter==1] <-"Winter"
preddf$Season[preddf$Winter==0] <-"Summer"

b <- c(-1.5,-1,-0.5, 0, 0.5, 1, 1.5)
ggplot(preddf, aes(x=Foxes, y=Rabbits, fill=r, z=r))+
	facet_grid(Rainfall ~ Season, labeller="label_both") +
	geom_raster(interpolate = TRUE) +
	stat_contour(breaks=c(0), lty=1, colour="black")+  #contour where r=0
	scale_fill_gradient2(low="firebrick", mid="white", high="royalblue3")+
	guides(fill = guide_colorbar(draw.ulim = FALSE,draw.llim = FALSE, tick=FALSE))+
	labs(x = expression(paste("Foxes km",phantom(0)^{-1})), 
		y = expression(paste("Rabbits km",phantom(0)^{-1}))) +
	theme_bw()+
	theme(strip.background = element_blank(), 
		 strip.text.x=element_text(hjust=0.1),
		 panel.border = element_rect(colour = "black"),
           axis.text.x=element_text(angle=0, vjust=0.5, hjust=0)) +
	theme(legend.title.align=0.25, legend.title=element_text(face="italic"))

ggsave(out_pdf)
ggsave(out_png, dpi=300)