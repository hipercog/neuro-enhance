function neuroenhance_debug_fin()
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
           @nefi_segout,...
           @nefi_peekpipe};

% use sbj_filt to select all (or a subset) of available recordings
grpXsbj_filt = {'all' 'all' 168 'all'}; %setdiff(1:12, [3 7]);


%% Runtime options for CTAP:
%You can also run only a subset of pipes, e.g. 2:length(pipeArr)
runps = 9;

PREPRO = true;
STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = false;

%Subsetting groups and paradigms
gix = 3;
pix = 2:3;
group_dir = group_dir(gix);
grpXsbj_filt = grpXsbj_filt(gix);
para_dir = para_dir(pix);

%PICK YOUR TIMEPOINT HERE! PRE or POST...
timept = 1;
ctapID = ctapID{timept};
    
%You can parameterize the sources for each pipe
pipe_src = [cellfun(@func2str, pipeArr, 'un', 0)'...
                , {NaN 1 1 1 1:3 1:3 1:6 1:6 1:10}'];


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
    grp = group_dir(gix);
    [Cfg, ~] = nefi_cfg(proj_root, grp{1}, para_dir{pix}, ctapID);
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

end %neuroenhance_branch_dev()
