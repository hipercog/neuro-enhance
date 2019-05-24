%% Configure pipe 1
function [Cfg, out] = neav_pipe1(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'pipe1';
    Cfg.srcid = {''};

    %%%%%%%% Define pipeline %%%%%%%%
    % Load
    i = 1; %stepSet 1
    stepSet(i).funH = { @CTAP_load_data,... 
                        @CTAP_clock_start,...
                        @CTAP_select_evdata,...
                        @CTAP_resample_data,...
                        @CTAP_load_chanlocs,...
                        @CTAP_reref_data,...
                        @CTAP_fir_filter,...
                        @CTAP_blink2event,...
                        @CTAP_fir_filter };
    stepSet(i).id = [num2str(i) '_load'];

    i = i+1; %stepSet 2
    stepSet(i).funH = { @CTAP_detect_bad_channels,...%given bad channels
                        @CTAP_reject_data,...
                        @CTAP_interp_chan,...
                        @CTAP_detect_bad_segments,...
                        @CTAP_reject_data };
    stepSet(i).id = [num2str(i) '_denoise'];    

    i = i+1; %stepSet 3
    stepSet(i).funH = { @CTAP_run_ica };
    stepSet(i).id = [num2str(i) '_ICA'];

    out.select_evdata = struct(...
        'covertype', 'total');
    
    out.resample_data = struct(...
        'newsrate', 250);
    
    out.load_chanlocs = struct(...
        'overwrite', true,...
        'index_match', false);
    % write EEG type for all channels, and then overwrite a subset as EOG
    out.load_chanlocs.field = {{{'all'} 'type' 'EEG'}...
        {{'E25' 'E127' 'E8' 'E126' 'E14' 'E21' 'E125' 'E128'} 'type' 'EOG'}};
% EGI - RECOMMENDED CHANNELS 
%Left upper-lower: 'E25' 'E127'
%Right upper-lower: 'E8' 'E126'
%Above inner canthi: 'E14' 'E21'
%Near outer canthi: 'E125' 'E128'

     out.fir_filter = struct(...
        'locutoff', {0.5 []},...
        'hicutoff', {[] 30},...
        'filtorder', {3380 226});

    [p, ~, ~] = fileparts(mfilename('fullpath'));
    out.detect_bad_channels = struct(...
         'method', 'given',...
         'badChanCsv', fullfile(p, '..', '..', 'res', ['badchans_' Cfg.T '.txt']));

    out.interp_chan = struct('missing_types', 'EEG');
    
    out.detect_bad_segments = struct(...
        'coOcurrencePrc', 0.15,... %require 15% chans > AmpLimits
        'normalEEGAmpLimits', [-150, 150]); %in muV

    out.blink2event = struct(...
        'classMethod', 'emgauss_asymmetric');

    out.run_ica = struct(...
        'method', 'fastica',...
        'overwrite', true);
    out.run_ica.channels = {'EEG' 'EOG'};


    %%%%%%%% Store to Cfg %%%%%%%%
    if isfield(Cfg, 'pipe_stp')% step sets to run, default: whole thing
        idx = Cfg.pipe_stp{ismember(Cfg.pipe_stp(:,1), mfilename), 2};
        Cfg.pipe.runSets = {stepSet(idx).id};
    else
        Cfg.pipe.runSets = {stepSet(:).id};
    end
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end