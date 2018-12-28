%% Debug script for branching CTAP of NEURO-ENHANCE Finnish PRE- POST-test data

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
grp_short_name = {'Mov' 'Con' 'Mus' 'MMo'};
par_short_name = {'AV' 'Multi' 'Swi'};

% use ctapID to uniquely name the base folder of the output directory tree
ctapID = {'pre' 'post'};

%Select pipe array and first and last pipe to run
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
%You can also run only a subset of pipes, e.g. 2:length(pipeArr)
runps = 1;%[5:6 9];

STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;

%Subsetting groups and paradigms
gix = 2;
pix = 2;
% use sbj_filt to select all (or a subset) of available recordings
bad_preslog_con_mul = [101 104 106:109 163:165 172];
grpXsbj_filt = {130:134 bad_preslog_con_mul 'all' 'all'}; %setdiff(1:12, [3 7]);

%PICK YOUR TIMEPOINT HERE! PRE or POST...
timept = 2;
    
%You can parameterize the sources for each pipe
pipe_src = [cellfun(@func2str, pipeArr, 'un', 0)'...
                , {NaN 1 1 1 1:3 1:3 1:6 1:6 1:10}'];

            
%% Use runtime options
group_dir = group_dir(gix);
grpXsbj_filt = grpXsbj_filt(gix);
grp_short_name = grp_short_name(gix);
para_dir = para_dir(pix);
par_short_name = par_short_name(pix);
ctapID = ctapID{timept};


%% Loop the available data sources
for ix = 1:numel(group_dir) * numel(para_dir)
    %get sub-index S from global index G by Matlab's combvec
    A = allcomb(1:numel(group_dir), 1:numel(para_dir));
    %First is group index:
    gix = A(ix, 1);
    %Second is protocol index
    pix = A(ix, 2);

    %Create the CONFIGURATION struct
    %First, define important paths; plus step sets and their parameters
    [Cfg, ~] = nefi_cfg(proj_root, group_dir{gix}, para_dir{pix}, ctapID);
    Cfg.pipe_src = pipe_src;

    %Then create measurement config (MC) based on a directory and filetype
    % - subselect subjects using numeric or name indexing in 'sbj_filt'
    % - name the session/group, and the measurement/condition (pass cells)
    sbj_filt = grpXsbj_filt{gix};
    Cfg = get_meas_cfg_MC(Cfg, Cfg.env.paths.branchSource...
                , 'eeg_ext', Cfg.eeg.data_type, 'sbj_filt', sbj_filt...
                , 'session', group_dir(gix), 'measurement', para_dir(pix));
    Cfg.MC.export_name_root =...
        sprintf('%d_%s_%s_', timept, grp_short_name{gix}, par_short_name{pix});

    % Run the pipe
    tic
        CTAP_pipeline_brancher(Cfg, pipeArr, 'runPipes', runps...
                    , 'dbg', STOP_ON_ERROR, 'ovw', OVERWRITE_OLD_RESULTS)
    toc
end

clear