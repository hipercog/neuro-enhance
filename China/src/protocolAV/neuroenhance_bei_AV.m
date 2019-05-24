function neuroenhance_bei_AV(proj_root, varargin)
%% CTAP script to clean NEURO-ENHANCE Chinese AV PRE- POST-test data
%
% Syntax:
%   On the Matlab console, execute >> neuroenhance_bei_AV
% 
% Inputs:
%   proj_root   string, path to data: see example_starter.m for examples
% Varargin:
%   grpix       vector, group index to include: control/english/music, 
%               default = 1:3
%   timept      scalar, time point to attack: pre-test / post-test,
%               default = 1
%   runps       vector, pipes to run, 
%               default = all of them
%   pipesrc     cell array, sources for each pipe - to override default you 
%                           must provide as many cells of source vectors as
%                           you have pipes; easiest is to copy+modify default
%                           default = {NaN 1 3 6 [1 4 10]}
%   pipestp     cell array, steps for each pipe - to override default you 
%                           must provide as many cells of source vectors as
%                           you have pipes; easiest is to copy+modify default
%                           default = {1:3 1 1 1:2 1}
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
%You can parameterize the sources for each pipe
srcix = {NaN 1 3 6 [1 4 10]};
stpix = {1:3 1 1 1:2 1};
       
       
%% Setup MAIN parameters
p = inputParser;
p.addRequired('proj_root', @ischar)
p.addParameter('grpix', 1:numel(group_dir), @(x) any(x == 1:numel(group_dir)))
p.addParameter('timept', 1, @(x) x == 1 || x == 2)
p.addParameter('runps', 1:length(pipeArr), @(x) all(ismember(x, 1:length(pipeArr))))
p.addParameter('pipesrc', srcix, @(x) iscell(x) && numel(x) == numel(srcix))
p.addParameter('pipestp', stpix, @(x) iscell(x) && numel(x) == numel(stpix))

p.parse(proj_root, varargin{:});
Arg = p.Results;
% set the input directory where your data is stored
% proj_root = fullfile('E:\', 'PROJECT_NEUROENHANCE', 'China');
% proj_root = 'D:\UH\data_analysis\school_intervention_study_data\EEG_data\3-105030102';
% proj_root = '/media/bcowley/Transcend/project_NEUROENHANCE/China';

            
%% Use runtime options
group_dir = group_dir(Arg.grpix);
ctapID = ctapID{Arg.timept};
pipe_src = [cellfun(@func2str, pipeArr, 'un', 0)', Arg.pipesrc'];
pipe_stp = [cellfun(@func2str, pipeArr, 'un', 0)', Arg.pipestp'];


%% Loop the available data sources
for ix = 1:numel(group_dir)
    %Create the CONFIGURATION struct
    %First, define important paths; plus step sets and their parameters
    [Cfg, ~] = neav_cfg(proj_root, group_dir{ix}, para_dir, ctapID);
    Cfg.pipe_src = pipe_src;
    Cfg.pipe_stp = pipe_stp;

    %Then create measurement config (MC) based on a directory and filetype
    % - name the session/group, and the measurement/condition (pass cells)
    Cfg = get_meas_cfg_MC(Cfg, Cfg.env.paths.branchSource...
                , 'eeg_ext',   Cfg.eeg.data_type...
                , 'session', group_dir(ix), 'measurement', {para_dir});
    Cfg.MC.export_name_root = sprintf('%d_%s_%s_', Arg.timept...
                                    , upper(group_dir{ix}(1:3)), para_dir);

    % Run the pipe
    tic
        CTAP_pipeline_brancher(Cfg, pipeArr, 'runPipes', Arg.runps...
                                           , 'dbg', false, 'ovw', true)
    toc
end

clear
