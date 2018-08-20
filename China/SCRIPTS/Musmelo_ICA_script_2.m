% Clear memory and the command window
clear;
clc;

preproc_data_path='G:\Data_from_China\music_group\melody_paradigm\1-group\art_rmv\'; %write here the full path to the folder with the raw data you want to preprocess e.g. don't forget the '' and /
cd(preproc_data_path); %sets the above folder as the current folder
output_path ='G:\Data_from_China\music_group\melody_paradigm\1-group\ICA\'; %write here the full path to the folder where you want to save the filtered and epoched data
files=dir('*.set');
files={files.name};

load('G:\Data_from_China\music_group\melody_paradigm\1-group\bad_channels.mat');

for i = 1:length(files)
    %loading dataset
    EEG = pop_loadset('filename',[files{i}],'filepath', preproc_data_path);
    %select necessary channels
    %EEG = pop_select( EEG,'channel',{'A1' 'A2' 'A3' 'A4' 'A5' 'A6' 'A7' 'A8' 'A9' 'A10' 'A11' 'A12' 'A13' 'A14' 'A15' 'A16' 'A17' 'A18' 'A19' 'A20' 'A21' 'A22' 'A23' 'A24' 'A25' 'A26' 'A27' 'A28' 'A29' 'A30' 'A31' 'A32' 'B1' 'B2' 'B3' 'B4' 'B5' 'B6' 'B7' 'B8' 'B9' 'B10' 'B11' 'B12' 'B13' 'B14' 'B15' 'B16' 'B17' 'B18' 'B19' 'B20' 'B21' 'B22' 'B23' 'B24' 'B25' 'B26' 'B27' 'B28' 'B29' 'B30' 'B31' 'B32'});
    %setting channels locations
    %EEG=pop_chanedit(EEG, 'load',{'G:\Musmelo_data_IH16\musmelo_16.elp', 'filetype', 'autodetect'});
    
    %selecting the 'good channels' - running ICA on the good channels only
    good_channels=setdiff(1:126,bad_channels{i,2});
    %run ICA
    EEG = pop_runica(EEG, 'extended',1,'interupt','on','chanind',good_channels); 
    
    EEG = pop_saveset( EEG, 'filename',[files{i}(1:end-4) '.set'],'filepath',output_path);
end