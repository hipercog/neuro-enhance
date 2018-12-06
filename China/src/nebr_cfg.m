function [Cfg, out] = nebr_cfg(project_root_folder, group_dir, para_dir, ID)
%NEBR_CFG Return configuration structure

    %% Fixed path options
    data_dir = {'CHINA_PRETEST' 'CHINA_POSTEST'};
    data_dir = data_dir{contains(data_dir, ID, 'IgnoreCase', true)};
    anal_dir = 'ANALYSIS';
    
    % Analysis branch ID
    Cfg.id = ['neuroenhance_bei_' ID];
    Cfg.srcid = {''};
    Cfg.env.paths.projectRoot = project_root_folder;

    % Define important directories and files
    Cfg.env.paths.branchSource = fullfile(Cfg.env.paths.projectRoot...
        , data_dir, group_dir, para_dir); 

    Cfg.env.paths.analysisRoot = fullfile(Cfg.env.paths.projectRoot, anal_dir);

    Cfg.env.paths.ctapRoot = fullfile(Cfg.env.paths.analysisRoot, Cfg.id);

    % get path to csv files of trial indices per musmelo feature, e.g. rhythm
    Cfg.env.paths.musmelo_trial_index_csv =...
        fullfile('SCRIPTS', 'musmelo_trial_indices');

    % Channel location file
    [p, ~, ~] = fileparts(mfilename('fullpath'));
    Cfg.eeg.chanlocs = ...
        fullfile(p, '..', 'res', 'EGI_chanlocs', '2_9AverageNet128_v1.sfp');

    % specify the file type of your data
    Cfg.eeg.data_type = '*.raw';

    % Define other important stuff
    Cfg.eeg.reference = {'E57' 'E100'};

    % NOTE! EOG channel specification for artifact detection purposes.
    Cfg.eeg.heogChannelNames = {'E1' 'E33'};
    Cfg.eeg.veogChannelNames = {'E14' 'E126'};

    % dummy var
    out = struct([]);
end