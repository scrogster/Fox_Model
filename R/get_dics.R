
args<-commandArgs(trailingOnly=TRUE)

outfile<-file.path(args[1])

result_list<-list(
	"model_results_0_0.Rdata",
	"model_results_0_6.Rdata",
	"model_results_6_0.Rdata",
	"model_results_6_6.Rdata",
	"model_results_6_12.Rdata",
	"model_results_12_6.Rdata",
	"model_results_0_12.Rdata",
	"model_results_12_0.Rdata",
	"model_results_12_12.Rdata"
)


get_dic<-function(resultfile){
    load(paste(resultfile))
    out<-dic.heirarch
    return(out)
}

diclist<-lapply(result_list, get_dic)

dics<-sapply(diclist, function(x) {sum(x$deviance+x$penalty)})
devs<-sapply(diclist, function(x) {sum(x$deviance)})

deltaDIC <- dics-dics[which.min(dics)]
weights <- exp(-0.5 *deltaDIC)

mod_names <- unlist(result_list)
fox_lag <- sapply(strsplit(as.character(mod_names), "[_.]"), function(x){x[3]})
rabbit_lag <- sapply(strsplit(as.character(mod_names), "[_.]"), function(x){x[4]})

modseltab <- data.frame(mod_names, fox_lag, rabbit_lag, devs, deltaDIC, model.weights = weights/sum(weights)  )

modseltab <- modseltab[order(modseltab$model.weights, decreasing = TRUE),]

save.image(outfile)
