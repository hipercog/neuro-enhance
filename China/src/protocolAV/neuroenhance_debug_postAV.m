%% CTAP script to clean NEURO-ENHANCE Chinese AV POST-test data

% set the input directory where your data is stored
% proj_root = fullfile('E:\', 'PROJECT_NEUROENHANCE', 'China');
% proj_root = 'D:\UH\data_analysis\school_intervention_study_data\EEG_data\3-105030102';
% proj_root = '/media/bcowley/Transcend/project_NEUROENHANCE/China';

group_dir = 'control';
para_dir = 'AV';
ctapID = 'post';
sbj_filt = [105020111, 105030216, 105030308];

%Select pipe array and first and last pipe to run
pipeArr = {@neav_pipe1,... 
           @nebr_pipe2C,...
           @nebr_pipe3B,... 
           @nebr_epout,...
           @nebr_peekpipe};

%You can parameterize the pipes/steps to run, and sources for each pipe
runps = 1:length(pipeArr);
pipe_src = [cellfun(@func2str, pipeArr, 'un', 0)', {NaN 3 3 6 [1 4 10]}'];
pipe_stp = [cellfun(@func2str, pipeArr, 'un', 0)', {1:3 1 1 1:2 1}'];

%Create the CONFIGURATION struct
%First, define important paths; plus step sets and their parameters
[Cfg, ~] = neav_cfg(proj_root, group_dir, para_dir, ctapID);
Cfg.pipe_src = pipe_src;
Cfg.pipe_stp = pipe_stp;

%Then create measurement config (MC) based on a directory and filetype
% - name the session/group, and the measurement/condition (pass cells)
Cfg = get_meas_cfg_MC(Cfg, Cfg.env.paths.branchSource...
						, 'eeg_ext',   Cfg.eeg.data_type...
						, 'sbj_filt', sbj_filt...
						, 'session', {group_dir}...
						, 'measurement', {para_dir});
Cfg.MC.export_name_root = sprintf('%d_%s_%s_'...
								, 2 ...
								, upper(group_dir(1:3))...
								, para_dir);

% Run the pipe
tic
	CTAP_pipeline_brancher(Cfg, pipeArr, 'runPipes', runps, 'ovw', true)
toc

clear
