%% Configure pipe to perform final bad epoch detection and grand avg export
function [Cfg, out] = nefi_epout(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'epochexpout';
    Cfg.srcid = {'pipe1#pipe2A#pipe3A#1_chan_corr_vari'};

    %%%%%%%% Define pipeline %%%%%%%%
    i = 1; %next stepSet
    stepSet(i).funH = { @CTAP_epoch_data,...
                        @CTAP_detect_bad_epochs,...
                        @CTAP_peek_data,...
                        @CTAP_export_data };
    stepSet(i).id = [num2str(i) '_epoch_export'];

    out.epoch_data = struct();
    
    out.detect_bad_epochs = struct();
    
    out.export_data = struct();
    
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