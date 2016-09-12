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
         ((tblSpotlightBackgroundData.[Spotlight Date])< #2016-06-30#)) 
ORDER BY tblSpotlightTransects.[Monitor Site], tblSpotlightBackgroundData.[Spotlight Date];
"

#Code to cull out some months if desired. For now leaving all in. Tradeoff between keeping just strictly autumn/spring data, and volume of data.
#AND 
#(month(tblSpotlightBackgroundData.[Spotlight Date])>2 AND month(tblSpotlightBackgroundData.[Spotlight Date])<6 )OR
#(month(tblSpotlightBackgroundData.[Spotlight Date])>8 AND month(tblSpotlightBackgroundData.[Spotlight Date])<12 )

channel<-odbcConnectAccess(file.path(wd, db))


spotlight_dat<-sqlQuery(channel, paste(query))

close(channel)

write.csv(spotlight_dat , "Data/spotlight_data.csv", row.names=FALSE)
