function neuroenhance_branch_fin(proj_root, varargin)
%% Branching CTAP script to clean NEURO-ENHANCE Finnish PRE- POST-test data
%
% Syntax:
%   On the Matlab console, execute >> neuroenhance_branch_bei
% 
% Inputs:
%   proj_root   string, path to data: see example_starter.m for examples
% Varargin:
%   grpix       vector, group index to include, default = 1:3
%   parix       vector, paradigm index to include, default = 1:4
%   timept      scalar, time point (pre-or post-test) to attack, default = 1
%   runps       vector, pipes to run, default = all of them
%   pipesrc     cell array, sources for each pipe, 
%                           default = {NaN 1 1 1 1:3 1:3 1:6 1:6 1:10}
% 
%
% Version History:
% 01.09.2018 Created (Benjamin Cowley, UoH)
%
% Copyright(c) 2018:
% Benjamin Cowley (Ben.Cowley@helsinki.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


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


%% Setup MAIN parameters
p = inputParser;
p.addRequired('proj_root', @ischar)
p.addParameter('grpix', 1:4, @(x) any(x == 1:4))
p.addParameter('parix', 1:3, @(x) any(x == 1:3))
p.addParameter('timept', 1, @(x) x == 1 || x == 2)
p.addParameter('runps', 1:length(pipeArr), @(x) any(x == 1:length(pipeArr)))
p.addParameter('pipesrc', {NaN 1 1 1 1:3 1:3 1:6 1:6 1:10}, @iscell)

p.parse(proj_root, varargin{:});
Arg = p.Results;


%% Runtime options for CTAP:
STOP_ON_ERROR = false;
OVERWRITE_OLD_RESULTS = true;

%You can parameterize the sources for each pipe
pipe_src = [cellfun(@func2str, pipeArr, 'un', 0)', Arg.pipesrc'];

%Set timepoint here: PRE or POST...
ctapID = ctapID{Arg.timept};

%Subsetting groups and paradigms
group_dir = group_dir(Arg.grpix);
grp_short_name = grp_short_name(Arg.grpix);
para_dir = para_dir(Arg.parix);
par_short_name = par_short_name(Arg.parix);


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
