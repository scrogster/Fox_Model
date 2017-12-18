require(jagsUI)
require(ggplot2)
require(gridExtra)

load("fitted_rain_model.Rdata")

#tabulate discrepancies
discreps<-data.frame(
fox.real=samp$sims.list$fit.fox,
fox.fake=samp$sims.list$fit.fox.fake,
fox.fake.zeroes=samp$sims.list$fox.fake.zeroes,
rabbit.real=samp$sims.list$fit.rabbit,
rabbit.fake=samp$sims.list$fit.rabbit.fake,
rabbit.fake.zeroes=samp$sims.list$rabbit.fake.zeroes)

#Bayesian p-values of chi-sq discrepancy
p_val_fox<-mean(discreps$fox.real>discreps$fox.fake)
p_val_rabbit<-mean(discreps$rabbit.real>discreps$rabbit.fake)


min_fox<-min(discreps[,1:2])-10
max_fox<-max(discreps[,1:2])+10
min_rab<-min(discreps[,4:5])-10
max_rab<-max(discreps[,4:5])+10

#FOX PP check
foxpp<-ggplot(discreps, aes(x=fox.real, y=fox.fake)) +
	geom_point(alpha=0.5, size=0.4, colour="darkorange3", fill="darkorange3")+
	geom_abline(slope=1, intercept=0)+
	xlab(expression(paste(chi[obs]^2)))+
	ylab(expression(paste(chi[rep]^2)))+
	annotate("text", -Inf, Inf, label=paste("p =", format(p_val_fox, digits=4)), hjust=-0.15, vjust=1.3)+
	xlim(min_fox, max_fox)+
	ylim(min_fox, max_fox)+
	ggtitle("Fox")+
     theme_bw()+
	theme(plot.title = element_text(hjust = 0.5), 
		 axis.title.x=element_text(face="italic"),
		 axis.title.y=element_text(face="italic"))




#Fox excess zero check
foxzerocheck<-ggplot(discreps, aes(x=fox.fake.zeroes))+
	geom_histogram(fill="darkorange", colour=NA, alpha=0.8, bins=20)+
	geom_vline(xintercept=sum(hier_dat$fox.count==0))+
	geom_vline(xintercept=quantile(discreps$fox.fake.zeroes, c(0.025, 0.975)), linetype="dashed")+
	xlab("Number of zeroes")+
	ggtitle("Fox")+
	theme_bw()+
	theme(plot.title = element_text(hjust = 0.5))



#RABBIT PP check
rabbitpp<-ggplot(discreps, aes(x=rabbit.real, y=rabbit.fake)) +
     geom_point(alpha=0.5, size=0.4, colour="blue", fill="blue")+
	geom_abline(slope=1, intercept=0)+
	xlab(expression(paste(chi[obs]^2)))+
	ylab(expression(paste(chi[rep]^2)))+
	annotate("text", -Inf, Inf, label=paste("p =", format(p_val_rabbit, digits=4)), hjust=-0.15, vjust=1.3)+
	xlim(min_rab, max_rab)+
	ylim(min_rab, max_rab)+
	ggtitle("Rabbit")+
     theme_bw()+
	theme(plot.title = element_text(hjust = 0.5), 
		 axis.title.x=element_text(face="italic"),
		 axis.title.y=element_text(face="italic"))

#Rabbit excess zero check
rabzerocheck<-ggplot(discreps, aes(x=rabbit.fake.zeroes))+
	geom_histogram(fill="blue", colour=NA, alpha=0.8, bins=20)+
	geom_vline(xintercept=sum(hier_dat$rabbit.count==0))+
	geom_vline(xintercept=quantile(discreps$rabbit.fake.zeroes, c(0.025, 0.975)), linetype="dashed")+
	xlab("Number of zeroes")+
	ggtitle("Rabbit")+
	theme_bw()+
	theme(plot.title = element_text(hjust = 0.5))


pdf("Figures/PPcheck.pdf", width=8, height=8)
grid.arrange(foxpp, foxzerocheck, rabbitpp, rabzerocheck, ncol=2, nrow=2)
dev.off()

png("Figures/PPcheck.png", width=8, height=8, units="in", res=300)
grid.arrange(foxpp, foxzerocheck, rabbitpp, rabzerocheck, ncol=2, nrow=2)
dev.off()
