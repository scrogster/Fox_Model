library(dplyr)
library(ggplot2)
library(tidyr)

args=commandArgs(trailingOnly=TRUE)

model_data=args[1]
out_pdf=file.path(args[2])
out_png=gsub("pdf", "png", out_pdf)

load(file.path(model_data))

rain_dat2<-rain_summary

#rain_dat2<-data.frame("SiteName"=row.names(rain_dat2), rain_dat2)
#row.names(rain_dat2)<-1:21

rain_dat2<-tbl_df(rain_dat2)

#Manual editing and overwrite of a few site names
NewSiteNames<-as.character(rain_dat2$Site)
NewSiteNames[NewSiteNames=="BlackRange"]<-"Black Range"
NewSiteNames[NewSiteNames=="SpringHill"]<-"Spring Hill"
NewSiteNames[NewSiteNames=="SwiftsCreek"]<-"Swifts Creek"
NewSiteNames[NewSiteNames=="TelopeaDowns"]<-"Telopea Downs"

rain_dat2$Site<-NewSiteNames

#re-arrange and tidy the data
rain_tidy<-rain_dat2 %>% 
	gather("TimeCode", "Rainfall", 2:43) %>%
	separate("TimeCode", into=c("Year", "Semester"), sep="--") %>%
	mutate(Time= as.numeric(Year) + as.numeric(Semester)*0.5)

#plot time series of half-yearly rainfall for each site.
ggplot(rain_tidy, aes(x=Time, y=Rainfall))+
	geom_line(col="blue")+
	facet_wrap(~Site, ncol=3, nrow=7)+
	xlim(1995, 2016)+
	ylab("Rainfall (mm)")+
	theme_classic()
ggsave(out_pdf)
ggsave(out_png)
