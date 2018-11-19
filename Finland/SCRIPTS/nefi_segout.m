%% Configure pipe to perform final bad epoch detection and grand avg export
function [Cfg, out] = nefi_segout(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'segout';
    Cfg.srcid = {'pipe1#pipe2A#pipe3A#1_chan_corr_vari'};

    %%%%%%%% Define pipeline %%%%%%%%
    i = 1; %next stepSet
    stepSet(i).funH = { @CTAP_detect_bad_segments,...
                        @CTAP_export_data };
    stepSet(i).id = [num2str(i) '_badseg_export'];
    
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
        'normalEEGAmpLimits', [-75, 75]); %in muV
    
%     out.peek_data = struct(...
%         'secs', [1 30],... %start few seconds after data starts
%         'peekStats', true,... %get statistics for each peek!
%         'overwrite', true,...
%         'plotAllPeeks', true,...
%         'savePeekData', true,...
%         'savePeekICA', true);

    out.export_data = struct(...
        'type', 'mul',...
        'outdir', fullfile(Cfg.env.paths.ctapRoot, 'MUL_EXPORT'));

    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.stepSets = stepSet;
    Cfg.pipe.runSets = {stepSet(:).id};
end