
library(lubridate)
library(dplyr)
library(readr)
library(tidyr)
library(stringr)



## Import and tidy the rainfall data for the sites, including imputing missing data for Pentland Hills site
rain_summary<-read_csv("Data/TabulatedRainHalfYearly_updated.csv") %>%
	rename(Site=X1) %>%
	filter(Site != "Avalon" & Site != "Sunbury") 
#add in rainfall for Pentland Hills (using data from nearby Ingliston Site)
pentland_rain<-rain_summary[rain_summary$Site=="Ingliston",]
pentland_rain$Site<-"Pentland Hills"
new_rain<-rbind(rain_summary[1:12,], pentland_rain, rain_summary[13:20,])

rain_summary<-new_rain
rm(new_rain)
rm(pentland_rain)

# tidy the raindat
tidy_rain<-rain_summary %>%
	gather(timestep, rain, 2:43) %>%
	arrange(Site) %>%
	separate(timestep, into=c("Year", "Step"), sep="--") %>%
	mutate(ytime_disc=as.numeric(Year) + as.numeric(Step)*0.5)


#this block of code adds a variable to denote each unique session for computing averages etc.
func<-function(x){
	incr=0
	out<-numeric(length(x))
	for(i in 1: length(x)){
		if(x[i]==1) {incr=incr+1}
		out[i]=incr 
	}
	return(out)
}
##Import and tidy the spotlight data.
spotlight<-read_csv("Data/spotlight_data.csv") %>%
	rename(Site=`Monitor.Site`, Date=`Spotlight.Date`) %>%
	filter(Site != "Pyramid Hill") %>%
	arrange(Site, Date)  %>%
	mutate(first=(Replicate_Count==1)) %>%
	mutate(session= func(first))


#calculate a mid-point date for each session of replicate counts and append to the dataframe
spotlight<-spotlight %>%
	group_by(session) %>%
	mutate(SessDate=mean(Date)) %>%
	mutate(ytime=decimal_date(SessDate) ) %>%
	mutate(ytime_disc=floor(ytime/0.5)*0.5) %>%  #this discretizes the dates.
	mutate(time_idx=1+(ytime_disc-1998)*2  ) %>% #this is a six-monthly time index for use in the models starts at first half of 1998
	mutate(site_code=as.numeric(factor(Site))) %>% #these are numeric site indices
	mutate(winter =  (ytime_disc %% 1) *2 )    #these are flags for second half of year (implies post-winter census)

#need to add in a winter variable to code for counts made after the winter interval (second half of year)                                                

start_times = spotlight %>% group_by(Site) %>% summarise(start_times=min(time_idx))

end_times = spotlight %>% group_by(Site) %>% summarise(end_times=max(time_idx))

rain_mat<-as.matrix( (rain_summary[,-1]-250)/100)  #rain data roughly centred by subtracting 250, and scaled by dividing by 100. 

#tidy this up with new variables, and all good.
hier_dat<-list(
	site.code=as.numeric(factor(spotlight$Site)),
	fox.count=spotlight$Foxes,
	rabbit.count=spotlight$Rabbits,
	trans.length=spotlight$TransectLength,
	obs_time=spotlight$time_idx,
	start=start_times$start_times,
	end=  end_times$end_times,
	sites=max(as.numeric(factor(spotlight$Site))),
	Nobs=nrow(spotlight),
	winter=spotlight$winter,
	postrip=spotlight$PostRipped,
	rain= rain_mat, 
	rain.offset=4   #value of 4= six-month lag, 3=1 year lag, #can smooth later.
)

save.image("prepped_data.Rdata")
