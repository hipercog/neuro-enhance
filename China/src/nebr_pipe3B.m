%% Configure pipe 3B - bad channel correction
function [Cfg, out] = nebr_pipe3B(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'pipe3B';
    Cfg.srcid = {'pipe1#pipe2A#1_ICcor_ADJblk'... 
                 'pipe1#pipe2B#1_IC_corr_FSTR'...
                 'pipe1#pipe2C#1_IC_FSTrcublk'};
    if isfield(Cfg, 'pipe_src')
        idx = Cfg.pipe_src{ismember(Cfg.pipe_src(:,1), mfilename), 2};
        Cfg.srcid = Cfg.srcid(idx);
    end

    %%%%%%%% Define pipeline %%%%%%%%
    % IC correction
    i = 1;  %stepSet
    stepSet(i).funH = { @CTAP_detect_bad_channels,...%bad channels by Mahalanobis
                        @CTAP_reject_data,...
                        @CTAP_interp_chan };
    stepSet(i).id = [num2str(i) '_chan_corr_maha'];

    out.detect_bad_channels = struct(...
        'method', 'maha_fast',...
        'factorVal', 2.8);

    out.interp_chan = struct('missing_types', 'EEG');
    
    %%%%%%%% Store to Cfg %%%%%%%%
    if isfield(Cfg, 'pipe_stp')% step sets to run, default: whole thing
        idx = Cfg.pipe_stp{ismember(Cfg.pipe_stp(:,1), mfilename), 2};
        Cfg.pipe.runSets = {stepSet(idx).id};
    else
        Cfg.pipe.runSets = {stepSet(:).id};
    end
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end
