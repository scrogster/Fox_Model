require("rjags")
load.module("glm")
NADAPT=250
NITER=40000
NBURN=40000
THIN=10

args=commandArgs(trailingOnly=TRUE)


prepped_data=args[1]
modelfile=args[2]
outfile=args[3]

load(file.path(prepped_data))

start.time<-Sys.time()
hier.mod<-jags.model(file.path(modelfile), 
				 data=hier_dat, n.chains = 3, n.adapt = NADAPT) 
update(hier.mod, NBURN) #burnin
samp<-coda.samples(hier.mod,
			    c('beta', 'sigma', 'r.mean', 'r.mean.rabbits', 
			      'site.r.eff.centered', 'site.r.eff.rabbits.centered'), 
			    n.iter=NITER, thin=THIN)

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
dic.heirarch<-dic.samples(hier.mod, NITER/10)
print(dic.heirarch)

end.time<-Sys.time()
print(end.time-start.time)

save.image(file.path(outfile))