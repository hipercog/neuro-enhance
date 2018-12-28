%% Configure pipe to perform final bad epoch detection and grand avg export
function [Cfg, out] = nefi_segcheck(Cfg)

    %%%%%%%% Define hierarchy %%%%%%%%
    Cfg.id = 'segcheck';
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
    stepSet(i).save = false;
    
    % Amplitude thresholding from continuous data (bad segments)
    out.detect_bad_segments = struct(...
        'channels', {{'F3' 'Fz' 'F4' 'C3' 'Cz' 'C4' 'P3' 'Pz' 'P4'}},...
        'coOcurrencePrc', 0.01,...
        'normalEEGAmpLimits', [-120, 120]); %in muV

    %%%%%%%% Store to Cfg %%%%%%%%
    Cfg.pipe.stepSets = stepSet;
    Cfg.pipe.runSets = {stepSet(:).id};
end