library(RODBC)
library(dplyr)

wd<-'J:/Biodiversity Research/Terrestrial Research/Rabbit project/Split Database'

db_old<-'Statewide Rabbit Monitoring Program_20150805_be.mdb'
db<-'Statewide Rabbit Monitoring Program_20170802_be.mdb' #new copy of DB code added 17/8/2017

query<-"SELECT tblSpotlightTransects.[Monitor Site], 
               tblSpotlightBackgroundData.[Spotlight Date], 
               tblSpotlightBackgroundData.Replicate_Count, 
               Sum(tblSpotlightCount.[Spotlight length (m)]) AS TransectLength, 
               Sum(tblSpotlightCount.[Number of Rabbits]) AS Rabbits, 
               Sum(tblSpotlightCount.[Number of Foxes]) AS Foxes
FROM tblSpotlightTransects INNER JOIN (tblSpotlightBackgroundData INNER JOIN tblSpotlightCount ON tblSpotlightBackgroundData.SpotlightBackgroundID = tblSpotlightCount.SpotlightBackgroundID) ON tblSpotlightTransects.SpotlightTransectID = tblSpotlightCount.SpotlightTransectID
GROUP BY tblSpotlightTransects.[Monitor Site], tblSpotlightBackgroundData.[Spotlight Date], tblSpotlightBackgroundData.Replicate_Count
HAVING ((Not (tblSpotlightTransects.[Monitor Site])='Avalon' And 
         Not (tblSpotlightTransects.[Monitor Site])='Sunbury' And 
         Not (tblSpotlightTransects.[Monitor Site])='Kerang') AND 
         ((tblSpotlightBackgroundData.[Spotlight Date])< #2016-06-30#)) 
ORDER BY tblSpotlightTransects.[Monitor Site], tblSpotlightBackgroundData.[Spotlight Date];
"

#Code to cull out some months if desired. For now leaving all in. Tradeoff between keeping just strictly autumn/spring data, and volume of data.
#AND 
#(month(tblSpotlightBackgroundData.[Spotlight Date])>2 AND month(tblSpotlightBackgroundData.[Spotlight Date])<6 )OR
#(month(tblSpotlightBackgroundData.[Spotlight Date])>8 AND month(tblSpotlightBackgroundData.[Spotlight Date])<12 )

channel<-odbcConnectAccess(file.path(wd, db))
spotlight_dat<-sqlQuery(channel, paste(query))

query2<-"SELECT tblMonitorSites.[Monitor site] AS `Monitor Site`, tblMonitorSites.[Ripped Date] FROM tblMonitorSites;"
ripdate_dat<-sqlQuery(channel, paste(query2))

close(channel)

#join the rip dates into the data
sdat<-spotlight_dat %>%
	  left_join(ripdate_dat, by="Monitor Site") %>%
	  mutate(PostRipped = `Spotlight Date`>=`Ripped Date`) %>%
       mutate(PostRipped =ifelse(is.na(PostRipped), FALSE, PostRipped)) %>%
	  select(-`Ripped Date`) %>%
	  data.frame()


write.csv(sdat , "Data/spotlight_data.csv", row.names=FALSE)
