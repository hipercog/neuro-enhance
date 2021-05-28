function [Cfg, out] = nefi_cfg(project_root_folder, group_dir, para_dir, ID)
%NEBR_CFG Return configuration structure

    %% Fixed path options
    data_dir = {'FIN_PRETEST' 'FIN_POSTEST'};
    idx = find(contains(data_dir, ID(1:3), 'IgnoreCase', true));
    data_dir = data_dir{idx};
    anal_dir = 'ANALYSIS';

    % Analysis branch ID
    Cfg.id = ['neuroenhance_fin_' ID];
    Cfg.srcid = {''};
    Cfg.env.paths.projectRoot = project_root_folder;

    % Define important directories and files
    Cfg.env.paths.branchSource = fullfile(Cfg.env.paths.projectRoot...
                , data_dir, sprintf('Data_%d', idx), group_dir, para_dir);
    Cfg.env.paths.logFiles = fullfile(Cfg.env.paths.projectRoot...
                , data_dir, sprintf('Logfiles_%d', idx), group_dir, para_dir);
    Cfg.env.paths.analysisRoot = fullfile(Cfg.env.paths.projectRoot, anal_dir);
    Cfg.env.paths.ctapRoot = fullfile(Cfg.env.paths.analysisRoot, Cfg.id);

    % Channel location file
    [p, ~, ~] = fileparts(mfilename('fullpath'));
    Cfg.eeg.chanlocs = ...
            fullfile(p, '..', 'res', 'acticap_chanlocs', 'myacticap32.ced');

    % specify the file type of your data
    Cfg.eeg.data_type = '*.vhdr';

    % Define preferred reference channel
    Cfg.eeg.reference = {'LM' 'RM'};

    % NOTE! EOG channel specification for artifact detection purposes
    Cfg.eeg.veogChannelNames = {'VEOG'};
    Cfg.eeg.heogChannelNames = {'Fp1' 'Fp2'};

    % dummy var
    out = struct([]);
end