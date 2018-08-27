%% Configure pipe 2A
function [Cfg, out] = nebr_pipe2A(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'pipe2A';
    Cfg.srcid = {'pipe1#1_load'};

    %%%%%%%% Define pipeline %%%%%%%%
    % IC correction
    i = 1;  %stepSet
    stepSet(i).funH = { @CTAP_detect_bad_comps,... %ADJUST for horiz eye moves
                        @CTAP_reject_data,...
                        @CTAP_detect_bad_comps,... %detect blink related ICs
                        @CTAP_filter_blink_ica };
    stepSet(i).id = [num2str(i) '_IC_correction'];

    out.detect_bad_comps = struct(...
        'method', {'adjust' 'blink_template'},...
        'adjustarg', {'horiz' ''});
    
    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end