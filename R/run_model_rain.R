require("jagsUI")
NADAPT=1000
NITER=40000
NBURN=20000
THIN=5
NCHAINS=4

set.seed(45454545)

prepped_data="prepped_data.Rdata"
modelfile="R/GHR_distlag_rain.txt"
outfile="test.Rdata"

load(file.path(prepped_data))
start.time<-Sys.time()



params=c('beta', 'sigma', 'r.mean', 'r.mean.rabbits', 
  'site.r.eff.centered', 'site.r.eff.rabbits.centered', 'fox.lag', 'rabbit.lag', 'food.lag')

#assembling a big string of abundance predictions #we predict a little into the future and also hindcast a bit.
st<-ifelse(start_times$start_times==5, 5, pmax(start_times$start_times-10, 5))
fin<-ifelse(end_times$end_times==40, 40, pmin(end_times$end_times+10, 40))
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



samp<-jags(data=hier_dat, parameters.to.save=c(params, predparamstring), model.file=modelfile, parallel=TRUE,
		 n.chains=NCHAINS, n.adapt=NADAPT, n.iter=NITER, n.burnin=NBURN, n.thin=THIN)


end.time<-Sys.time()
duration_run<-end.time-start.time
print(duration_run)

save.image("Fitted_rain_model.Rdata")