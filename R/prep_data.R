## ----setup, cache=TRUE, echo=FALSE, message=FALSE, tidy=TRUE-------------
#library(gdata)
library(gdata)
library(lubridate)
library(reshape2)
library(plyr)

## ----read_data, echo=FALSE, warning=FALSE, message=FALSE, cache=TRUE, tidy=TRUE----
#spotlight<-read.xls("Data/kasey.xls", 2)

spotlight<-read.csv("Data/spotlight_data.csv")


#convert date data to date format using lubridate facilities
spotlight$Spotlight.Date<-ymd(as.character(spotlight$Spotlight.Date))

#SOI data from BOM. Convert to long-format. Lubridate, and ddply to summarise by half-year.
SOI<-read.table("Data/SOI.txt", skip=6, header=TRUE)
SOI_long<-melt(SOI, id.vars='Year', variable.name="Month", value.name="SOI")

soi<-data.frame("Date"=ymd(paste(SOI_long$Year, SOI_long$Month, 15, sep="-")), "SOI"=SOI_long$SOI)
soi<-soi[order(soi$Date),]
soi$SOI<-as.numeric(as.character(soi$SOI))

soi$sechalf<-as.numeric(month(soi$Date)>7) #observations in second half of cal year will score "1", o'wise "0"
soi$year<-year(soi$Date)
#ddply to the rescue
SOI_summary<-ddply(soi, ~year+sechalf, function(x){mean(x$SOI, na.rm=TRUE)})

## ----import_rain_summary, echo=FALSE, warning=FALSE, message=FALSE, cache=TRUE, tidy=TRUE----
rain_summary<-read.csv("Data/TabulatedRainHalfYearly_updated.csv")
#str(rain_summary)

#tidy up (delete unwanted sites, duplicate Ingliston to substitute for pentland hills)
aa<-rain_summary[rain_summary$X!=c("Avalon") & rain_summary$X!=c("Sunbury"),]
pentland_rain<-aa[aa$X=="Ingliston",]
pentland_rain$X<-"Pentland Hills"

new_rain<-rbind(aa[1:12,], pentland_rain, aa[13:20,])
names(new_rain)[1]<-"Site"

#rain_matrix<-data.frame(new_rain[,-1])

rain_dat<-data.frame(new_rain[,-1])
row.names(rain_dat)<-new_rain$Site
rm(aa)
rm(new_rain)

##rain_dat is the final summary.

## ----session_midpoints, echo=FALSE, message=FALSE, cache=TRUE, tidy=TRUE----
#for each site, step through survey dates. Where replicate count increases, store the results. Average the dates and 
#store in new variable. These are effective mid-points for each "closed session"
make.session.dates<-function(sitename="Yambuk"){
	sitedata<-subset(spotlight, Monitor.Site==sitename)
	rep.count<-sitedata$Replicate_Count
	starts<-which(rep.count==1)
	ends<-c(starts[-1]-1, nrow(sitedata))
	store<-sitedata$Spotlight.Date
	for(i in 1:length(starts)){
		dates<-sitedata$Spotlight.Date[starts[i]:ends[i]]
		mid.date<-min(dates) +((max(dates)-min(dates))/2)
		store[starts[i]:ends[i]]<-mid.date
	}
	return(store)
}

sess.dates.list<-sapply(unique(spotlight$Monitor.Site), make.session.dates)
sess.dates<-do.call(c, sess.dates.list)
spotlight<-data.frame(spotlight, sess.dates)

## ----obs_data_list, cache=TRUE, echo=FALSE, tidy=TRUE--------------------
#idea here is to make a list of data required by JAGS for analysis, and store it in a data.frame/list
#for further processing.
obs_data<-data.frame(
	"site"=spotlight$Monitor.Site,
	"year"=year(spotlight$sess.dates),
	"month"=month(spotlight$sess.dates),
	#this variable is the calender year, plus the monthly fraction.
	"ytime"=year(spotlight$sess.dates)+(month(spotlight$sess.dates)/12),
	"breeding"=as.numeric(month(spotlight$sess.dates)>6),
	"foxes.counted"=spotlight$Foxes,
	"rabbits.counted"=spotlight$Rabbits,
	"trans.length"=spotlight$TransectLength,
	"rep_count"=spotlight$Replicate_Count
)

## ----discretize, cache=TRUE, echo=FALSE, tidy=TRUE-----------------------
#idea here is to discretize dates into half-year intervals. E.g., if time is 2001.4534 years,
#then disc.time =2001, if time is 2001.676, then disc.time=2001.5
disc.time<-floor(obs_data$ytime) +    #takes whole part of year
	((obs_data$ytime-floor(obs_data$ytime))>0.5)*0.5 #adds 0.5 if remainder is >0.5

obs_data<-data.frame(obs_data, disc.time)

#all potential times that 
time.levels<-seq(min(disc.time), max(disc.time), by=0.5)

mod_data<-data.frame(
	site.code=as.numeric(obs_data$site),
	rabbits=obs_data$rabbits.counted,
	foxes=obs_data$foxes.counted,
	trans.length=obs_data$trans.length,
	disctime=obs_data$disc.time-1998
)
#starting times for each site...
#tapply(mod_data$disctime, mod_data$site.code, min)
#ending times for each site...
#tapply(mod_data$disctime, mod_data$site.code, max)

## ----disc_time_data, echo=FALSE, cache=TRUE, tidy=TRUE-------------------
disctime_shifted=1+(obs_data$disc.time-1998)*2 
hier_dat<-list(
	site.code=as.numeric(obs_data$site),
	#  rabbits=obs_data$rabbits.counted,
	fox.count=obs_data$foxes.counted,
	rabbit.count=obs_data$rabbits.counted,
	trans.length=obs_data$trans.length,
	#makes first ever time 1, then adds 1 for each sixmonth inter.
	obs_time=disctime_shifted,
	start=tapply(disctime_shifted, mod_data$site.code, min),
	end=tapply(disctime_shifted, mod_data$site.code, max),
	sites=max(as.numeric(obs_data$site)),
	Nobs=length(obs_data$foxes.counted),
	#first rabbit counts are 1998 (first half). start lagged aggregated SOI from beginning of 1997
	#t-1 = half year lag, t-2 =full year lag.
	# modSOI=subset(SOI_summary, year>=1997)$V1,
	#winter=subset(SOI_summary, year>=1997)$sechalf,
	winter=rep(c(0, 1), 25),
	rain=(rain_dat-250)/100, #rain data now roughly centred by subtracting 250, (roughly the mean), 
	#then divided by 100 to make scales comparable with other covars.
	rain.offset=4   #value of 4= six-month lag, 3=1 year lag, #can smooth later.
)

##This is the code for site summarys. It will go in Supp Material. Probably best inserted as a chunk into the word document.
## ----site_summary_data, eval=TRUE, cache=FALSE, echo=FALSE, results='asis', message=FALSE----
# require(dplyr)
# require(xtable)
# obs_data2<-tbl_df(data.frame("sitename"=spotlight$Monitor.Site, obs_data))
# trans_summary<-obs_data2 %>%
# 	group_by(sitename) %>%
# 	summarise(firstsamp=round(min(year)), lastsamp=round(max(year)), total_surv=length(foxes.counted), years_samped=n_distinct(year), maxlength=max(trans.length)/1000, meanlength=mean(trans.length)/1000)
# 
# names(trans_summary)<-c("Transect", "Established", "Last survey", "Number of Surveys", "Years with survey", "Full length (km)", "Mean length (km)")
# #make the table
# print(
# 	xtable(
# 		trans_summary, caption="Summary statistics for the 21 transects surveyed for abundance of foxes and rabbits.", 
# 		label="transect_summary", 
# 		digits=c(1, 0, 0, 0, 0, 0, 1, 1), align=c("c", "l", "c", "c", "c","c", "c", "c") ), 
# 	include.rownames=FALSE, table.placement="p!", floating.environment="sidewaystable", caption.placement = "top")


save.image("prepped_data.Rdata")
