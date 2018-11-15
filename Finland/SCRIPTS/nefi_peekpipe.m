%% Configure pipe for peeking at other pipe outputs
function [Cfg, out] = nefi_peekpipe(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'peekpipe';
    Cfg.srcid = {'pipe1#1_load'...
                'pipe1#pipe2A#1_ICcor_ADJblk'... 
                'pipe1#pipe2B#1_IC_corr_FSTR'...
                'pipe1#pipe2A#pipe3A#1_chan_corr_vari'...
                'pipe1#pipe2A#pipe3B#1_chan_corr_maha'...
                'pipe1#pipe2B#pipe3A#1_chan_corr_vari'...
                'pipe1#pipe2B#pipe3B#1_chan_corr_maha'};

    %%%%%%%% Define pipeline %%%%%%%%
    i = 1; %next stepSet
    stepSet(i).funH = { @CTAP_peek_data };
    stepSet(i).id = [num2str(i) '_final_peek'];
    stepSet(i).save = false;

    out.peek_data = struct(...
        'secs', [1 30],... %start few seconds after data starts
        'peekStats', true,... %get statistics for each peek!
        'overwrite', true,...
        'plotAllPeeks', true,...
        'savePeekData', true,...
        'savePeekICA', true);

    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.stepSets = stepSet;
    Cfg.pipe.runSets = {stepSet(:).id};
end