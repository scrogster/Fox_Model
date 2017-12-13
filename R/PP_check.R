require(jagsUI)
require(ggplot2)
require(gridExtra)

load("fitted_rain_model.Rdata")

#tabulate discrepancies
discreps<-data.frame(
fox.real=samp$sims.list$fit.fox,
fox.fake=samp$sims.list$fit.fox.fake,
rabbit.real=samp$sims.list$fit.rabbit,
rabbit.fake=samp$sims.list$fit.rabbit.fake)

#Bayesian p-values
p_val_fox<-mean(discreps$fox.real>discreps$fox.fake)
p_val_rabbit<-mean(discreps$rabbit.real>discreps$rabbit.fake)

min_fox<-min(discreps[,1:2])-10
max_fox<-max(discreps[,1:2])+10
min_rab<-min(discreps[,3:4])-10
max_rab<-max(discreps[,3:4])+10

#FOX PP check
foxpp<-ggplot(discreps, aes(x=fox.real, y=fox.fake)) +
	geom_point(alpha=0.3, size=0.4)+
	geom_abline(slope=1, intercept=0)+
	xlab(expression(paste(chi[real]^2)))+
	ylab(expression(paste(chi[rep]^2)))+
	annotate("text", -Inf, Inf, label=paste("p =", format(p_val_fox, digits=3)), hjust=-0.15, vjust=1.3)+
	xlim(min_fox, max_fox)+
	ylim(min_fox, max_fox)+
	ggtitle("Fox")+
     theme_bw()+
	theme(plot.title = element_text(hjust = 0.5))

#RABBIT PP check
rabbitpp<-ggplot(discreps, aes(x=rabbit.real, y=rabbit.fake)) +
     geom_point(alpha=0.3, size=0.4)+
	geom_abline(slope=1, intercept=0)+
	xlab(expression(paste(chi[real]^2)))+
	ylab(expression(paste(chi[rep]^2)))+
	annotate("text", -Inf, Inf, label=paste("p =", format(p_val_rabbit, digits=3)), hjust=-0.15, vjust=1.3)+
	xlim(min_rab, max_rab)+
	ylim(min_rab, max_rab)+
	ggtitle("Rabbit")+
     theme_bw()+
	theme(plot.title = element_text(hjust = 0.5))

pdf("Figures/PPcheck.pdf", width=4, height=8)
grid.arrange(foxpp, rabbitpp, ncol=1, nrow=2)
dev.off()

png("Figures/PPcheck.png", width=4, height=8, units="in", res=300)
grid.arrange(foxpp, rabbitpp, ncol=1, nrow=2)
dev.off()
