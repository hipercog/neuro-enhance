% EEGLAB history file generated on the 09-Feb-2018
% ------------------------------------------------

EEG.etc.eeglabvers = '14.1.2'; % this tracks which version of EEGLAB is being used, you may ignore it
EEG = pop_readegi('G:\Data_from_China\music_group\melody_paradigm\1-group\105020101-melody_20170826_024045.raw', [],[],'auto');
EEG = eeg_checkset( EEG );
EEG=pop_chanedit(EEG, 'load',{'G:\\Data_from_China\\EGI-System_locationFile\\2_9AverageNet128_v1.sfp' 'filetype' 'sfp'});
EEG = eeg_checkset( EEG );
