%% Configure pipe 2B
function [Cfg, out] = nebr_pipe2B(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'pipe2B';
    Cfg.srcid = {'pipe1#1_load'};

    %%%%%%%% Define pipeline %%%%%%%%
    % IC correction
    i = 1;  %stepSet
    stepSet(i).funH = { @CTAP_detect_bad_comps,... %FASTER bad IC detection
                        @CTAP_reject_data };
    stepSet(i).id = [num2str(i) '_IC_correction'];

    out.detect_bad_comps = struct(...
        'method', 'faster',...
        'bounds', [-2.5 2.5],...
        'match_logic', @any);
    
    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
    Cfg.pipe.stepSets = stepSet; % record of all step sets
end
