library(Rtools)
library(tidyverse)
library(plotly)

#TODO: pre post comparison

#choose channels 
channels <- c('Fz','Cz')
#pre or post
pre_post <- 'pre'
protocol <- 'AV'


#TODO: make automagic
#pipes
branches <- expand.grid(c('A','B','C'), c('A','B'))
pipes <- mapply(function(a,b)sprintf('pipe1/pipe2%s/pipe3%s',a,b),branches[,1], branches[,2])
pipe <- pipes[1]

#source folder
#folder <- file.path('E:/PROJECT_NEUROENHANCE/Finland/ANALYSIS',pre_post,pipe,paste0('epout/this/export/HDF5_EXPORT_',protocol))
folder <- file.path('~/EEG19/R_data/PROJECT_NEUROENHANCE/Finland/ANALYSIS',paste0('neuroenhance_fin_',pre_post),pipe,paste0('epout/this/export/HDF5_EXPORT_',protocol))


fsplits <- strsplit(folder,'/')
path_info <- paste(fsplits[[1]][5:8], collapse="/") 
folder_info <- paste(fsplits[[1]][1:10], collapse="/") 


savedir_loc <- file.path(folder_info, 'gavg_plots', protocol) #local
dir.create(savedir_loc, showWarnings = F, recursive = T)


#get list of files in folder
h5_file_list <- list.files(folder, full.names = T)

#get contents of files
#set element (erp or erpavg)
element <- '/erpavg' #avg for each subject
eeg <- loadfl.h5(h5_file_list, element)


#melt into plottable format
melt.erp.lst <- function(erpLst){
  #  erpLst <- lapply(erpLst, function(dmat){dmat[channels,]}) #select only some channels
  erpLst <- simplify2array(erpLst) #to array
  names(dimnames(erpLst)) <- c('channel','time','ds') #name dimensions
  pd <- reshape2::melt(erpLst) %>% #to long data.frame, makes srings into factors
    mutate(ds = as.character(ds)) 
  pd$ds <- pd$ds %>% str_replace_all(c('loc1' = 'loc', 'loc2' = 'loc',
                                       'freq1' = 'freq', 'freq2' = 'freq'))  
  if (protocol %in% c('Swi','ATTE')) {  
    pd <- pd %>%
    group_by(ds) %>%
    mutate(ds_base = ifelse(startsWith(basename(ds),'2_'),str_remove(basename(ds), '2_'), basename(ds))) %>%  #modify ds because posttest files have prefix '2_'
    mutate(erpid = ifelse(strsplit(ds_base,'_')[[1]][6] %in% c('std'), strsplit(ds_base,'_')[[1]][6], paste0(strsplit(ds_base,'_')[[1]][6:7], collapse="")),
           group = strsplit(ds_base,'_')[[1]][4]) %>% 
    group_by(group, channel, time, erpid, ds_base) %>%
    summarise(value = mean(value)) %>%
    ungroup %>%
      filter(channel %in% channels)
  
  } else if (protocol %in% c('MUSM')) {
    pd <- pd %>%
      group_by(ds) %>%
      mutate(ds_base = ifelse(startsWith(basename(ds),'2_'),str_remove(basename(ds), '2_'), basename(ds))) %>%  #modify ds because posttest files have prefix '2_'
      mutate(erpid = paste0(strsplit(ds_base,'_')[[1]][6:7], collapse=""),
             group = strsplit(ds_base,'_')[[1]][4]) %>% 
      group_by(group, channel, time, erpid, ds_base) %>%
      summarise(value = mean(value)) %>%
      ungroup %>%
      mutate(erpid = str_remove(erpid, 'ERPdata.h5')) %>%
      filter(channel %in% channels)
  
  } else {
    pd <- pd %>%
      group_by(ds) %>%
      mutate(ds_base = ifelse(startsWith(basename(ds),'2_'),str_remove(basename(ds), '2_'), basename(ds))) %>%  #modify ds because posttest files have prefix '2_'
      mutate(erpid = strsplit(ds_base,'_')[[1]][6],
             group = strsplit(ds_base,'_')[[1]][4]) %>% 
      group_by(group, channel, time, erpid, ds_base) %>%
      summarise(value = mean(value)) %>%
      ungroup %>%
      filter(!startsWith(erpid,'pic'), channel %in% channels)
  }
  pd
}


pd <- melt.erp.lst(eeg)

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

