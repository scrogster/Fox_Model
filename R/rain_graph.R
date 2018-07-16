
library(lubridate)
library(dplyr)
library(readr)
library(tidyr)
library(stringr)
library(ggplot2)
library(zoo)
dir.create("Figures", showWarnings = FALSE)

args=commandArgs(trailingOnly=TRUE)

model_data=args[1]
file_loc=args[2]

out_pdf=file.path(file_loc)
out_png=gsub("pdf", "png", out_pdf)

#read and tidy the rain data
allrain<-read_csv("Data/AllRain.csv") %>%
	select(-X1 , -Spring) %>%
	filter(Site != "Avalon" & Site != "Sunbury")

allrain_pentland<-allrain %>%
	filter(Site=="Ingliston") %>%
	mutate(Site=replace(Site, Site=="Ingliston", "Pentland Hills"))
allrain<-rbind(allrain, allrain_pentland)
rm(allrain_pentland)
allrain<-distinct(allrain) %>% #drop duplicate rows!!!
	mutate(Deemed_date=ymd(paste(Year, Month, 15))) %>%
	mutate(Site=replace(Site, Site=="BlackRange", "Black Range")) %>%
	mutate(Site=replace(Site, Site=="SwiftsCreek", "Swifts Creek")) %>%
	mutate(Site=replace(Site, Site=="Yarram/Woodside", "Yarram")) %>%
	group_by(Site) %>%
	mutate(meanrain=mean(Rain)) %>%
	mutate(roll_mean6 = rollmean(Rain, 6, fill=NA, align="right"), roll_mean12 = rollmean(Rain, 12, fill=NA, align="right")) %>%
	ungroup() %>%
	mutate(Site=factor(Site)) %>%
	mutate(Site =forcats::fct_reorder(Site, meanrain, fun=mean))

ggplot(allrain, aes(y=Rain, x=Deemed_date))+
	#geom_rect(aes(xmin=ymd("2001-01-01"), xmax=ymd("2009-12-30"), ymin=0, ymax=Inf), col=NA, fill="gray",alpha=0.4)+
	annotate("rect", xmin=ymd("2001-01-01"), xmax=ymd("2009-12-30"), ymin=0, ymax=Inf, fill="gray",alpha=0.6)+
	geom_line(colour="blue", lwd=0.2)+
	geom_line(aes(y=roll_mean12), lwd=0.4, col="red")+
	geom_hline(aes(yintercept=meanrain), col="black", alpha=0.9, lwd=0.5) +
	facet_wrap(~Site, nrow=7, ncol=3) +
	xlab("Date")+
	ylab("Monthly rainfall (mm)")+
	theme_bw()+
      theme(strip.background = element_blank(), 
	 strip.text.x=element_text(hjust=0.05),
	 panel.border = element_rect(colour = "black"),
	 panel.grid.major=element_line(colour="grey50", size=0.15),
	 panel.grid.minor=element_line(colour="grey80", size=0.05))

ggsave(out_pdf, width=6, height=7.5)
ggsave(out_png, width=6, height=7.5)
