%% Configure pipe for peeking at other pipe outputs
function [Cfg, out] = nebr_peekpipe(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'peekpipe';
    Cfg.srcid = {'pipe1#1_load'};
%         ...
%                 'pipe1#pipe2A#1_artifact_correction'... 
%                 'pipe1#pipe2B#1_artifact_correction'};

    %%%%%%%% Define pipeline %%%%%%%%
    i = 1; %next stepSet
    stepSet(i).funH = { @CTAP_peek_data };
    stepSet(i).id = [num2str(i) '_final_peek'];
    stepSet(i).save = false;

    out.peek_data = struct(...
        'secs', [10 30],... %start few seconds after data starts
        'peekStats', true,... %get statistics for each peek!
        'overwrite', false,...
        'plotAllPeeks', false,...
        'savePeekData', true,...
        'savePeekICA', true);

    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.stepSets = stepSet;
    Cfg.pipe.runSets = {stepSet(:).id};
end