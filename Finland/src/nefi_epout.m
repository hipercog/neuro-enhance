%% Configure pipe to perform final bad epoch detection and grand avg export
function [Cfg, out] = nefi_epout(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'epout';
    Cfg.srcid= {'pipe1#pipe2A#pipe3A#1_chan_corr_vari'...
                'pipe1#pipe2A#pipe3B#1_chan_corr_maha'...
                'pipe1#pipe2B#pipe3A#1_chan_corr_vari'...
                'pipe1#pipe2B#pipe3B#1_chan_corr_maha'...
                'pipe1#pipe2C#pipe3A#1_chan_corr_vari'...
                'pipe1#pipe2C#pipe3B#1_chan_corr_maha'};
    if isfield(Cfg, 'pipe_src')
        idx = Cfg.pipe_src{ismember(Cfg.pipe_src(:,1), mfilename), 2};
        Cfg.srcid = Cfg.srcid(idx);
    end
    

    %%%%%%%% Define contingent parameters %%%%%%%%
    time = [[-100 500];%parameterise this in case needs changed later
            [-100 500];
            [-100 500]];
    evty = {{'sound_NO' 'pic_'};
            {'dur' 'freq1' 'freq2' 'gap' 'int' 'loc1' 'loc2' 'novel' 'stand'};
            {'std1' 
            'std_aft1' 
            'std_aft2' 
            'std_aft3' 
            'Cat_A_S1_Cat_V'
            'Cat_A_S1_Dog_V'
            'Cat_A_S2_Cat_V'
            'Cat_A_S2_Dog_V'
            'Dog_A_S1_Cat_V'
            'Dog_A_S1_Dog_V'
            'Dog_A_S2_Cat_V'
            'Dog_A_S2_Dog_V'}'};
    match = {'starts' 'exact' 'exact'};
    pix = contains({'AV' 'Multi' 'Swi'}, Cfg.MC.export_name_root(end - 2:end - 1));
    

    %%%%%%%% Define pipeline %%%%%%%%
    i = 1; %next stepSet
    stepSet(i).funH = { @CTAP_epoch_data,...
                        @CTAP_detect_bad_epochs,...
                        @CTAP_reject_data };
    stepSet(i).id = [num2str(i) '_epoch'];
    
    i = i + 1; %next stepSet
    stepSet(i).funH = repmat({@CTAP_export_data}, 1, numel(evty{pix}));
    stepSet(i).id = [num2str(i) '_export'];
    stepSet(i).save = false;

    out.epoch_data = struct(...
        'method', 'epoch',...
        'match',  match{pix},...
        'timelim', time(pix, :),...
        'evtype', evty(pix));
    
    out.detect_bad_epochs = struct(...
        'channels', {{'F3' 'Fz' 'F4' 'C3' 'Cz' 'C4' 'P3' 'Pz' 'P4'}},...
        'method', 'eegthresh',...
        'uV_thresh', [-120 120]);
    
    out.export_data = struct(...
        'type', 'mul',...
        'outdir', fullfile('exportRoot', 'MUL_EXPORT'),...
        'lock_event', evty{pix});


    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.stepSets = stepSet;
    Cfg.pipe.runSets = {stepSet(1).id};
end