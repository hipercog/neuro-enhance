library(Rtools)
library(tidyverse)
library(plotly)

#TODO: pre post comparison

#choose channels 
channels <- c('Fz')
#pre or post
##pre_post <- 'pre'
phases <- c('pre', 'post')
protocol <- 'AV'
deviants <- c('std', 'novel')

#TODO: make automagic
#pipes
branches <- expand.grid(c('A','B','C'), c('A','B'))
pipes <- mapply(function(a,b)sprintf('pipe1/pipe2%s/pipe3%s',a,b),branches[,1], branches[,2])
pipe <- pipes[1]

read_eeg <- function(phase) { 
  #folder <- file.path('E:/PROJECT_NEUROENHANCE/Finland/ANALYSIS',pre_post,pipe,paste0('epout/this/export/HDF5_EXPORT_',protocol))
  folder <- file.path('~/EEG19/R_data/PROJECT_NEUROENHANCE/Finland/ANALYSIS',paste0('neuroenhance_fin_',phase),pipe,paste0('epout/this/export/HDF5_EXPORT_',protocol))
  
  fsplits <- strsplit(folder,'/')
  path_info <- paste(fsplits[[1]][5:8], collapse="/") 
  #folder_info <- paste(fsplits[[1]][1:10], collapse="/") 
  folder_info <- paste(fsplits[[1]][1:6], collapse="/") 
  
  savedir_loc <<- file.path(folder_info, 'gavg_plots', protocol) #local
  
  #get list of files in folder
  h5_file_list <- list.files(folder, full.names = T)
  
  #get contents of files
  #set element (erp or erpavg)
  element <- '/erpavg' #avg for each subject
  eeg <- loadfl.h5(h5_file_list, element)
  eeg
}

#melt into plottable format
melt.erp.lst <- function(erpLst){
  #  erpLst <- lapply(erpLst, function(dmat){dmat[channels,]}) #select only some channels
  erpLst <- simplify2array(erpLst) #to array
  names(dimnames(erpLst)) <- c('channel','time','ds') #name dimensions
  pd <- reshape2::melt(erpLst) %>% #to long data.frame, makes strings into factors
    mutate(ds = as.character(ds)) 
  pd$ds <- pd$ds %>% str_replace_all(c('loc1' = 'loc', 'loc2' = 'loc',
                                       'freq1' = 'freq', 'freq2' = 'freq'))  
  if (protocol %in% c('Swi','ATTE')) {  
    pd <- pd %>% 
      mutate(phase = ifelse(grepl('pre',ds[1]), 'pre', 'post')) %>%
      group_by(ds) %>% 
      mutate(ds_base = ifelse(startsWith(basename(ds),'2_'),str_remove(basename(ds), '2_'), basename(ds))) %>%  #modify ds because posttest files have prefix '2_'
      mutate(erpid = ifelse(strsplit(ds_base,'_')[[1]][6] %in% c('std'), strsplit(ds_base,'_')[[1]][6], paste0(strsplit(ds_base,'_')[[1]][6:7], collapse="")),
             group = strsplit(ds_base,'_')[[1]][4]) %>% 
      mutate(ds_base = sub("\\_.*", "", ds_base)) %>%
      group_by(group, channel, time, erpid, ds_base) %>%
      summarise(value = mean(value)) %>%
      ungroup %>%
      filter(channel %in% channels) %>%
      droplevels()
    
  } else if (protocol %in% c('MUSM')) {
    pd <- pd %>%
      mutate(phase = ifelse(grepl('pre',ds[1]), 'pre', 'post')) %>%
      group_by(ds) %>%
      mutate(ds_base = ifelse(startsWith(basename(ds),'2_'),str_remove(basename(ds), '2_'), basename(ds))) %>%  #modify ds because posttest files have prefix '2_'
      mutate(erpid = paste0(strsplit(ds_base,'_')[[1]][6:7], collapse=""),
             group = strsplit(ds_base,'_')[[1]][4]) %>% 
      mutate(ds_base = sub("\\_.*", "", ds_base)) %>%
      group_by(group, channel, time, erpid, ds_base) %>%
      summarise(value = mean(value)) %>%
      ungroup %>%
      mutate(erpid = str_remove(erpid, 'ERPdata.h5')) %>%
      filter(channel %in% channels) %>%
      droplevels()
    
  } else {
    pd <- pd %>%
      mutate(phase = ifelse(grepl('pre',ds[1]), 'pre', 'post')) %>%
      group_by(ds) %>% 
      mutate(ds_base = ifelse(startsWith(basename(ds),'2_'),str_remove(basename(ds), '2_'), basename(ds))) %>%  #modify ds because posttest files have prefix '2_'
      mutate(erpid = strsplit(ds_base,'_')[[1]][6],
             group = strsplit(ds_base,'_')[[1]][4]) %>% 
      mutate(ds_base = sub("\\_.*", "", ds_base)) %>%
      group_by(phase, group, channel, time, erpid, ds_base) %>%
      summarise(value = mean(value)) %>%
      ungroup %>%
      filter(!startsWith(erpid,'pic'), channel %in% channels) %>%
      droplevels()
  }
  pd
}


#bind pre and post if needed
if (length(phases) == 1) { 
  eeg <- read_eeg(phases[1])
  pd <- melt.erp.lst(eeg)
} else if (length(phases) == 2) {
  eeg_pre <- read_eeg(phases[1])
  pd_pre <- melt.erp.lst(eeg_pre)
  eeg_post <- read_eeg(phases[2])
  pd_post <- melt.erp.lst(eeg_post)
  pd <- rbind(pd_pre, pd_post)
}


plot_difference <- function(pd) { 
  
  c <- unique(pd$channel)   
  
  titlestr = sprintf('GA ERPs and difference curves at %s', c)
  
  ga_diff <- pd %>%
    filter(erpid %in% deviants,
           phase %in% phases,
           channel %in% channels) %>%
    spread(erpid, value) %>%
    mutate(difference = novel - std) %>%
    gather(var, value, novel, std, difference) %>%
    group_by(phase, time, channel, var) %>%
    mutate(n = n()) %>%
    ungroup %>%
    mutate(phase = factor(paste0(phase, ' (n=',n,')')) %>% fct_rev()) %>%
    #  mutate(var2 = ifelse(var %in% c('pre', 'post'), 'phase', 'diff')) %>% #linetype variable
    filter(!is.na(value)) %>%
    ggplot(aes(time, value)) +
    stat_summary(fun.data = mean_cl_boot, #bootstrapped 95% CIs, default B=1000
                 geom = "ribbon", size = 1, aes(fill = var),alpha = 0.3)+
    guides(fill = "none", linetype = "none") +
    stat_summary(fun.y = mean,geom = "line",size = 1,aes(colour = var)) + #calculate mean here
    labs(x = "Time (ms)",y = "Amplitude", #expression(paste("Amplitude (",mu,"V)")), #TODO: mu in plotly
         colour = "", title = titlestr) +
    geom_vline(xintercept = 0,linetype = "longdash" )+
    geom_hline(yintercept = 0,linetype = "longdash") +
    scale_linetype_manual("", values=c("dashed", "solid")) +
    scale_color_manual("", values = c("black", "#619CFF", "#F8766D")) +
    scale_fill_manual("", values = c("darkgrey", "#619CFF", "#F8766D")) +
    scale_y_reverse() +
    theme_bw() +
    facet_wrap(~phase)
  
  
  erpids <- paste0(unique(pd$erpid),collapse="_")
  savefile <- file.path(savedir_loc, sprintf('GAERP_%s.html', paste0(c(phases, deviants, channels), collapse="_")))
  dir.create(savedir_loc, showWarnings = F, recursive = T)
  gp <- ggplotly(ga_diff)
  htmlwidgets::saveWidget(gp, savefile)
  #ggsave(file=savefile, plot=ga, width=10, height=8)
  
  # 
}
# 
plot_difference(pd)

#####################
#grand average, individual ERPs
gapd_ind <- pd %>%
  group_by(group, channel, time, erpid) %>%
  mutate(n=n(), # n = number of subjects
         mean=mean(value)
  ) %>% 
  ungroup() %>%
  filter(erpid %in% c('novel', 'std')) #TODO: for other protocols

#TODO: make gapd_ind an argument
plots_groups <- function(c) { # c = channel 
  
  titlestr = sprintf('GA ERP, %s, %s', c, pipe)
  
  #create plot
  ga <-  gapd_ind %>%
    filter(channel == c) %>%
    mutate(group = paste0(group, ' (N_sbj=', n, ')')) %>%
    ggplot(aes(time, mean, color=erpid, group=ds_base)) + geom_line(size=1, alpha=.8) +
    facet_wrap(~group) +
    geom_vline(aes(xintercept=0), alpha=.6, linetype="longdash") +
    geom_line(aes(time, value, color=erpid), alpha=.4) +
    scale_y_reverse() +
    theme_bw() +
    labs(title = titlestr,
         y = "amplitude",
         x = "time (ms)") #modify legend text
  
  erpids <- paste0(unique(gapd_ind$erpid),collapse="_")
  savefile <- file.path(savedir_loc, sprintf('GAERP_%s_%s.html', erpids, c))
  #pipename <- paste(strsplit(pipe, '/')[[1]], collapse="")
  #savefile <- file.path(savedir_loc, sprintf('GAERP_%s_%s.png', c,pipename))
  gp <- ggplotly(ga)
  htmlwidgets::saveWidget(gp, savefile)
  
  #ggsave(file=savefile, plot=ga, width=10, height=8)
  # 
}
# 
plots <- lapply(channels, plots_groups)

