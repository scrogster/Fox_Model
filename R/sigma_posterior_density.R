require(ggplot2)
require(ggmcmc)
require(dplyr)
library(grid)

args=commandArgs(trailingOnly=TRUE)

model_data=args[1]

load(file.path(model_data))

beta_result<-ggs(samp, family="^sigma")

# signames <- c(
# 	'sigma[1]'= "sigma[proc] (fox)",         #"\\sigma[proc] (fox)",
# 	'sigma[2]'="sigma[proc] (rabbit)",
# 	'sigma[3]'="sigma[transect] (fox)",
# 	'sigma[4]'="sigma[transect] (rabbit)"
# )


ggplot(beta_result, aes(x=value, group=Parameter))+
	geom_density(fill="red", alpha=0.3)+
	facet_wrap(~Parameter)+
	xlab("")+
	ylab("")+
	theme_classic()+
	theme(axis.text.x = element_text(angle = 90, vjust = 0.5))

grid.gedit(gPath(paste0("strip_t-", 1), "strip.text"), 
		 grep=TRUE, label=bquote(sigma[proc](fox)))
grid.gedit(gPath(paste0("strip_t-", 2), "strip.text"), 
		 grep=TRUE, label=bquote(sigma[proc](rabbit)))
grid.gedit(gPath(paste0("strip_t-", 3), "strip.text"), 
		 grep=TRUE, label=bquote(sigma[transect](fox)))
grid.gedit(gPath(paste0("strip_t-", 4), "strip.text"), 
		 grep=TRUE, label=bquote(sigma[transect](rabbit)))

ggsave("Figures/sigma_posterior_density.pdf")
ggsave("Figures/sigma_posterior_density.png")