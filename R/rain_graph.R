library(dplyr)
library(ggplot2)

load("model_results.Rdata")

rain_dat2<-rain_dat

rain_dat2<-data.frame("SiteName"=row.names(rain_dat2), rain_dat2)
row.names(rain_dat2)<-1:21

library(tidyr)
library(dplyr)
library(ggplot2)

rain_dat2<-tbl_df(rain_dat2)

#re-arrange and tidy the data
rain_tidy<-rain_dat2 %>% 
	gather("TimeCode", "Rainfall", starts_with("X")) %>%
	separate("TimeCode", into=c("Rubbish", "Year", "Semester"), sep=c(1, 5)) %>%
	select(-Rubbish) %>%
	mutate(Year=as.numeric(Year)) %>%
	mutate(Semester=as.numeric(substr(Semester, 3, 3))) %>%
	mutate(Time= Year + Semester*0.5)

ggplot(rain_tidy, aes(x=Time, y=Rainfall))+
	geom_line(col="blue")+
	facet_wrap(~SiteName, ncol=3, nrow=7)+
	xlim(1995, 2015)+
	theme_classic()
ggsave("Figures/rain_graph.pdf")
ggsave("Figures/rain_graph.png")