%% Configure pipe to perform final bad epoch detection and grand avg export
function [Cfg, out] = nefi_segout(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'segout';
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

    %%%%%%%% Define pipeline %%%%%%%%
    i = 1; %next stepSet
    stepSet(i).funH = { @CTAP_detect_bad_segments,...
                        @CTAP_reject_data };
    stepSet(i).id = [num2str(i) '_badseg_reject'];
    
    % Amplitude thresholding from continuous data (bad segments)
    exclChannels = {[Cfg.eeg.reference(:)',...
                   Cfg.eeg.heogChannelNames(:)',...
                   Cfg.eeg.veogChannelNames(:)',...
                   {'VEOG'}, {'Fp1'}, {'Fp2'}]};
    % channels {'VEOG', 'Fp1', 'Fp2'} are frontal and contain large
    % blinks. They are removed in order to not detect blinks in
    % CTAP_detect_bad_segments().
    out.detect_bad_segments = struct(...
        'badchannels', {exclChannels}, ...
        'normalEEGAmpLimits', [-120, 120]); %in muV

    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.stepSets = stepSet;
    Cfg.pipe.runSets = {stepSet(:).id};
end