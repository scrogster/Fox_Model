library(RODBC)


wd<-'J:/Biodiversity Research/Terrestrial Research/Rabbit project/Split Database'

db<-'Statewide Rabbit Monitoring Program_20150805_be.mdb'

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
         ((tblSpotlightBackgroundData.[Spotlight Date])< #2014-07-01#))
ORDER BY tblSpotlightTransects.[Monitor Site], tblSpotlightBackgroundData.[Spotlight Date];
"

channel<-odbcConnectAccess(file.path(wd, db))


spotlight_dat<-sqlQuery(channel, paste(query))

close(channel)

write.csv(spotlight_dat , "Data/spotlight_data.csv", row.names=FALSE)
