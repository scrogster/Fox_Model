
result_list<-list(
	"model_results_0_0.Rdata",
	"model_results_0_6.Rdata",
	"model_results_6_0.Rdata",
	"model_results_0_6.Rdata",
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

lapply(result_list, get_dic)
