function neuroenhance_branch_fin(grpix, parix, timept, runps, pipesrc)
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
%   * NeuroEnhance repo,
%       git clone https://github.com/zenBen/neuro-enhance.git
% 
% # 2
% Set your working directory to CTAP root (wherever you cloned CTAP)
% 
% # 3
% Add EEGLAB and CTAP to your Matlab path. For a script to do this see
% update_matlab_path_ctap.m at CTAP repository root
% 
% # 4
% Set up a directory to contain the data files:
%   * EEG datasets (BrainAmp .eeg format) from NeuroEnhance Finland pre/post-test
% Pass the complete path to this directory into the variable 'proj_root', below
% 
% # 5
% On the Matlab console, execute >> neuroenhance_branch_fin
    

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
grp_short_name = {'Mov' 'Con' 'Mus' 'MMo'};
par_short_name = {'AV' 'Multi' 'Swi'};

% use ctapID to uniquely name the base folder of the output directory tree
ctapID = {'pre' 'post'};

%Dfine pipe array
pipeArr = {@nefi_pipe1,...
           @nefi_pipe2A,...
           @nefi_pipe2B,...
           @nefi_pipe2C,...
           @nefi_pipe3A,...
           @nefi_pipe3B,...
           @nefi_epout,...
           @nefi_segcheck,...
           @nefi_peekpipe};


%% Runtime options for CTAP:
STOP_ON_ERROR = false;
OVERWRITE_OLD_RESULTS = true;

%You can parameterize the sources for each pipe
if nargin < 5, pipesrc = {NaN 1 1 1 1:3 1:3 1:6 1:6 1:10}; end
pipe_src = [cellfun(@func2str, pipeArr, 'un', 0)', pipesrc'];

%You can run only a subset of pipes, e.g. 2:length(pipeArr)
if nargin < 4, runps = 1:length(pipeArr); end

%PICK YOUR TIMEPOINT HERE! PRE or POST...
if nargin < 3, timept = 1; end
ctapID = ctapID{timept};

%Subsetting groups and paradigms
if nargin < 2, parix = 1:3; end
if nargin < 1, grpix = 1:4; end
group_dir = group_dir(grpix);
grp_short_name = grp_short_name(grpix);
para_dir = para_dir(parix);
par_short_name = par_short_name(parix);


%% Loop the available data sources
% Use non-nested loop for groups X protocols; allows parfor parallel processing
parfor (ix = 1:numel(group_dir) * numel(para_dir))
    %get sub-index S from global index G by allcomb()
    A = allcomb(1:numel(group_dir), 1:numel(para_dir));
    %First is group index:
    gix = A(ix, 1);
    %Second is protocol index
    pix = A(ix, 2);

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
    Cfg.MC.export_name_root =...
        sprintf('%d_%s_%s_', timept, grp_short_name{gix}, par_short_name{pix});

    % Run (and time) the pipe
    tic
        CTAP_pipeline_brancher(Cfg, pipeArr, 'runPipes', runps...
                , 'dbg', STOP_ON_ERROR, 'ovw', OVERWRITE_OLD_RESULTS)
    toc

end

end %neuroenhance_branch_fin()
