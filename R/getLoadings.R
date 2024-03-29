#' The getLoadings function
#'
#' This function predicts the pathogen loadings from onsite sanitation systems for data available through the UNICEF/WHO Joint Monitoring Program and provides an output that can be used directly by the Pathogen Mapping Tool.
#' @param inputDF A dataframe containing your onsite sanitation data. An example template can be found at http://data.waterpathogens.org/
#' @param pathogenType Specify either "Virus","Bacteria","Protozoa", or "Helminth"
#' @keywords pathogens
#' @export
#' @examples
#' myOutput<-getLoadings(inputDF,pathogenType="Virus")
#' myOutput$output
#'
#' $output
#'      gid excreted   to_groundwater   to_surface       retained_in_soil      decayed         In_Fecal_Sludge    In_Sewage        stillViable        Onsite_LRV     Onsite_PR
#' 1    HND 3.63e+18   5.840389e+16     1.963546e+18     5.738629e+17          5.042712e+17    1.179983e+14       5.297977e+17     2.551866e+18       0.15           0.2970
#' 2    UGA 1.67e+19   1.565005e+17     1.731193e+18     1.408505e+18          1.340068e+19    0.000000e+00       3.127723e+15     1.890822e+18       0.95           0.8868

getLoadings<-function(inputDF=read.csv("data/input_file_new_kla_div_20200729-0Baseline.csv"),pathogenType="Virus"){

  df1<-inputDF

#comment out these lines after testing
  #df1<-df1[,c(1:42)]
  #colnames(df1)<-c(colnames(df1[,c(1:19)]),substr(colnames(df1[,c(20:42)]),1,nchar(colnames(df1[,c(20:42)]))-4))
  #colnames(df1)
  #df1$excreted<-rep(1e10,5)
#comment out these lines after testing

  pathogenGroups<-c("Virus","Bacteria","Protozoa","Helminth")
  index<-which(pathogenGroups==pathogenType)
  # &&&&& START GWPP Inputs &&&&&
  lambdas<-c(lambdaV=0.2,lambdaB=0.3,lambdaP=0.6,lambdaH=0.99) # these lambda values are based on data from the literature (Chauret et al., 1999; Lucena et al., 2004; Ramo et al., 2017; Rose et al., 1996; Kinyua et al. 2016; Tanji et al., 2002; Tsai et al., 1998)
  vzReduction<-c(vzV=0.1,vzB=0.01,vzP=0.001,vzH=0.0001) # currently assuming 1-, 2-, 3-, and 4-log reduction of viruses, bacteria, protozoa, and helminth eggs, respectively, between pits and groundwater

  #persistence model in pits
  persist<-read.csv("http://data.waterpathogens.org/dataset/eda3c64c-479e-4177-869c-93b3dc247a10/resource/f99291ab-d536-4536-a146-083a07ea49b9/download/k2p_persistence.csv",header=T)
  persist<-read.csv("data/k2p_persistence_WR.csv",header=T)
  persist<-persist[1:(length(persist)-1)]
  #persist<-persist[persist$matrix=="Fecal sludge",]
  persist<-subset(persist,matrix=="Fecal sludge")
  persist$ln_removal<--persist$log10_reduction*log(10)
  N<-length(unique(persist$experiment_id))
  persist$ind<-NA       # this will be an index variable to distinguish each independent experiment
  for(j in 1:length(persist$experiment_id)){
    persist$ind[j]<-which(data.frame(unique(persist$experiment_id))==persist$experiment_id[j])
  }
<<<<<<< HEAD
  k<-rep(NA,N);group<-rep(NA,N);addit<-rep(NA,N);urea<-rep(NA,N);pH<-rep(NA,N);urine<-rep(NA,N);moisture<-rep(NA,N);temperature<-rep(NA,N);r2<-rep(NA,N);num<-rep(NA,N);authors<-rep(NA,N)
=======
  k<-rep(NA,N);group<-rep(NA,N);addit<-rep(NA,N); pH<-rep(NA,N);urine<-rep(NA,N);urea<-rep(NA,N);moisture<-rep(NA,N);temperature<-rep(NA,N);r2<-rep(NA,N);num<-rep(NA,N);authors<-rep(NA,N)
>>>>>>> fb831e81352fbaa2ec30fb2aebbf9c32ffb0b9b9

  for(z in 1:N){   #in this loop, we calculate the k value for the log linear decay:                 Ct = Co*exp(-k*t)
    time<-persist[persist$ind==z,]$time_days   #get the time only for the present experiment
    lnrv<-persist[persist$ind==z,]$ln_removal  #get the ln reduction only for the present experiment
    # since we calculated the ln reduction, then equation gets algebraically rearranged like this:    ln(Ct/Co) = -k*t
    # lnrv is ln(Ct/Co), so our linear model is like this: lnrv~time
    fit<-lm(lnrv~time)
    num[z]<-length(time)
    r2[z]<-suppressWarnings(summary(fit)$r.squared)
    k[z]<-fit$coefficients[2]
    authors[z]<-paste(unique(persist[persist$ind==z,]$bib_id),as.character(unique(persist[persist$ind==z,]$authors)))
    group[z]<-as.character(unique(persist[persist$ind==z,]$microbial_group))
    addit[z]<-as.character(unique(persist[persist$ind==z,]$additive))
    pH[z]<-as.numeric(median(persist[persist$ind==z,]$pH))
    urine[z]<-as.character(unique(persist[persist$ind==z,]$urine))
    urea[z]<-as.character(unique(persist[persist$ind==z,]$urea))
<<<<<<< HEAD
    moisture[z]<-as.numeric(median(persist[persist$ind==z,]$moisture_content_percent))
    temperature[z]<-as.numeric(median(persist[persist$ind==z,]$temperature_celsius))
  }
  kPit<-data.frame(authors=authors,microbial_group=group,k=k,num=num,additive=addit,pH=pH,temp=temperature,moisture=moisture,urea=urea,urine=urine,r2=r2)
  #write.csv(kPit,"kPit3.csv")
  #kPit=kPit[-c(30,46,47,73,204,205),] #removing data points that are outliers
  kPit<-kPit[kPit$r2>0.5,] #only keeping data with good log linear fit (r2>0.7)
  kPit<-kPit[kPit$k<0,] #removing any data showing growth
  kPit<-kPit[kPit$num>4,] #removing any results from experiments done with fewer than 4 data points
  kPit$lk<-log(-kPit$k)
  kPit$ltemp<-log(kPit$temp)
  kPit<-kPit[-64,]
  fit_kPit<-lm(lk~factor(microbial_group)+factor(urine)+factor(urea)*pH+temp+moisture+additive,data=kPit)
  #summary(fit_kPit)
  # not UDT, no additives
  kValueV<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Excreta",pH=7,temp=(30),urea="None",moisture=80,additive="None",microbial_group="Virus"))))
  kValueB<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Excreta",pH=7,temp=(30),urea="None",moisture=80,additive="None",microbial_group="Bacteria"))))
  kValueP<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Excreta",pH=7,temp=(30),urea="None",moisture=80,additive="None",microbial_group="Protozoa"))))
  kValueH<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Excreta",pH=7,temp=(30),urea="None",moisture=80,additive="None",microbial_group="Helminth"))))
  # UDT, no additives
  kValueV_udt<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Feces only",pH=7,temp=(30),urea="None",moisture=40,additive="None",microbial_group="Virus"))))
  kValueB_udt<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Feces only",pH=7,temp=(30),urea="None",moisture=40,additive="None",microbial_group="Bacteria"))))
  kValueP_udt<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Feces only",pH=7,temp=(30),urea="None",moisture=40,additive="None",microbial_group="Protozoa"))))
  kValueH_udt<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Feces only",pH=7,temp=(30),urea="None",moisture=40,additive="None",microbial_group="Helminth"))))
  # not UDT, additives
  kValueV_a<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Excreta",pH=7,temp=(30),urea="Urea",moisture=80,additive="Lime",microbial_group="Virus"))))
  kValueB_a<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Excreta",pH=7,temp=(30),urea="Urea",moisture=80,additive="Lime",microbial_group="Bacteria"))))
  kValueP_a<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Excreta",pH=7,temp=(30),urea="Urea",moisture=80,additive="Lime",microbial_group="Protozoa"))))
  kValueH_a<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Excreta",pH=7,temp=(30),urea="Urea",moisture=80,additive="Lime",microbial_group="Helminth"))))
  # UDT, additives
  kValueV_udt_a<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Feces only",pH=7,temp=(30),urea="Urea",moisture=40,additive="Lime",microbial_group="Virus"))))
  kValueB_udt_a<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Feces only",pH=7,temp=(30),urea="Urea",moisture=40,additive="Lime",microbial_group="Bacteria"))))
  kValueP_udt_a<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Feces only",pH=7,temp=(30),urea="Urea",moisture=40,additive="Lime",microbial_group="Protozoa"))))
  kValueH_udt_a<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Feces only",pH=7,temp=(30),urea="Urea",moisture=40,additive="Lime",microbial_group="Helminth"))))
=======
    moisture[z]<-as.numeric(max(persist[persist$ind==z,]$moisture_content_percent))
    temperature[z]<-as.numeric(median(persist[persist$ind==z,]$temperature_celsius))
  }
  kPit<-data.frame(microbial_group=group,k=k,num=num,additive=addit,pH=pH,temp=temperature,moisture=moisture,urine=urine,urea=urea,r2=r2)
  #kPit=kPit[-c(30,46,47,73,204,205),] #removing data points that are outliers
  #kPit<-kPit[kPit$r2>0.7,] #only keeping data with good log linear fit (r2>0.7)
  #kPit<-kPit[kPit$k<0,] #removing any data showing growth
  #kPit<-kPit[kPit$num>4,] #removing any results from experiments done with fewer than 4 data points
  kPit$lk<-log(-kPit$k)
  #kPit$ltemp<-log(kPit$temp)
  fit_kPit<-lm(lk~factor(microbial_group)+pH+temp+moisture+factor(urine)+factor(urea)+factor(additive),data=kPit[kPit$temp<50,])
  #summary(fit_kPit)
  # not UDT, no additives
  kValueV<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Excreta",pH=7,temp=(30),moisture=80,additive="None",urea="None",microbial_group="Virus"))))
  kValueB<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Excreta",pH=7,temp=(30),moisture=80,additive="None",urea="None",microbial_group="Bacteria"))))
  kValueP<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Excreta",pH=7,temp=(30),moisture=80,additive="None",urea="None",microbial_group="Protozoa"))))
  kValueH<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Excreta",pH=7,temp=(30),moisture=80,additive="None",urea="None",microbial_group="Helminth"))))
  # UDT, no additives
  kValueV_udt<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Feces only",pH=7,temp=(30),moisture=80,additive="None",urea="None",microbial_group="Virus"))))
  kValueB_udt<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Feces only",pH=7,temp=(30),moisture=80,additive="None",urea="None",microbial_group="Bacteria"))))
  kValueP_udt<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Feces only",pH=7,temp=(30),moisture=80,additive="None",urea="None",microbial_group="Protozoa"))))
  kValueH_udt<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Feces only",pH=7,temp=(30),moisture=80,additive="None",urea="None",microbial_group="Helminth"))))
  # not UDT, additives
  kValueV_a<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Excreta",pH=7,temp=(30),moisture=80,additive="Lime",urea="Urea",microbial_group="Virus"))))
  kValueB_a<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Excreta",pH=7,temp=(30),moisture=80,additive="Lime",urea="Urea",microbial_group="Bacteria"))))
  kValueP_a<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Excreta",pH=7,temp=(30),moisture=80,additive="Lime",urea="Urea",microbial_group="Protozoa"))))
  kValueH_a<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Excreta",pH=7,temp=(30),moisture=80,additive="Lime",urea="Urea",microbial_group="Helminth"))))
  # UDT, additives
  kValueV_udt_a<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Feces only",pH=7,temp=(30),moisture=80,additive="Lime",urea="Urea",microbial_group="Virus"))))
  kValueB_udt_a<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Feces only",pH=7,temp=(30),moisture=80,additive="Lime",urea="Urea",microbial_group="Bacteria"))))
  kValueP_udt_a<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Feces only",pH=7,temp=(30),moisture=80,additive="Lime",urea="Urea",microbial_group="Protozoa"))))
  kValueH_udt_a<-suppressWarnings(exp(predict(fit_kPit,newdata=data.frame(urine="Feces only",pH=7,temp=(30),moisture=80,additive="Lime",urea="Urea",microbial_group="Helminth"))))
>>>>>>> fb831e81352fbaa2ec30fb2aebbf9c32ffb0b9b9

  kValues<-data.frame(Virus=c(kValueV,kValueV_udt,kValueV_a,kValueV_udt_a),Bacteria=c(kValueB,kValueB_udt,kValueB_a,kValueB_udt_a),Protozoa=c(kValueP,kValueP_udt,kValueP_a,kValueP_udt_a),Helminth=c(kValueH,kValueH_udt,kValueH_a,kValueH_udt_a))
  rownames(kValues)<-c("conventional","urine-diverting","conventional w/ lime.urea","urine-diverting w/ lime.urea") #the units here are 1/days
  # &&&&& END GWPP Inputs &&&&&

  loops<-nrow(df1)

  loadings.names <- c("virus", "bacteria", "protozoa", "helminth")
  loadings <- vector("list", length(loadings.names))
  names(loadings) <- loadings.names
  for(o in 1:4){
    loadings[[o]] <- vector("list",loops)
    names(loadings[[o]]) <- df1$gid
  }

  onsite_results.names <- c("virus", "bacteria", "protozoa", "helminth")
  onsite_results <- vector("list", length(onsite_results.names))
  names(onsite_results) <- onsite_results.names

  loadings<-loadings[[index]]
  onsite_results<-onsite_results[[index]]
  myJMP1<-read.csv("http://data.waterpathogens.org/dataset/86741b90-62ab-4dc2-941c-60c85bfe7ffc/resource/9113d653-0e10-4b4d-9159-344c494f7fc7/download/jmp_assumptions.csv",header=T)

  for(m in 1:loops){  # m is an index for region or subregion
    df<-df1[m,]
    myJMP<-myJMP1
    gid<-df$gid
    population<-df$population
    excreted<-df$excreted
    isWatertight<-if(is.null(df$isWatertight)){0}else{if(is.na(df$isWatertight)){0}else{df$isWatertight}}
    hasLeach<-if(is.null(df$hasLeach)){0}else{if(is.na(df$hasLeach)){0}else{df$hasLeach}}
    emptyFrequency<-if(is.null(df$emptyFrequency)){3}else{if(is.na(df$emptyFrequency)){3}else{df$emptyFrequency}}
    pitAdditive<-if(is.null(df$pitAdditive)){0}else{if(is.na(df$pitAdditive)){0}else{df$pitAdditive}}
    twinPits<-if(is.null(df$twinPits)){0}else{if(is.na(df$twinPits)){0}else{df$twinPits}}
    urine_diverting<-if(is.null(df$urine)){0}else{if(is.na(df$urine)){0}else{df$urine}}

    coverBury<-if(is.null(df$coverBury)){0}else{if(is.na(df$coverBury)){0}else{df$coverBury}}
    emptiedTreatment<-if(is.null(df$fecalSludgeTreated)){0}else{if(is.na(df$fecalSludgeTreated)){0}else{df$fecalSludgeTreated}}
    sewerLeak<-if(is.null(df$sewageTreated)){1}else{if(is.na(df$sewageTreated)){1}else{1-df$sewageTreated}}

    flushSewer<-if(is.null(df$flushSewer)){0}else{if(is.na(df$flushSewer)){0}else{df$flushSewer}}
    flushSeptic<-if(is.null(df$flushSeptic)){0}else{if(is.na(df$flushSeptic)){0}else{df$flushSeptic}}
    flushPit<-if(is.null(df$flushPit)){0}else{if(is.na(df$flushPit)){0}else{df$flushPit}}
    flushOpen<-if(is.null(df$flushOpen)){0}else{if(is.na(df$flushOpen)){0}else{df$flushOpen}}
    flushUnknown<-if(is.null(df$flushUnknown)){0}else{if(is.na(df$flushUnknown)){0}else{df$flushUnknown}}
    pitSlab<-if(is.null(df$pitSlab)){0}else{if(is.na(df$pitSlab)){0}else{df$pitSlab}}
    pitNoSlab<-if(is.null(df$pitNoSlab)){0}else{if(is.na(df$pitNoSlab)){0}else{df$pitNoSlab}}
    #compostingTwinSlab<-if(is.null(df$compostingTwinSlab)){0}else{if(is.na(df$compostingTwinSlab)){0}else{df$compostingTwinSlab}}
    #compostingTwinNoSlab<-if(is.null(df$compostingTwinNoSlab)){0}else{if(is.na(df$compostingTwinNoSlab)){0}else{df$compostingTwinNoSlab}}
    compostingToilet<-if(is.null(df$compostingToilet)){0}else{if(is.na(df$compostingToilet)){0}else{df$compostingToilet}}
    bucketLatrine<-if(is.null(df$bucketLatrine)){0}else{if(is.na(df$bucketLatrine)){0}else{df$bucketLatrine}}
    containerBased<-if(is.null(df$containerBased)){0}else{if(is.na(df$containerBased)){0}else{df$containerBased}}
    hangingToilet<-if(is.null(df$hangingToilet)){0}else{if(is.na(df$hangingToilet)){0}else{df$hangingToilet}}
    openDefecation<-if(is.null(df$openDefecation)){0}else{if(is.na(df$openDefecation)){0}else{df$openDefecation}}
    other<-if(is.null(df$other)){0}else{if(is.na(df$other)){0}else{df$other}}


    daysperyear<-366
    decayTimeUNSAFE<-daysperyear  # this is the average time interval between unsafe pit emptying events (default is set to 1 year, assuming it happens at the beginning of the rainy season)

    myJMP$percentage<-c(flushSewer,
                        flushSeptic,
                        flushPit,
                        flushOpen,
                        flushUnknown,
                        pitSlab,
                        pitNoSlab,
                        #compostingTwinSlab,
                        #compostingTwinNoSlab,
                        compostingToilet,
                        bucketLatrine,
                        containerBased,
                        hangingToilet,
                        openDefecation,
                        other)

    myJMP$tankWatertight<-c(0,isWatertight,rep(0,11))
    myJMP$leachSystem<-c(0,hasLeach,rep(0,11))
    myJMP$cover_bury<-c(0,coverBury,coverBury,0,0,coverBury,0,coverBury,0,coverBury,0,0,coverBury)
    myJMP$tankOutlet<-myJMP$flushOnsite*(1-myJMP$leachSystem)

    myJMP$DRY_TOILET<-(1-myJMP$flushSewer)*(1-myJMP$flushOnsite)

    myJMP$FLUSH_TOILET_sewered<-myJMP$flushSewer
    myJMP$FLUSH_TOILET_containedNotWT<-(1-myJMP$flushSewer)*myJMP$flushOnsite*(1-myJMP$tankWatertight)
    myJMP$FLUSH_TOILET_containedWT_noLeach<-myJMP$flushOnsite*myJMP$tankWatertight*myJMP$tankOutlet
    myJMP$FLUSH_TOILET_containedWT_Leach<-myJMP$flushOnsite*myJMP$tankWatertight*myJMP$leachSystem

    myJMP$safeEmpty<-emptiedTreatment*(1-myJMP$FLUSH_TOILET_sewered-myJMP$cover_bury)
    myJMP$unsafeEmpty<-1-myJMP$FLUSH_TOILET_sewered-myJMP$cover_bury-myJMP$safeEmpty #includes "flooding out" latrines in the rainy season

    myJMP$twinPits<-c(0,twinPits,twinPits,0,0,twinPits,0,twinPits,0,0,0,0,0)
    myJMP$singlePits<-c(0,(1-twinPits),(1-twinPits),0,0,(1-twinPits),1,(1-twinPits),0,1,0,0,0)

    myJMP$UDT<-c(0,0,0,0,0,urine_diverting,0,1,0,0,0,0,0) #assumed that all composting toilets are urine diverting, and the fraction urine_diverting controls pitSlab)
    myJMP$pitAdd<-c(0,0,0,0,0,pitAdditive,pitAdditive,pitAdditive,pitAdditive,pitAdditive,0,0,0) #pit additives can be added to all dry onsite toilets (pitSlab, pitNoSlab, bucketLatrine, containerBased, and compostingToilet)

    # ^^^^^ END JMP data calculations ^^^^^

    loadings[[m]]<-data.frame(myJMP[,c("name","classification","percentage","initiallyContained","flushSewer","FLUSH_TOILET_containedNotWT","FLUSH_TOILET_containedWT_Leach","FLUSH_TOILET_containedWT_noLeach","unsafeEmpty","safeEmpty","twinPits","singlePits","UDT","pitAdd")])

    # &&&&& START PFM Onsite Calculations &&&&&

    i=index
    loadings[[m]]$lamda<-c(0,lambdas[i],lambdas[i],0,0,1,1,1,0,1,0,0,0)
    loadings[[m]]$excreted<-excreted*loadings[[m]]$percentage  #Eq. 1: Pathogen Loading Model (Column J) #/year
    loadings[[m]]$initContained<-loadings[[m]]$excreted*loadings[[m]]$initiallyContained  #Eq. 2: Number Initially Contained (Column O) #/year
    loadings[[m]]$notContained<-loadings[[m]]$excreted-loadings[[m]]$initContained
    loadings[[m]]$inLiquid<-loadings[[m]]$initContained*(1-loadings[[m]]$lamda)*(1-loadings[[m]]$flushSewer)
    loadings[[m]]$inSolid<-loadings[[m]]$initContained*loadings[[m]]$lamda*(1-loadings[[m]]$flushSewer)
    loadings[[m]]$toGW<-loadings[[m]]$inLiquid*(loadings[[m]]$FLUSH_TOILET_containedNotWT+loadings[[m]]$FLUSH_TOILET_containedWT_Leach)*vzReduction[[i]]   #Eq. 5: Number Reaching Groundwater (Column AI) #/year
    loadings[[m]]$inVZ<-loadings[[m]]$inLiquid*(loadings[[m]]$FLUSH_TOILET_containedNotWT+loadings[[m]]$FLUSH_TOILET_containedWT_Leach)-loadings[[m]]$toGW
    loadings[[m]]$coveredBuried<-loadings[[m]]$inSolid*coverBury
    loadings[[m]]$totalSubsurface<-loadings[[m]]$inVZ+loadings[[m]]$coveredBuried
    loadings[[m]]$toSW_liq<-loadings[[m]]$inLiquid*loadings[[m]]$FLUSH_TOILET_containedWT_noLeach+loadings[[m]]$initContained*loadings[[m]]$flushSewer*sewerLeak
    loadings[[m]]$toSW_sol_twin<-NA
    loadings[[m]]$toSW_sol_sing<-NA
    loadings[[m]]$unsafeDecay_twin<-NA
    loadings[[m]]$unsafeDecay_sing<-NA
    loadings[[m]]$toFSTP_twin<-NA
    loadings[[m]]$toFSTP_sing<-NA
    loadings[[m]]$safeDecay_twin<-NA
    loadings[[m]]$safeDecay_sing<-NA

    for(j in 1:13){  # decay for toilets with UNSAFE emptying practices
      remainingTwinNoUD<-exp(-kValues["conventional",i]*(seq(decayTimeUNSAFE,1,by=-1)+decayTimeUNSAFE-1));remainingTwinNoUD<-replace(remainingTwinNoUD,which(remainingTwinNoUD<0.001),0.001) # this limits onsite pathogen reduction to no more than 3-log reduction
      remainingTwinUD<-exp(-kValues["urine-diverting",i]*(seq(decayTimeUNSAFE,1,by=-1)+decayTimeUNSAFE-1));remainingTwinUD<-replace(remainingTwinUD,which(remainingTwinUD<0.001),0.001) # this limits onsite pathogen reduction to no more than 3-log reduction
      remainingTwinLime<-exp(-kValues["conventional w/ lime.urea",i]*(seq(decayTimeUNSAFE,1,by=-1)+decayTimeUNSAFE-1));remainingTwinLime<-replace(remainingTwinLime,which(remainingTwinLime<0.001),0.001)
      remainingTwinUrea<-exp(-kValues["urine-diverting w/ lime.urea",i]*(seq(decayTimeUNSAFE,1,by=-1)+decayTimeUNSAFE-1));remainingTwinUrea<-replace(remainingTwinUrea,which(remainingTwinUrea<0.001),0.001)
      toSW_sol_twin_noUDT<-loadings[[m]]$twinPits[j]*(1-loadings[[m]]$pitAdd[j])*(1-loadings[[m]]$UDT[j])*sum(remainingTwinNoUD*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$unsafeEmpty[j])
      toSW_sol_twin_UDT<-loadings[[m]]$twinPits[j]*(1-loadings[[m]]$pitAdd[j])*(loadings[[m]]$UDT[j])*sum(remainingTwinUD*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$unsafeEmpty[j])
      toSW_sol_twin_lime<-loadings[[m]]$twinPits[j]*(loadings[[m]]$pitAdd[j])*(1-loadings[[m]]$UDT[j])*sum(remainingTwinNoUD*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$unsafeEmpty[j])
      toSW_sol_twin_urea<-loadings[[m]]$twinPits[j]*(loadings[[m]]$pitAdd[j])*(loadings[[m]]$UDT[j])*sum(remainingTwinUD*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$unsafeEmpty[j])
      loadings[[m]]$toSW_sol_twin[j]<-toSW_sol_twin_UDT+toSW_sol_twin_noUDT+toSW_sol_twin_lime+toSW_sol_twin_urea
      unsafeDecay_twin_noUDT<-loadings[[m]]$twinPits[j]*(1-loadings[[m]]$pitAdd[j])*(1-loadings[[m]]$UDT[j])*sum((1-remainingTwinUD)*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$unsafeEmpty[j])
      unsafeDecay_twin_UDT<-loadings[[m]]$twinPits[j]*(1-loadings[[m]]$pitAdd[j])*(loadings[[m]]$UDT[j])*sum((1-remainingTwinNoUD)*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$unsafeEmpty[j])
      unsafeDecay_twin_lime<-loadings[[m]]$twinPits[j]*(loadings[[m]]$pitAdd[j])*(1-loadings[[m]]$UDT[j])*sum((1-remainingTwinUD)*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$unsafeEmpty[j])
      unsafeDecay_twin_urea<-loadings[[m]]$twinPits[j]*(loadings[[m]]$pitAdd[j])*(loadings[[m]]$UDT[j])*sum((1-remainingTwinNoUD)*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$unsafeEmpty[j])
      loadings[[m]]$unsafeDecay_twin[j]<-unsafeDecay_twin_UDT+unsafeDecay_twin_noUDT+unsafeDecay_twin_lime+unsafeDecay_twin_urea

      remainingSingleNoUD<-exp(-kValues["conventional",i]*seq(decayTimeUNSAFE,1,by=-1));remainingSingleNoUD<-replace(remainingSingleNoUD,which(remainingSingleNoUD<0.001),0.001) # this limits onsite pathogen reduction to no more than 3-log reduction
      remainingSingleUD<-exp(-kValues["urine-diverting",i]*seq(decayTimeUNSAFE,1,by=-1));remainingSingleUD<-replace(remainingSingleUD,which(remainingSingleUD<0.001),0.001) # this limits onsite pathogen reduction to no more than 3-log reduction
      remainingSingleLime<-exp(-kValues["conventional w/ lime.urea",i]*seq(decayTimeUNSAFE,1,by=-1));remainingSingleLime<-replace(remainingSingleLime,which(remainingSingleLime<0.001),0.001)
      remainingSingleUrea<-exp(-kValues["urine-diverting w/ lime.urea",i]*seq(decayTimeUNSAFE,1,by=-1));remainingSingleUrea<-replace(remainingSingleUrea,which(remainingSingleUrea<0.001),0.001)
      toSW_sol_sing_noUDT<-loadings[[m]]$singlePits[j]*(1-loadings[[m]]$pitAdd[j])*(1-loadings[[m]]$UDT[j])*sum(remainingSingleNoUD*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$unsafeEmpty[j])
      toSW_sol_sing_UDT<-loadings[[m]]$singlePits[j]*(1-loadings[[m]]$pitAdd[j])*(loadings[[m]]$UDT[j])*sum(remainingSingleUD*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$unsafeEmpty[j])
      toSW_sol_sing_lime<-loadings[[m]]$singlePits[j]*(loadings[[m]]$pitAdd[j])*(1-loadings[[m]]$UDT[j])*sum(remainingSingleNoUD*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$unsafeEmpty[j])
      toSW_sol_sing_urea<-loadings[[m]]$singlePits[j]*(loadings[[m]]$pitAdd[j])*(loadings[[m]]$UDT[j])*sum(remainingSingleUD*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$unsafeEmpty[j])
      loadings[[m]]$toSW_sol_sing[j]<-toSW_sol_sing_UDT+toSW_sol_sing_noUDT+toSW_sol_sing_lime+toSW_sol_sing_urea
      unsafeDecay_sing_noUDT<-loadings[[m]]$singlePits[j]*(1-loadings[[m]]$pitAdd[j])*(1-loadings[[m]]$UDT[j])*sum((1-remainingSingleNoUD)*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$unsafeEmpty[j])
      unsafeDecay_sing_UDT<-loadings[[m]]$singlePits[j]*(1-loadings[[m]]$pitAdd[j])*(loadings[[m]]$UDT[j])*sum((1-remainingSingleUD)*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$unsafeEmpty[j])
      unsafeDecay_sing_lime<-loadings[[m]]$singlePits[j]*(loadings[[m]]$pitAdd[j])*(1-loadings[[m]]$UDT[j])*sum((1-remainingSingleNoUD)*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$unsafeEmpty[j])
      unsafeDecay_sing_urea<-loadings[[m]]$singlePits[j]*(loadings[[m]]$pitAdd[j])*(loadings[[m]]$UDT[j])*sum((1-remainingSingleUD)*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$unsafeEmpty[j])
      loadings[[m]]$unsafeDecay_sing[j]<-unsafeDecay_sing_UDT+unsafeDecay_sing_noUDT+unsafeDecay_sing_lime+unsafeDecay_sing_urea
    }

    loadings[[m]]$toWWTP<-loadings[[m]]$initContained*loadings[[m]]$flushSewer*(1-sewerLeak)

    for(j in 1:13){  # decay for toilets with SAFE emptying practices
      remainingTwinNoUD<-exp(-kValues["conventional",i]*(seq(daysperyear*emptyFrequency,1,by=-1)+daysperyear*emptyFrequency-1));remainingTwinNoUD<-replace(remainingTwinNoUD,which(remainingTwinNoUD<0.001),0.001)
      remainingTwinUD<-exp(-kValues["urine-diverting",i]*(seq(daysperyear*emptyFrequency,1,by=-1)+daysperyear*emptyFrequency-1));remainingTwinUD<-replace(remainingTwinUD,which(remainingTwinUD<0.001),0.001)
      remainingTwinLime<-exp(-kValues["conventional w/ lime.urea",i]*(seq(daysperyear*emptyFrequency,1,by=-1)+daysperyear*emptyFrequency-1));remainingTwinLime<-replace(remainingTwinLime,which(remainingTwinLime<0.001),0.001)
      remainingTwinUrea<-exp(-kValues["urine-diverting w/ lime.urea",i]*(seq(daysperyear*emptyFrequency,1,by=-1)+daysperyear*emptyFrequency-1));remainingTwinUrea<-replace(remainingTwinUrea,which(remainingTwinUrea<0.001),0.001)
      toFSTP_twin_noUDT<-loadings[[m]]$twinPits[j]*(1-loadings[[m]]$pitAdd[j])*(1-loadings[[m]]$UDT[j])*sum(remainingTwinNoUD*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$safeEmpty[j])/emptyFrequency
      toFSTP_twin_UDT<-loadings[[m]]$twinPits[j]*(1-loadings[[m]]$pitAdd[j])*(loadings[[m]]$UDT[j])*sum(remainingTwinUD*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$safeEmpty[j])/emptyFrequency
      toFSTP_twin_lime<-loadings[[m]]$twinPits[j]*(loadings[[m]]$pitAdd[j])*(1-loadings[[m]]$UDT[j])*sum(remainingTwinNoUD*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$safeEmpty[j])/emptyFrequency
      toFSTP_twin_urea<-loadings[[m]]$twinPits[j]*(loadings[[m]]$pitAdd[j])*(loadings[[m]]$UDT[j])*sum(remainingTwinUD*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$safeEmpty[j])/emptyFrequency
      loadings[[m]]$toFSTP_twin[j]<-toFSTP_twin_noUDT+toFSTP_twin_UDT+toFSTP_twin_lime+toFSTP_twin_urea
      safeDecay_twin_noUDT<-loadings[[m]]$twinPits[j]*(1-loadings[[m]]$pitAdd[j])*(1-loadings[[m]]$UDT[j])*sum((1-remainingTwinNoUD)*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$safeEmpty[j])/emptyFrequency
      safeDecay_twin_UDT<-loadings[[m]]$twinPits[j]*(1-loadings[[m]]$pitAdd[j])*(loadings[[m]]$UDT[j])*sum((1-remainingTwinUD)*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$safeEmpty[j])/emptyFrequency
      safeDecay_twin_lime<-loadings[[m]]$twinPits[j]*(loadings[[m]]$pitAdd[j])*(1-loadings[[m]]$UDT[j])*sum((1-remainingTwinNoUD)*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$safeEmpty[j])/emptyFrequency
      safeDecay_twin_urea<-loadings[[m]]$twinPits[j]*(loadings[[m]]$pitAdd[j])*(loadings[[m]]$UDT[j])*sum((1-remainingTwinUD)*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$safeEmpty[j])/emptyFrequency
      loadings[[m]]$safeDecay_twin[j]<-safeDecay_twin_noUDT+safeDecay_twin_UDT+safeDecay_twin_lime+safeDecay_twin_urea

      remainingSingleNoUD<-exp(-kValues["conventional",i]*(seq(daysperyear*emptyFrequency,1,by=-1)));remainingSingleNoUD<-replace(remainingSingleNoUD,which(remainingSingleNoUD<0.001),0.001)
      remainingSingleUD<-exp(-kValues["urine-diverting",i]*(seq(daysperyear*emptyFrequency,1,by=-1)));remainingSingleUD<-replace(remainingSingleUD,which(remainingSingleUD<0.001),0.001)
      remainingSingleLime<-exp(-kValues["conventional w/ lime.urea",i]*(seq(daysperyear*emptyFrequency,1,by=-1)));remainingSingleLime<-replace(remainingSingleLime,which(remainingSingleLime<0.001),0.001)
      remainingSingleUrea<-exp(-kValues["urine-diverting w/ lime.urea",i]*(seq(daysperyear*emptyFrequency,1,by=-1)));remainingSingleUrea<-replace(remainingSingleUrea,which(remainingSingleUrea<0.001),0.001)
      toFSTP_sing_noUDT<-loadings[[m]]$singlePits[j]*(1-loadings[[m]]$pitAdd[j])*(1-loadings[[m]]$UDT[j])*sum(remainingSingleNoUD*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$safeEmpty[j])/emptyFrequency
      toFSTP_sing_UDT<-loadings[[m]]$singlePits[j]*(1-loadings[[m]]$pitAdd[j])*(loadings[[m]]$UDT[j])*sum(remainingSingleUD*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$safeEmpty[j])/emptyFrequency
      toFSTP_sing_lime<-loadings[[m]]$singlePits[j]*(loadings[[m]]$pitAdd[j])*(1-loadings[[m]]$UDT[j])*sum(remainingSingleNoUD*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$safeEmpty[j])/emptyFrequency
      toFSTP_sing_urea<-loadings[[m]]$singlePits[j]*(loadings[[m]]$pitAdd[j])*(loadings[[m]]$UDT[j])*sum(remainingSingleUD*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$safeEmpty[j])/emptyFrequency
      loadings[[m]]$toFSTP_sing[j]<-toFSTP_sing_noUDT+toFSTP_sing_UDT+toFSTP_sing_lime+toFSTP_sing_urea
      safeDecay_sing_noUDT<-loadings[[m]]$singlePits[j]*(1-loadings[[m]]$pitAdd[j])*(1-loadings[[m]]$UDT[j])*sum((1-remainingSingleNoUD)*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$safeEmpty[j])/emptyFrequency
      safeDecay_sing_UDT<-loadings[[m]]$singlePits[j]*(1-loadings[[m]]$pitAdd[j])*(loadings[[m]]$UDT[j])*sum((1-remainingSingleUD)*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$safeEmpty[j])/emptyFrequency
      safeDecay_sing_lime<-loadings[[m]]$singlePits[j]*(loadings[[m]]$pitAdd[j])*(1-loadings[[m]]$UDT[j])*sum((1-remainingSingleNoUD)*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$safeEmpty[j])/emptyFrequency
      safeDecay_sing_urea<-loadings[[m]]$singlePits[j]*(loadings[[m]]$pitAdd[j])*(loadings[[m]]$UDT[j])*sum((1-remainingSingleUD)*loadings[[m]]$inSolid[j]/daysperyear*loadings[[m]]$safeEmpty[j])/emptyFrequency
      loadings[[m]]$safeDecay_sing[j]<-safeDecay_sing_noUDT+safeDecay_sing_UDT+safeDecay_sing_lime+safeDecay_sing_urea
    }

    loadings[[m]]$totalDecayed<-loadings[[m]]$unsafeDecay_twin+loadings[[m]]$unsafeDecay_sing+loadings[[m]]$safeDecay_twin+loadings[[m]]$safeDecay_sing
    loadings[[m]]$toSW<-loadings[[m]]$notContained+loadings[[m]]$toSW_sol_twin+loadings[[m]]$toSW_sol_sing+loadings[[m]]$toSW_liq
    loadings[[m]]$toFSTP<-loadings[[m]]$toFSTP_twin+loadings[[m]]$toFSTP_sing
    loadings[[m]]$stillViable<-loadings[[m]][,"toGW"]+loadings[[m]][,"toSW"]+loadings[[m]][,"toWWTP"]+loadings[[m]][,"toFSTP_twin"]+loadings[[m]][,"toFSTP_sing"]
    loadings[[m]]$LRV_byTech<-round(log10(loadings[[m]][,"excreted"]/loadings[[m]][,"stillViable"]),2)
    loadings[[m]]$LRV_byTech[is.na(loadings[[m]]$LRV_byTech)]<-NA
    #loadings[[m]]$excreted_check<-loadings[[m]]$toGW+loadings[[m]]$toSW+loadings[[m]]$totalSubsurface+loadings[[m]]$totalDecayed+loadings[[m]]$toFSTP+loadings[[m]]$toWWTP
    LRV_byTechnology <- as.data.frame(t(loadings[[m]]$LRV_byTech))
    colnames(LRV_byTechnology) <- paste("LRV_",loadings[[m]]$name,sep="")
    LRV_byTechnology[is.na(LRV_byTechnology)]<-NA

    ### CALCULATE EMISSIONS ###
    excreted=sum(loadings[[m]]$excreted)
    to_groundwater=sum(loadings[[m]]$toGW)
    to_surface=sum(loadings[[m]]$toSW)
    retained_in_soil=sum(loadings[[m]]$totalSubsurface)
    decayed=sum(loadings[[m]]$totalDecayed)
    In_Sewage=sum(loadings[[m]]$toWWTP)
    In_Fecal_Sludge=sum(loadings[[m]]$toFSTP_twin)+sum(loadings[[m]]$toFSTP_sing)
    excreted_check<-sum(to_groundwater,to_surface,retained_in_soil,decayed,In_Sewage,In_Fecal_Sludge)

    loadings[[m]]<-loadings[[m]][,c("name","classification","percentage","excreted","toGW","toSW","totalSubsurface","totalDecayed","toFSTP","toWWTP","stillViable","LRV_byTech")]
    names(loadings[[m]])<-c("id","sanitationTechnology","percentage","excreted","toGroundwater","toSurface","inSubsurface","decayed","fecalSludge","sewerage","stillViable","onsiteLRV")

    newRow<-data.frame(gid=df$gid,excreted,excreted_check,to_groundwater,to_surface,retained_in_soil,decayed,
                       In_Fecal_Sludge,In_Sewage,stillViable=(to_groundwater+to_surface+In_Sewage+In_Fecal_Sludge),
                       Onsite_LRV=round(log10(excreted/(to_groundwater+to_surface+In_Sewage+In_Fecal_Sludge)),2),
                       Onsite_PR=round(((excreted-(to_groundwater+to_surface+In_Sewage+In_Fecal_Sludge))/excreted),4))
    onsite_results=rbind(onsite_results,newRow)
  }

  #return(list(detailed=loadings,summary=onsite_results[complete.cases(onsite_results),]))
  returned<-list(input=df1,
                 det=loadings,
                 output=onsite_results[complete.cases(onsite_results),]
                 )
  return(returned)

}
