ICA_dir='G:\Data_from_China\music_group\melody_paradigm\1-group\ICA_comp_rmv\'; %Change this
output_path='G:\Data_from_China\music_group\melody_paradigm\1-group\erp\'; %Change this
cd(ICA_dir);
files=dir('*.set');
files={files.name};

for i = 1:length(files)
    %This command loads the data to eeglab
    EEG = pop_loadset('filename',files{i},'filepath', ICA_dir);
    
    %automatic artefact detection and rejection
    EEG = pop_eegthresh(EEG,1,EEG.icachansind ,-100,100,EEG.xmin,EEG.xmax,0,1);
    %interpolating bad channels
    EEG = pop_interp(EEG,[setdiff(1:EEG.nbchan,EEG.icachansind)],'spherical');
    
    EEG = pop_saveset( EEG, 'filename',[files{i}(1:end-4) '.set'],'filepath',output_path);
    
    EEG = pop_loadset('filename',files{i},'filepath', output_path); 
    
    %creating average ERPs
    ERP = pop_averager( EEG, 'Criterion', 'all', 'ExcludeBoundary', 'off', 'SEM' , 'on');
    
    ERP.erpname = [files{i}(1:end-4) '_ERP'];  % name for erpset menu
    pop_savemyerp(ERP, 'erpname', ERP.erpname, 'filename', [ERP.erpname '.erp'], 'filepath', output_path, 'warning', 'off');
end
