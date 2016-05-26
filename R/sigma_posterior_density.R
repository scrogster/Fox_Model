require(ggplot2)
require(ggmcmc)
require(dplyr)

load("model_results.Rdata")

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

ggsave("Figures/sigma_posterior_density.pdf")
ggsave("Figures/sigma_posterior_density.png")