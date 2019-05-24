%% Debug script for branching CTAP of NEURO-ENHANCE Chinese PRE- POST-test data

%% Setup MAIN parameters
% set the input directory where your data is stored
% proj_root = fullfile('E:\', 'PROJECT_NEUROENHANCE', 'China');
% proj_root = 'D:\UH\data_analysis\school_intervention_study_data\EEG_data\3-105030102';
proj_root = '/media/bcowley/Transcend/project_NEUROENHANCE/China';
group_dir = {'control' 'english' 'music'};
para_dir = 'AV';

% use ctapID to uniquely name the base folder of the output directory tree
ctapID = {'pre' 'post'};

%Select pipe array and first and last pipe to run
pipeArr = {@neav_pipe1,... 
           @nebr_pipe2C,...
           @nebr_pipe3B,... 
           @nebr_epout,...
           @nebr_peekpipe};


%% Runtime options for CTAP:
%You can also run only a subset of pipes, e.g. 2:length(pipeArr)
runps = [1];

STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;

%Choose groups & use sbj_filt to select all or some of available recordings
gix = 1;
grpXsbj_filt = {'all' 'all' 'all'}; %setdiff(1:12, [3 7]);

%PICK YOUR TIMEPOINT HERE! PRE or POST...
timept = 1;
    
%You can parameterize the sources for each pipe [1 4 6 7 9]
pipe_src = [cellfun(@func2str, pipeArr, 'un', 0)', {NaN 1 3 6 10}'];

            
%% Use runtime options
group_dir = group_dir(gix);
grpXsbj_filt = grpXsbj_filt(gix);
ctapID = ctapID{timept};


%% Loop the available data sources
for ix = 1:numel(group_dir)
    %Create the CONFIGURATION struct
    %First, define important paths; plus step sets and their parameters
    [Cfg, ~] = neav_cfg(proj_root, group_dir{ix}, para_dir, ctapID);
    Cfg.pipe_src = pipe_src;

    %Then create measurement config (MC) based on a directory and filetype
    % - subselect subjects using numeric or name indexing in 'sbj_filt'
    % - name the session/group, and the measurement/condition (pass cells)
    sbj_filt = grpXsbj_filt{ix};
    Cfg = get_meas_cfg_MC(Cfg, Cfg.env.paths.branchSource...
                , 'eeg_ext',   Cfg.eeg.data_type, 'sbj_filt', sbj_filt...
                , 'session', group_dir(ix), 'measurement', {para_dir});
    Cfg.MC.export_name_root = sprintf('%d_%s_%s_', timept...
        , upper(group_dir{ix}(1:3)), para_dir);

    % Run the pipe
    tic
        CTAP_pipeline_brancher(Cfg, pipeArr, 'runPipes', runps...
                    , 'dbg', STOP_ON_ERROR, 'ovw', OVERWRITE_OLD_RESULTS)
    toc
end

clear
