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
%   subjfilt    vector | cell array, list of subjects by ID number or string
%               default = all
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
srcix = {NaN 3 3 6 [1 4 10]};
stpix = {1:3 1 1 1:2 1};
       
       
%% Setup MAIN parameters
p = inputParser;
p.addRequired('proj_root', @ischar)

p.addParameter('grpix', 1:numel(group_dir), @(x) any(x == 1:numel(group_dir)))
p.addParameter('subjfilt', {'all'}, @(x) iscell(x) || isvector(x))
p.addParameter('timept', 1:2, @isvector)
p.addParameter('runps', 1:length(pipeArr), @(x) all(ismember(x, 1:length(pipeArr))))
p.addParameter('pipesrc', srcix, @(x) iscell(x) && numel(x) == numel(srcix))
p.addParameter('pipestp', stpix, @(x) iscell(x) && numel(x) == numel(stpix))

p.parse(proj_root, varargin{:});
Arg = p.Results;

            
%% Use runtime options
group_dir = group_dir(Arg.grpix);
pipe_src = [cellfun(@func2str, pipeArr, 'un', 0)', Arg.pipesrc'];
pipe_stp = [cellfun(@func2str, pipeArr, 'un', 0)', Arg.pipestp'];
runps = Arg.runps;
sbj_filt = Arg.subjfilt;
ctapID = ctapID(Arg.timept);


%% Loop the available data sources
parfor (ix = 1:numel(group_dir) * numel(ctapID))
    
    %get sub-index S from global index G
    %First is group index:
    grix = mod(ix, numel(group_dir)) + 1;
    %Second is pre/post index
    idix = mod(ix, numel(ctapID)) + 1;
    
    ctapid = ctapID{idix};
    grpdir = group_dir{grix};
    %Create the CONFIGURATION struct
    %First, define important paths; plus step sets and their parameters
    [Cfg, ~] = neav_cfg(proj_root, grpdir, para_dir, ctapid);
    Cfg.pipe_src = pipe_src;
    Cfg.pipe_stp = pipe_stp;

    %Then create measurement config (MC) based on a directory and filetype
    % - name the session/group, and the measurement/condition (pass cells)
    Cfg = get_meas_cfg_MC(Cfg, Cfg.env.paths.branchSource...
                            , 'eeg_ext',   Cfg.eeg.data_type...
                            , 'sbj_filt', sbj_filt...
                            , 'session', {grpdir}...
                            , 'measurement', {para_dir});
    Cfg.MC.export_name_root = sprintf('%d_%s_%s_'...
                                    , idix...
                                    , upper(grpdir(1:3))...
                                    , para_dir);

    % Run the pipe
    tic
        CTAP_pipeline_brancher(Cfg, pipeArr, 'runPipes', runps, 'ovw', true)
    toc
end

clear
