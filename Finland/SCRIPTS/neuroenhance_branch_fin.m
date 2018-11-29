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
%define collection of groups and paradigms
group_dir = {'A_movement' 'B_control' 'C_music' 'D_musicmove'};
para_dir = {'AV' 'multiMMN' 'switching'};

% use ctapID to uniquely name the base folder of the output directory tree
ctapID = {'pre' 'post'};

% Runtime options for CTAP:
STOP_ON_ERROR = false;
OVERWRITE_OLD_RESULTS = true;
%Subsetting groups and paradigms
group_dir = group_dir(1);
para_dir = para_dir(2);
ctapID = ctapID{1};%PICK YOUR TIMEPOINT HERE! PRE or POST...

%Select pipe array and first and last pipe to run
pipeArr = {@nefi_pipe1,...
           @nefi_pipe2A,...
           @nefi_pipe2B,...
           @nefi_pipe2C,...
           @nefi_pipe3A,...
           @nefi_pipe3B,...
           @nefi_epout,...
           @nefi_segout,...
           @nefi_peekpipe};
%You can also run only a subset of pipes, e.g. 2:length(pipeArr)
runps = 8;

%You can parameterize the sources for each pipe
pipe_src = [cellfun(@func2str, pipeArr, 'un', 0)'...
                , {NaN 1 1 1 1:3 1:3 6 1:6 1:10}'];


%% Loop the available data sources
% Use non-nested loop for groups X protocols; allows parfor parallel processing
parfor (ix = 1:numel(group_dir) * numel(para_dir))
    %get sub-index S from global index G by modulo. Loop order is not as for 
    %nested loops, but parfor mixes order anyway. First is group index:
    gix = mod(ix - 1, numel(group_dir)) + 1;
    %Second is protocol index
    pix = mod(ix - 1, numel(para_dir)) + 1;

    %Create the CONFIGURATION struct
    %First, define important paths; plus step sets and their parameters
    grp = group_dir(gix);
    [Cfg, ~] = nefi_cfg(proj_root, grp{1}, para_dir{pix}, ctapID);
    Cfg.pipe_src = pipe_src;

    %Then create measurement config (MC) based on a directory and filetype
    % - subselect subjects using numeric or name indexing in 'sbj_filt'
    % - name the session/group, and the measurement/condition (pass cells)
    Cfg = get_meas_cfg_MC(Cfg, Cfg.env.paths.branchSource...
                , 'eeg_ext', Cfg.eeg.data_type...
                , 'session', group_dir(gix), 'measurement', para_dir(pix));

    % Run (and time) the pipe
    tic %#ok<*UNRCH>
        CTAP_pipeline_brancher(Cfg, pipeArr, 'runPipes', runps...
                , 'dbg', STOP_ON_ERROR, 'ovw', OVERWRITE_OLD_RESULTS)
    toc

end

%cleanup the global workspace
clear STOP_ON_ERROR OVERWRITE_OLD_RESULTS sbj_filt pipeArr runps gix pix grp

end %neuroenhance_branch_dev()
