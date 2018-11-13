%% Configure pipe 3B - bad channel correction
function [Cfg, out] = nefi_pipe3B(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'pipe3B';
    Cfg.srcid = {'pipe1#pipe2A#1_ICcor_ADJblk'... 
                 'pipe1#pipe2B#1_IC_corr_FSTR'};

    %%%%%%%% Define pipeline %%%%%%%%
    % IC correction
    i = 1;  %stepSet
    stepSet(i).funH = { @CTAP_detect_bad_channels,...%bad channels by Mahalanobis
                        @CTAP_reject_data,...
                        @CTAP_interp_chan };
    stepSet(i).id = [num2str(i) '_chan_corr_maha'];

    out.detect_bad_channels = struct(...
        'method', 'maha_fast',...
        'factorVal', 2.8,...
        'channelType', {'EEG'});
    
    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end
