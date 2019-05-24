function [Cfg, out] = neav_cfg(project_root_folder, group_dir, para_dir, ID)
%NEBR_CFG Return configuration structure

    %% Fixed path options
    data_dir = {'BEI_PRETEST' 'BEI_POSTEST'};
    data_dir = data_dir{contains(data_dir, ID, 'IgnoreCase', true)};
    anal_dir = 'ANALYSIS';
    
    % Analysis branch ID
    Cfg.id = ['neuroenhance_bei_AV_' ID];
    Cfg.srcid = {''};
    Cfg.env.paths.projectRoot = project_root_folder;

    % Define important directories and files
    Cfg.env.paths.branchSource = fullfile(Cfg.env.paths.projectRoot...
        , data_dir, group_dir, para_dir); 

    Cfg.env.paths.analysisRoot = fullfile(Cfg.env.paths.projectRoot, anal_dir);

    Cfg.env.paths.ctapRoot = fullfile(Cfg.env.paths.analysisRoot, Cfg.id);

    % Channel location file
    [p, ~, ~] = fileparts(mfilename('fullpath'));
    Cfg.eeg.chanlocs = ...
        fullfile(p, '..', '..', 'res', 'EGI_chanlocs', '2_9AverageNet128_v1.sfp');

    % specify the file type of your data
    Cfg.eeg.data_type = '*.raw';

    % Define other important stuff
    Cfg.eeg.reference = { 'average'};

    % NOTE! EOG channel specification for artifact detection purposes.
    Cfg.eeg.heogChannelNames = {'E125' 'E128'};
    Cfg.eeg.veogChannelNames = {'E14' 'E126'};

    % dummy var
    out = struct([]);
end