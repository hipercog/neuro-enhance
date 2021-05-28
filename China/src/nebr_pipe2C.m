%% Configure pipe 2C
function [Cfg, out] = nebr_pipe2C(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'pipe2C';
    Cfg.srcid = {'pipe1#1_load'...
                 'pipe1#2_denoise'...
                 'pipe1#3_ICA'};
    if isfield(Cfg, 'pipe_src')
        idx = Cfg.pipe_src{ismember(Cfg.pipe_src(:,1), mfilename), 2};
        Cfg.srcid = Cfg.srcid(idx);
    end

    %%%%%%%% Define pipeline %%%%%%%%
    % IC correction
    i = 1;  %stepSet
    stepSet(i).funH = { @CTAP_detect_bad_comps,... %FASTER for non-blinks
                        @CTAP_detect_bad_comps,... %detect blink related ICs
                        @CTAP_reject_data };
%                     CTAP_filter_blink_ica
    stepSet(i).id = [num2str(i) '_IC_FSTrcublk'];

    out.detect_bad_comps = struct(...
        'method', {'faster' 'recu_blink_tmpl'},...
        'match_measures', {{'m' 's' 'k' 'h'} ''},...
        'bounds', {[-2.75 2.75] []},...
        'match_logic', {@any 0});
    
    %%%%%%%% Store to Cfg %%%%%%%%
    if isfield(Cfg, 'pipe_stp')% step sets to run, default: whole thing
        idx = Cfg.pipe_stp{ismember(Cfg.pipe_stp(:,1), mfilename), 2};
        Cfg.pipe.runSets = {stepSet(idx).id};
    else
        Cfg.pipe.runSets = {stepSet(:).id};
    end
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end