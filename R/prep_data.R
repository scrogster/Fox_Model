
library(lubridate)
library(dplyr)
library(readr)
library(tidyr)
library(stringr)

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
     mutate(Site=replace(Site, Site=="Yarram/Woodside", "Yarram")) 

func<-function(x){
	incr=0
	out<-numeric(length(x))
	for(i in 1: length(x)){
		if(x[i]==1) {incr=incr+1}
		out[i]=incr
	}
	return(out)
}
#tidying and discretizing the spotlight data
spotlight<-read_csv("Data/spotlight_data.csv") %>%
	rename(Site=`Monitor.Site`, Date=`Spotlight.Date`) %>%
	filter(Site != "Pyramid Hill") %>%
	arrange(Site, Date)  %>%
	mutate(first=(Replicate_Count==1)) %>%
	mutate(session= func(first)) %>%
	group_by(session) %>%
	mutate(SessDate=mean(Date)) %>%   #within a session the deemed date of the survey is the mean date
	ungroup() %>%
	mutate(Semester=semester(SessDate), Year=year(SessDate)) %>%   #which year and semester were each session in
	mutate(ytime_disc = Year + (Semester-1)/2) %>%    #making times discrete
	mutate(time_idx = 5+(ytime_disc-1998)*2) %>%     #integer flags for successive semesters  #first surveys at time 3
	mutate(site_code=as.numeric(factor(Site))) %>% #these are numeric site indices
	mutate(winter =  (ytime_disc %% 1) *2 )  %>%
	mutate(Site=replace(Site, Site=="Yarram/Woodside", "Yarram"))   #these are flags for second half of year (implies post-winter census)

#need to add in a winter variable to code for counts made after the winter interval (second half of year)                                                

start_times = spotlight %>% group_by(Site) %>% summarise(start_times=min(time_idx), start_dates=min(SessDate))

end_times = spotlight %>% group_by(Site) %>% summarise(end_times=max(time_idx), end_dates=max(SessDate))

#key for matching time_idx with Year/Semester designation...
time.key<-data.frame("time_idx"=seq(1:42), "Year"=rep(1996:2016, each=2), "Semester"=c(1:2))

#dates of site ripping
ripdate<-read_csv("Data/ripping_data.csv")

riptime<-ripdate %>% 
	mutate(Year=year(RippedDate)) %>%
	mutate(Semester=semester(RippedDate)) %>%
	left_join(time.key) %>%
	mutate(time_idx=ifelse(is.na(time_idx), 500, time_idx)) %>% #makes unripped sites ostensibly ripped at time=500.
	pull(time_idx)


###############################################################################
#   MAKING LAGGED RAINFALL ARRAYS..
###############################################################################

preds<-expand.grid(time_idx=1:42,  Site=levels(factor(spotlight$Site)), lag=1:30) %>%
	left_join(time.key, by="time_idx") %>% 
	select(time_idx, Site, Year, Semester, lag) %>%
	mutate(Site=as.character(Site))

#This function grabs months rainfall by site, year, semester and lag.
get_rain<-function(Sitename="Ararat", Year=1998, Sem=1, lag=0){
	if(Sem==1){month=4} else {month=11} #we'll assume April and November surveys
	DD<-ymd(paste(Year, month, 15)) %m-% months(as.numeric(lag))
	outrain<-allrain %>%
		filter(Site==Sitename, Deemed_date==DD) %>%
		head(1)
	outval<-outrain
	if(length(outval$Rain==1))  {return(outval$Rain)} else {return(NA)}
}

get_rain2<-function(x){
	out<-get_rain(Sitename = x[,"Site"], Year=x[,"Year"], Sem=x[,"Semester"], lag=x[,"lag"])
	return(out)
}

rainpred<-numeric(nrow(preds))
for(i in 1:nrow(preds)){
rainpred[i]<-get_rain2(preds[i,])
}; rm(i)

#append rain vector to pred dataframe
preds<-data.frame(preds, "rain"=rainpred)

#this makes the array with dimensions (Site, time_idx and lag)
rain_lag_array<-tapply(preds$rain, preds[,c(2, 1,5)], min, na.rm=FALSE)

rain_array2<-rain_lag_array  #this will be a version with cumulative means over increasing lags

dim(rain_array2)
#sweep out cumulative means along increasing lags...
for(i in 1:21){  #sites
	for(j in 1:42){  #times
	 for(k in 1:30){ #lags
	 	rain_array2[i,j,k]<-mean(rain_lag_array[i,j,1:k], na.rm=TRUE)	
	 }	
	}
}; rm(i); rm(j);  rm(k)

###############################################################################
#   MAKNG DATA OBJECT (LIST) FOR MODELLING IN JAGS
###############################################################################
#tidy this up with new variables, and all good.
hier_dat<-list(
	site.code=as.numeric(factor(spotlight$Site)),
	fox.count=spotlight$Foxes,
	rabbit.count=spotlight$Rabbits,
	trans.length=spotlight$TransectLength,
	obs_time=spotlight$time_idx,
	sites=max(as.numeric(factor(spotlight$Site))),
	Nobs=nrow(spotlight),
	winter=rep(c(0, 1), 21),
	riptime=riptime,
     rain_array = rain_array2  #site by time by lag array
)

save.image("prepped_data.Rdata")
