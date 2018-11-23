function neuroenhance_branch_fin()
%% Branching CTAP script to clean NEURO-ENHANCE Finnish PRE- POST-test data
%
% OPERATION STEPS
% # 1
% Download + Install:
%   * Matlab R2016b or newer
%   * EEGLAB, latest version,
%       git clone https://adelorme@bitbucket.org/sccn_eeglab/eeglab.git
%   * CTAP,
%       git clone https://github.com/bwrc/ctap.git

% # 2
% Set your working directory to CTAP root (wherever you cloned CTAP)

% # 3
% Add EEGLAB and CTAP to your Matlab path. For a script to do this see
% update_matlab_path_ctap.m at CTAP repository root: the directory containing
% 'ctap' and 'dependencies' folders.

% # 4
% Set up a directory to contain the data files:
%   * EEG datasets (BrainAmp .eeg format) from NeuroEnhance Beijing pre-test
% Pass the complete path to this directory into the variable 'proj_root', below

% # 5
% On the Matlab console, execute >> neuroenhance_branch_dev


%% Setup MAIN parameters
% set the input directory where your data is stored
linux = {'~/Benslab', fullfile(filesep, 'media', 'ben', 'Transcend')};
pc3 = 'D:\LocalData\bcowley';
if isunix
    % Code to run on Linux platform
    proj_root = fullfile(linux{2}, 'PROJECT_NEUROENHANCE', 'Finland', '');
elseif ispc
    % Code to run on Windows platform
    proj_root = fullfile(pc3, 'PROJECT_NEUROENHANCE', 'Finland', '');
else
    disp('Platform not supported')
end
group_dir = {'A_movement' 'B_control' 'C_music' 'D_musicmove'};
para_dir = {'AV' 'multiMMN' 'switching'};
% group_dir = group_dir(1);
para_dir = para_dir(2);

% use ctapID to uniquely name the base folder of the output directory tree
ctapID = {'pre' 'post'};
ctapID = ctapID{1};%PICK YOUR TIMEPOINT HERE! PRE or POST...

% use sbj_filt to select all (or a subset) of available recordings
grpXsbj_filt = {[] [] [] []}; %setdiff(1:12, [3 7]);

% Runtime options for CTAP:
DEBUG = false;
PREPRO = true;
STOP_ON_ERROR = false;
OVERWRITE_OLD_RESULTS = true;


%% Loop the available data sources
% Use non-nested loop for groups X protocols; allows parfor parallel processing
if DEBUG
  parforArg = 0;
else
  parforArg = Inf;
end
% parfor (ix = 1:numel(group_dir) * numel(para_dir), parforArg)
for ix = 1:numel(group_dir) * numel(para_dir)
    %get sub-index S from global index G by modulo. Loop order is not as for 
    %nested loops, but parfor mixes order anyway. First is group index:
    gix = mod(ix - 1, numel(group_dir)) + 1;
    if parforArg == 0
        sbj_filt = grpXsbj_filt{gix}; %%#ok<PFBNS>
    else
        sbj_filt = [];
    end
    %Second is protocol index
    pix = mod(ix - 1, numel(para_dir)) + 1;

    %Create the CONFIGURATION struct
    %First, define important paths; plus step sets and their parameters
    grp = group_dir(gix);
    [Cfg, ~] = nefi_cfg(proj_root, grp{1}, para_dir{pix}, ctapID);

    %Then create measurement config (MC) based on a directory and filetype
    % - subselect subjects using numeric or name indexing in 'sbj_filt'
    % - name the session/group, and the measurement/condition (pass cells)
    Cfg = get_meas_cfg_MC(Cfg, Cfg.env.paths.branchSource...
                , 'eeg_ext', Cfg.eeg.data_type, 'sbj_filt', sbj_filt...
                , 'session', group_dir(gix), 'measurement', para_dir(pix));

    %Select pipe array and first and last pipe to run
    pipeArr = {@nefi_pipe1,...
               @nefi_pipe2A,...
               @nefi_pipe2B,...
               @nefi_pipe3A,...
               @nefi_pipe3B,...
               @nefi_peekpipe,...
               @nefi_epout,...
               @nefi_segout};
    runps = 7:8;
    %You can also run only a subset of pipes, e.g. 2:length(pipeArr)


    %% Run the pipe
    if PREPRO
        tic %#ok<*UNRCH>
        CTAP_pipeline_brancher(Cfg, pipeArr, 'runPipes', runps...
                    , 'dbg', STOP_ON_ERROR, 'ovw', OVERWRITE_OLD_RESULTS)
        toc
    end


    %% Finally, compare pre-post improvements of stats for each branch
    % ...use CTAP_postproc_brancher helper function to rebuild branching
    % tree of paths to the export directories??
%     CTAP_postproc_brancher(Cfg, @dynamic_func, {'name', value}...
%                     , 'runPipes', runps...
%                     , 'dbg', STOP_ON_ERROR)

%     end
end

%cleanup the global workspace
clear PREPRO STOP_ON_ERROR OVERWRITE_OLD_RESULTS sbj_filt pipeArr first last

end %neuroenhance_branch_dev()
