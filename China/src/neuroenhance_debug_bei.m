function neuroenhance_debug_bei()
%% Branching CTAP script to clean NEURO-ENHANCE Chinese PRE-test data

%% Setup MAIN parameters
% set the input directory where your data is stored
linux = '~/Benslab';
pc3 = 'D:\LocalData\bcowley';
if isunix % Code to run on Linux platform
    proj_root = fullfile(linux, 'PROJECT_NEUROENHANCE', 'China');
elseif ispc % Code to run on Windows platform
    proj_root = fullfile(pc3, 'PROJECT_NEUROENHANCE', 'China');
else
    disp('Platform not supported')
end
group_dir = {'control' 'english' 'music'};
para_dir = {'attention' 'AV' 'multiMMN' 'musmelo'};

% use ctapID to uniquely name the base folder of the output directory tree
ctapID = {'pre' 'post'};

%Select pipe array and first and last pipe to run
pipeArr = {@nebr_pipe1,...
           @nebr_pipe2A,...
           @nebr_pipe2B,...
           @nebr_pipe2C,...
           @nebr_pipe3A,...
           @nebr_pipe3B,...
           @nebr_epout,...
           @nebr_segcheck,...
           @nebr_peekpipe};


%% RUNTIME OPTIONS for CTAP:
PREPRO = true;
STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = false;

%You can also run only a subset of pipes, e.g. 2:length(pipeArr)
runps = [1:6 8 9];

ctapID = ctapID{1};

% use sbj_filt to select all (or a subset) of available recordings
grpXsbj_filt = {'all' 'all' 'all'}; %setdiff(1:12, [3 7]);

pipe_src = ...
    [cellfun(@func2str, pipeArr, 'un', 0)', {NaN 1 1 1 1:3 1:3 1:6 1:6 1:10}'];
group_dir = group_dir(1);
para_dir = para_dir(1:4);


%% Loop the available data sources
for ix = 1:numel(group_dir) * numel(para_dir)
    %get sub-index S from global index G by Matlab's combvec
    A = allcomb(1:numel(group_dir), 1:numel(para_dir));
    %First is group index:
    gix = A(1, ix);
    %Second is protocol index
    pix = A(2, ix);
    
    %Create the CONFIGURATION struct
    %First, define important paths; plus step sets and their parameters
    [Cfg, ~] = nebr_cfg(proj_root, group_dir{gix}, para_dir{pix}, ctapID);
    Cfg.pipe_src = pipe_src;

    %Then create measurement config (MC) based on a directory and filetype
    % - subselect subjects using numeric or name indexing in 'sbj_filt'
    % - name the session/group, and the measurement/condition (pass cells)
    sbj_filt = grpXsbj_filt{gix};
    Cfg = get_meas_cfg_MC(Cfg, Cfg.env.paths.branchSource...
                , 'eeg_ext', Cfg.eeg.data_type, 'sbj_filt', sbj_filt...
                , 'session', group_dir(gix), 'measurement', para_dir(pix));

    % Run the pipe
    tic
        CTAP_pipeline_brancher(Cfg, pipeArr, 'runPipes', runps...
                    , 'dbg', STOP_ON_ERROR, 'ovw', OVERWRITE_OLD_RESULTS)
    toc
end

end %neuroenhance_debug_bei()
