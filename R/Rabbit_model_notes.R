## ----setup, cache=TRUE, echo=FALSE, message=FALSE, tidy=TRUE-------------
library(gdata)
library(rjags)
library(lubridate)
library(reshape2)
library(plyr)

## ----read_data, echo=FALSE, warning=FALSE, message=FALSE, cache=TRUE, tidy=TRUE----
spotlight<-read.xls("kasey.xls", 2)
#names(spotlight)
#convert date data to date format using lubridate facilities
spotlight$Spotlight.Date<-dmy(as.character(spotlight$Spotlight.Date))

#SOI data from BOM. Convert to long-format. Lubridate, and ddply to summarise by half-year.
SOI<-read.table("SOI.txt", skip=6, header=TRUE)
SOI_long<-melt(SOI, id.vars='Year', variable.name="Month", value.name="SOI")

soi<-data.frame("Date"=ymd(paste(SOI_long$Year, SOI_long$Month, 15, sep="-")), "SOI"=SOI_long$SOI)
soi<-soi[order(soi$Date),]
soi$SOI<-as.numeric(as.character(soi$SOI))

soi$sechalf<-as.numeric(month(soi$Date)>7) #observations in second half of cal year will score "1", o'wise "0"
soi$year<-year(soi$Date)
#ddply to the rescue
SOI_summary<-ddply(soi, ~year+sechalf, function(x){mean(x$SOI, na.rm=TRUE)})

## ----import_rain_summary, echo=FALSE, warning=FALSE, message=FALSE, cache=TRUE, tidy=TRUE----
rain_summary<-read.csv("KaseyRainfall/TabulatedRainHalfYearly.csv")
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
  "foxes.counted"=spotlight$SumOfNumber.of.Foxes,
  "rabbits.counted"=spotlight$SumOfNumber.of.Rabbits,
  "trans.length"=spotlight$SumOfSpotlight.Length..m.,
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
   winter=subset(SOI_summary, year>=1997)$sechalf,
  rain=(rain_dat-250)/100, #rain data now roughly centred by subtracting 250, (roughly the mean), 
  #then divided by 100 to make scales comparable with other covars.
rain.offset=4   #value of 4= six-month lag, 3=1 year lag, #can smooth later.
  )

#starts
#print(tapply(disctime_shifted, mod_data$site.code, min))
#ends
#print(tapply(disctime_shifted, mod_data$site.code, max))


## ----site_summary_data, eval=TRUE, cache=FALSE, echo=FALSE, results='asis', message=FALSE----
require(dplyr)
require(xtable)
obs_data2<-tbl_df(data.frame("sitename"=spotlight$Monitor.Site, obs_data))
trans_summary<-obs_data2 %>%
  group_by(sitename) %>%
  summarise(firstsamp=round(min(year)), lastsamp=round(max(year)), total_surv=length(foxes.counted), years_samped=n_distinct(year), maxlength=max(trans.length)/1000, meanlength=mean(trans.length)/1000)

names(trans_summary)<-c("Transect", "Established", "Last survey", "Number of Surveys", "Years with survey", "Full length (km)", "Mean length (km)")
#make the table
print(
  xtable(
  trans_summary, caption="Summary statistics for the 21 transects surveyed for abundance of foxes and rabbits.", 
  label="transect_summary", 
    digits=c(1, 0, 0, 0, 0, 0, 1, 1), align=c("c", "l", "c", "c", "c","c", "c", "c") ), 
include.rownames=FALSE, table.placement="p!", floating.environment="sidewaystable", caption.placement = "top")

## ----testplot, eval=FALSE, echo=FALSE, message=FALSE---------------------
## #code to test that computed end/start times match up with census times. all looks ok, so not sure why preds are funny.
## test_data<-data.frame(
##   "site.code"=as.numeric(obs_data$site),
##   "Site"=obs_data$site,
##     "fox.count"=obs_data$foxes.counted,
##   "rabbit.count"=obs_data$rabbits.counted,
##   "trans.length"=obs_data$trans.length,
##   "obs_time"=disctime_shifted
##   )
## start_end_data<-data.frame(
##   starter=tapply(disctime_shifted, mod_data$site.code, min),
##   ender=tapply(disctime_shifted, mod_data$site.code, max)
## )
## start_end_data$site.code<-row.names(start_end_data)
## 
## head(start_end_data)
## 
## require(ggplot2)
## ggplot(test_data, aes(x=obs_time, y=fox.count))+
##   geom_point()+
##   geom_vline(aes(xintercept=ender), start_end_data, colour="red")+
##     geom_vline(aes(xintercept=starter), start_end_data, colour="red")+
##   facet_wrap(~site.code)

## ----hier_model, cache=TRUE, echo=FALSE, message=FALSE, tidy=FALSE, results="hide", cache.extra = tools::md5sum('gompertz_heirarch_rain.txt')----
require("rjags")
load.module("glm")
NADAPT=250
NITER=40000
NBURN=40000
THIN=10

start.time<-Sys.time()
hier.mod<-jags.model('gompertz_heirarch_rain.txt', 
                     data=hier_dat, n.chains = 3, n.adapt = NADAPT) 
update(hier.mod, NBURN) #burnin
samp<-coda.samples(hier.mod,
             c('beta', 'sigma', 'r.mean', 'r.mean.rabbits', 
               'site.r.eff.centered', 'site.r.eff.rabbits.centered'), 
               n.iter=NITER, thin=THIN)
dic.heirarch<-dic.samples(hier.mod, 4000)
print(dic.heirarch)

#assembling a big string of abundance predictions
st<-print(tapply(disctime_shifted, mod_data$site.code, min))
fin<-print(tapply(disctime_shifted, mod_data$site.code, max))
predparamstring<-c(paste0("mu.rabbits[",st[1]:fin[1],",1]"),
  paste0("mu.rabbits[",st[2]:fin[2],",2]"),
  paste0("mu.rabbits[",st[3]:fin[3],",3]"),
  paste0("mu.rabbits[",st[4]:fin[4],",4]"),
  paste0("mu.rabbits[",st[5]:fin[5],",5]"),
  paste0("mu.rabbits[",st[6]:fin[6],",6]"),
  paste0("mu.rabbits[",st[7]:fin[7],",7]"),
  paste0("mu.rabbits[",st[8]:fin[8],",8]"),
  paste0("mu.rabbits[",st[9]:fin[9],",9]"),
  paste0("mu.rabbits[",st[10]:fin[10],",10]"),
  paste0("mu.rabbits[",st[11]:fin[11],",11]"),
  paste0("mu.rabbits[",st[12]:fin[12],",12]"),
  paste0("mu.rabbits[",st[13]:fin[13],",13]"),
  paste0("mu.rabbits[",st[14]:fin[14],",14]"),
  paste0("mu.rabbits[",st[15]:fin[15],",15]"),
  paste0("mu.rabbits[",st[16]:fin[16],",16]"),
  paste0("mu.rabbits[",st[17]:fin[17],",17]"),
  paste0("mu.rabbits[",st[18]:fin[18],",18]"),
  paste0("mu.rabbits[",st[19]:fin[19],",19]"),
  paste0("mu.rabbits[",st[20]:fin[20],",20]"),
  paste0("mu.rabbits[",st[21]:fin[21],",21]"),
  paste0("mu.fox[",st[1]:fin[1],",1]"),
  paste0("mu.fox[",st[2]:fin[2],",2]"),
  paste0("mu.fox[",st[3]:fin[3],",3]"),
  paste0("mu.fox[",st[4]:fin[4],",4]"),
  paste0("mu.fox[",st[5]:fin[5],",5]"),
  paste0("mu.fox[",st[6]:fin[6],",6]"),
  paste0("mu.fox[",st[7]:fin[7],",7]"),
  paste0("mu.fox[",st[8]:fin[8],",8]"),
  paste0("mu.fox[",st[9]:fin[9],",9]"),
  paste0("mu.fox[",st[10]:fin[10],",10]"),
  paste0("mu.fox[",st[11]:fin[11],",11]"),
  paste0("mu.fox[",st[12]:fin[12],",12]"),
  paste0("mu.fox[",st[13]:fin[13],",13]"),
  paste0("mu.fox[",st[14]:fin[14],",14]"),
  paste0("mu.fox[",st[15]:fin[15],",15]"),
  paste0("mu.fox[",st[16]:fin[16],",16]"),
  paste0("mu.fox[",st[17]:fin[17],",17]"),
  paste0("mu.fox[",st[18]:fin[18],",18]"),
  paste0("mu.fox[",st[19]:fin[19],",19]"),
  paste0("mu.fox[",st[20]:fin[20],",20]"),
  paste0("mu.fox[",st[21]:fin[21],",21]"))

#sample abundance predictions
predsamp<-coda.samples(hier.mod,
             c(predparamstring), 
               n.iter=NITER, thin=THIN)
#extract dic
end.time<-Sys.time()
print(end.time-start.time)

## ----PP_check, eval=FALSE, cache=TRUE, echo=FALSE, tidy=FALSE, cache.extra = tools::md5sum('gompertz_heirarch_rain_PPcheck.txt')----
## require("rjags")
## load.module("glm")
## NADAPT=250
## NITER=100
## NBURN=100
## THIN=1
## 
## start.time<-Sys.time()
## pp.mod<-jags.model('gompertz_heirarch_rain_PPcheck.txt',
##                      data=hier_dat, n.chains = 3, n.adapt = NADAPT)
## update(pp.mod, NBURN) #burnin
## pp.samp<-coda.samples(pp.mod,
##              c('chi', 'pval'),
##                n.iter=NITER, thin=THIN)

## ----PP_check_plot, eval=FALSE, echo=FALSE-------------------------------
## pp.samp

## ----hier_model_lag2, eval=FALSE, cache=TRUE, echo=FALSE, tidy=FALSE, cache.extra = tools::md5sum('gompertz_heirarch_lag2.txt')----
## require("rjags")
## load.module("glm")
## NADAPT=250
## NITER=40000
## NBURN=40000
## THIN=10
## 
## start.time<-Sys.time()
## hier.mod_lag2<-jags.model('gompertz_heirarch_lag2.txt',
##                      data=hier_dat, n.chains = 3, n.adapt = NADAPT)
## update(hier.mod_lag2, NBURN) #burnin
## samp_lag2<-coda.samples(hier.mod_lag2,
##              c('beta', 'sigma', 'r.mean', 'r.mean.rabbits',
##                'site.r.eff', 'site.r.eff.rabbits'),
##                n.iter=NITER, thin=THIN)
## #extract dic
## dic.heirarch_lag2<-dic.samples(hier.mod_lag2, 4000)
## print(dic.heirarch_lag2)
## end.time<-Sys.time()
## print(end.time-start.time)

## ----mcmc_results_beta, eval=FALSE, echo=FALSE, cache=TRUE, fig.cap='Posterior distributions of the regression parameters ($\\beta$)', dependson="hier_model"----
## require(ggmcmc) #fancy mcmc plots with ggplot2
## mcmc_result<-ggs(samp)

## ----mcmc_plot_beta, echo=FALSE, cache=FALSE, fig.cap='Posterior distributions of the regression parameters ($\\beta$).', dependson="hier_model", fig.pos="p!", message=FALSE----
require(ggplot2)
require(ggmcmc)
beta_result<-ggs(samp, family="^beta|^r.mean")
ggplot(beta_result, aes(x=value, group=Parameter))+
  geom_density(fill="red", alpha=0.3)+
  xlab("")+
  ylab("")+
  facet_wrap(~Parameter)+
  geom_vline(xintercept=0, col="black", linetype = "longdash")+
  theme_classic()

## ----mcmc_results_sigma, echo=FALSE, cache=FALSE, fig.cap='Posterior distributions of the error terms ($\\sigma$).', dependson="hier_model", fig.width=8*0.8, fig.height=5*0.8, fig.pos="p!", message=FALSE----
require(ggplot2)
require(ggmcmc)
require(dplyr)
beta_result<-ggs(samp, family="^sigma")

signames <- c(
  'sigma[1]'= "sigma[proc] (fox)",         #"\\sigma[proc] (fox)",
  'sigma[2]'="sigma[proc] (rabbit)",
  'sigma[3]'="sigma[transect] (fox)",
  'sigma[4]'="sigma[transect] (rabbit)"
)

#faclab<-function(variable, value){
#  return(signames[value])
#  llply(as.character(signames[value]), function(x) parse(text = x))
#}

ggplot(beta_result, aes(x=value, group=Parameter))+
  geom_density(fill="red", alpha=0.3)+
  facet_grid(.~Parameter)+ #labeller = faclab)+
  xlab("")+
  ylab("")+
  theme_classic()+
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5))

## ----mcmc_results_site_fox, eval=TRUE, echo=FALSE, cache=TRUE, fig.cap='Posterior densities of transect-level random effects ($\\zeta_{i}$) on rates-of-increase for foxes at the 21 transects.', dependson="hier_model",  fig.pos="p!"----
#ggs_caterpillar(mcmc_result, family = "site.r.eff")+ theme_classic()
sitelabs<-as.character(unique(obs_data$site))

raneff_result_rab<-ggs(samp, family="^site.r.eff.centered\\[")
param_names<-levels(raneff_result_rab$Parameter)

ggplot(raneff_result_rab, aes(factor(Parameter), value))+
  geom_violin(fill="darkorange3", alpha=0.65)+
  geom_hline(yintercept=0, col="black", linetype = "longdash")+
  ylab(expression(paste(zeta[i])))+
  scale_x_discrete(limits=levels(raneff_result_rab$Parameter), labels=sitelabs)+
  xlab("")+
  coord_flip()+
  theme_classic()

## ----mcmc_results_site, eval=TRUE, echo=FALSE, cache=TRUE, fig.cap='Posterior densities of transect-level random effects ($\\zeta_{i}$) on rates-of-increase for rabbits at the 21 transects.', dependson="hier_model", fig.pos="p!"----
#ggs_caterpillar(mcmc_result, family = "site.r.eff")+ theme_classic()
sitelabs<-as.character(unique(obs_data$site))

raneff_result_rab<-ggs(samp, family="^site.r.eff.rabbits.centered")
param_names<-levels(raneff_result_rab$Parameter)

ggplot(raneff_result_rab, aes(factor(Parameter), value))+
  geom_violin(fill="slategray3", alpha=0.65)+
  geom_hline(yintercept=0, col="black", linetype = "longdash")+
  ylab(expression(paste(zeta[i])))+
  scale_x_discrete(limits=levels(raneff_result_rab$Parameter), labels=sitelabs)+
  xlab("")+
  coord_flip()+
  theme_classic()

## ----mcmc_table_summary, eval=TRUE, echo=FALSE, cache=FALSE, dependson="hier_model", results='asis', message=FALSE----
require(xtable)
require(dplyr)
require(rjags)
param.names<-c("$\\beta_{1}$", "$\\beta_{2}$", "$\\beta_{3}$", "$\\beta_{4}$", "$\\beta_{5}$","$\\beta_{6}$", "$\\beta_{7}$",
               "$\\bar{r}_{\\mbox{fox}}$", "$\\bar{r}_{\\mbox{rabbit}}$",
                 "$\\sigma_{proc} \\mbox{(fox)}$", "$\\sigma_{proc} \\mbox{(rabbit)}$",
                  "$\\sigma_{transect} \\mbox{(fox)}$", "$\\sigma_{transect} \\mbox{(rabbit)}$")

tab1<-data.frame( summary(samp)$statistics[1:13,])
#row.names(tab1)<-param.names
tab2<-data.frame( summary(samp)$quantiles[1:13,])

tabout<-cbind(tab1[,1:2], tab2[,c(3, 1,5)])
  names(tabout)<-c("Mean", "SD", "Median", "q2.5", "q97.5")
  row.names(tabout)<-param.names
print(xtable(
  tabout, caption="Summary statistics for the posterior distributions of the state-space model\'s parameters.", 
  label="mcmc_summary",
    digits=4, align=c("l", "r", "r", "r", "r", "r") ) ,  sanitize.text.function = function(x){x}, table.placement="p!", caption.placement = "top")

## ----prediction_plot, eval=TRUE, echo=FALSE, cache=TRUE, fig.cap='Predicted rates of increase $(r)$ for fox populations under varying rabbit and fox abundances (counts per spotlight km). Separate predictions are given for the austral summer and winter half-yearly intervals, under low, medium and high rainfall. The dashed line denotes the combinations of rabbit and fox abundance for which $r=0$', fig.width=6----
#rain levels to consider (transformed same way as raw data)
require(ggplot2)
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

preddf$Season[preddf$Winter==1] <-"Winter"
preddf$Season[preddf$Winter==0] <-"Summer"

b <- c(-1.5,-1,-0.5, 0, 0.5, 1, 1.5)
ggplot(preddf, aes(x=Foxes, y=Rabbits, fill=r, z=r))+
  facet_grid(Rain ~ Season, labeller="label_both") +
  geom_raster(interpolate = TRUE) +
  stat_contour(breaks=c(0), lty=2)+  #contour where r=0
      scale_fill_gradientn(limits = c(-1.7,1.7),
                           colours=c("firebrick","red", "orange", "yellow2",
                                     "white", 
                                     "green", "limegreen", "chartreuse4", "darkgreen"),
                           breaks=b,labels=format(b))+
   labs(x = expression(paste("Foxes km",phantom(0)^-1)), 
        y = expression(paste("Rabbits km",phantom(0)^-1))) +
     theme_classic() +
  theme(axis.text.x=element_text(angle=90, vjust=0.5, hjust=0)) +
  theme(legend.title.align=0.5)

## ----pred_process1,  cache=FALSE, echo=FALSE, message=FALSE--------------
#this chunk won't cache
require(ggmcmc)
require(dplyr) #dplyr
preds<-ggs(predsamp) 

## ----pred_process2,  cache=FALSE, echo=FALSE, message=FALSE, dependson="heir_model"----
#pred 
require(ggmcmc)
require(dplyr)
require(rjags)
preds<-ggs(predsamp)
aa<-group_by(preds, Parameter)
pred_summary<-summarise(aa, post.mean = mean(value), 
                        post.med = median(value),
                      lwr =quantile(value, 0.025), 
                      upp=quantile(value, 0.975))
splitter<-function(x){
  bb<-unlist(strsplit(as.character(x), '[\\[,\\]'))
  cc<-unlist(strsplit(bb[3], '\\]'))
  out<-c(bb[1], as.numeric(as.character(bb[2])), as.numeric(as.character(cc)))
  out
}
vars<-t(sapply(as.character(pred_summary$Parameter), splitter))
vars<-data.frame(vars)
names(vars)<-c("Param", "Time", "Site")
vars$Time<-as.numeric(as.character(vars$Time))
vars$Site<-as.numeric(as.character(vars$Site))
preddf<-data.frame(pred_summary, vars)
preddf$time.orig<-1998 +(preddf$Time-1)/2
#tabulation of site codes and names, adding site names to the dataframe for plot labelling
labelling_tab<-data.frame(
  "Site"=unique(obs_data$site))
row.names(labelling_tab)<-as.numeric(unique(obs_data$site))
preddf$Sitename<-labelling_tab$Site[preddf$Site]

## ----tidy_obs_data, cache=FALSE, echo=FALSE, message=FALSE---------------
tidy_obs<-data.frame(
  "fox.count"=obs_data$foxes.counted,
  "rabbit.count"=obs_data$rabbits.counted,
  "trans.length"=obs_data$trans.length,
  "Site"=as.numeric(obs_data$site),
  "Sitename"=obs_data$site,
  "Time"=disctime_shifted,
  "time.orig"=1998 +(disctime_shifted-1)/2
  ) 

## ----fox_pred_graph, cache=FALSE, echo=FALSE, fig.height=9.5, fig.width=7.5, fig.cap='Predicted (line) and observed (points) relative abundances (spotlight counts per transect km) of foxes at each of the 21 study sites over the course of the study. Solid line is the posterior median, and shaded polygons are the 95\\% credible intervals of the mean expected abundances.', fig.pos="p!"----
#plotting estimated trajectories of all fox populations.
require(dplyr)
preddf %>%
  filter(Param=="mu.fox") %>%
ggplot(aes(x=time.orig, y=post.med))+
      geom_line(colour="black")+
      geom_ribbon(aes(ymin=lwr,ymax=upp, colour=NULL),alpha=0.65, fill="darkorange3")+
      ylab(expression(paste("Foxes k",m^{-1})))+
      xlab("Time")+
      xlim(1995, 2015)+
      geom_point(data=tidy_obs, aes(x=time.orig, y=fox.count/(trans.length/1000)), cex=1) +
      facet_wrap(~Sitename,  ncol=3, nrow=7, scales="free_y") +
      theme_classic() #classic 

## ----rabbit_pred_graph, cache=FALSE, echo=FALSE, message=FALSE, fig.height=9.5, fig.width=7.5, fig.cap='Predicted (line) and observed (points) relative abundances (spotlight counts per transect km) of rabbits at each of the 21 study sites over the course of the study. Solid line is the posterior median, and shaded polygons are the 95\\% credible intervals of the mean expected abundances.', fig.pos="p!"----
#plotting estimated trajectories of all rabbit populations.
require(dplyr)
preddf %>%
  filter(Param=="mu.rabbits") %>%
ggplot(aes(x=time.orig, y=post.med))+
      geom_line(colour="black")+
      geom_ribbon(aes(ymin=lwr,ymax=upp, colour=NULL),alpha=0.65, fill="slategray3")+
      ylab(expression(paste("Rabbits k",m^{-1})))+
      xlab("Time")+
      xlim(1995, 2015)+
      geom_point(data=tidy_obs, aes(x=time.orig, y=rabbit.count/(trans.length/1000)), cex=1) +
      facet_wrap(~Sitename, ncol=3, nrow=7, scales="free_y")+
      theme_classic() #classic

## ----rain_graph, eval=TRUE, echo=FALSE, cache=TRUE, message=FALSE, fig.height=9.5, fig.width=7.5, fig.cap='Half-yearly rainfall at the 21 transects 1996-2015.', dependson='import_rain_summary', fig.pos="p!"----
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

## ----site_summary_table, eval=FALSE, echo=FALSE, cache=TRUE, results='asis', message=FALSE----
## #compute mean rainfalls (doesn't work yet)
## ann_rain<-rain_tidy %>%
##   group_by(c(SiteName, Year)) %>%
##   summarize(AnnRain=sum() )
## ann_rain %>%
##   group_by(Year)
## 
## #compute summary statistics on survey effort (start/end dates, number of survey sessions etc)
## 

## ----traceplot_beta, eval=TRUE, echo=FALSE, cache=TRUE, fig.cap='MCMC traceplots for the regression parameters.', dependson="hier_model"----
ggs_traceplot(mcmc_result, family = "^beta|^r.mean") + theme_classic() #BGR diagnostics

## ----traceplot_sigma, eval=TRUE, echo=FALSE, cache=TRUE, fig.cap='MCMC traceplots for the error terms.', dependson="hier_model"----
ggs_traceplot(mcmc_result, family = "^sigma") + theme_classic() #BGR diagnostics

## ----gelman_diag_beta, eval=TRUE, echo=FALSE, cache=TRUE, fig.cap='Scale reduction factors for the regression parameters. Values close to one indicate convergence of the MCMC algorithm', dependson="hier_model", fig.width=6, fig.height=6----
ggs_Rhat(mcmc_result, family = "^beta|^r.mean") + xlab(expression(paste(hat(R))))+ theme_classic() #BGR diagnostics

## ----gelman_diag_sigma, eval=TRUE, echo=FALSE, cache=TRUE, fig.cap='Scale reduction factors for the error terms. Values close to one indicate convergence of the MCMC algorithm', dependson="hier_model", fig.width=6, fig.height=6----
ggs_Rhat(mcmc_result, family = "^sigma") + xlab(expression(paste(hat(R))))+ theme_classic() #BGR diagnostics

