%% Branching CTAP script to clean NEURO-ENHANCE Chinese PRE-test data
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
%   * 483 EEG datasets (EGI .raw format) from NeuroEnhance Beijing pre-test
% Pass the complete path to this directory into the variable 'proj_root', below

% # 5
% On the Matlab console, execute >> neuroenhance_branch_dev


%% Setup MAIN parameters
% set the input directory where your data is stored
proj_root = '~/Benslab/PROJECT_NEUROENHANCE/China';
group_dir = {'music' 'english' 'control'};%order from Chinese bkgrd data labels
para_dir = {'attention' 'AV' 'multiMMN' 'musmelo'};

% use ctapID to uniquely name the base folder of the output directory tree
ctapID = 'neuroenhance_branch_test';

% use sbj_filt to select all (or a subset) of available recordings
sbj_filt = []; %setdiff(1:12, [3 7]);

% set the electrode for which to calculate and plot ERPs after preprocessing
erploc = {'A31'};

% Runtime options for CTAP:
PREPRO = true;
STOP_ON_ERROR = true;
OVERWRITE_OLD_RESULTS = true;


%% Loop the available data sources
% for gix = 1:numel(group_dir)
%     for pix = 1:numel(para_dir)
%DEBUG:
gix = 3; pix = 3;

        %Create the CONFIGURATION struct
        %First, define important paths; plus step sets and their parameters
        [Cfg, ~] = nebr_cfg(proj_root, group_dir{gix}, para_dir{pix}, ctapID);

        %Then create measurement config (MC) based on a directory and filetype
        % - subselect subjects using numeric or name indexing in 'sbj_filt'
        % - name the session/group, and the measurement/condition (pass cells)
        Cfg = get_meas_cfg_MC(Cfg, Cfg.env.paths.branchSource...
                    , 'eeg_ext', Cfg.eeg.data_type, 'sbj_filt', sbj_filt...
                    , 'session', group_dir(gix), 'measurement', para_dir(pix));

        %Select pipe array and first and last pipe to run
        pipeArr = {@nebr_pipe1,...
                   @nebr_pipe2A,...
                   @nebr_pipe2B,...
                   @nebr_peekpipe};
        runps = [1 4];
        %You can also run only a subset of pipes, e.g. 2:length(pipeArr)


        %% Run the pipe
        if PREPRO
            tic %#ok<*UNRCH>
            CTAP_pipeline_brancher(Cfg, pipeArr, 'runPipes', runps...
                        , 'dbg', STOP_ON_ERROR, 'ovw', OVERWRITE_OLD_RESULTS)
            toc
        end


        %% Finally, obtain ERPs of known conditions from the processed data
        % ...use CTAP_postproc_brancher helper function to rebuild branching
        % tree of paths to the export directories??
        % CTAP_postproc_brancher(Cfg, @dynamic_func, {'loc_label', erploc}...
        %                 , pipeArr, 'first', first, 'last', last...
        %                 , 'dbg', STOP_ON_ERROR)

%     end
% end

%cleanup the global workspace
clear PREPRO STOP_ON_ERROR OVERWRITE_OLD_RESULTS sbj_filt pipeArr first last


%% Subfunctions

% %% Return configuration structure
% function [Cfg, out] = sbf_cfg(project_root_folder, ID)
% 
%     % Analysis branch ID
%     Cfg.id = ID;
%     Cfg.srcid = {''};
%     Cfg.env.paths.projectRoot = project_root_folder;
% 
%     % Define important directories and files
%     Cfg.env.paths.branchSource = ''; 
%     Cfg.env.paths.ctapRoot = fullfile(Cfg.env.paths.projectRoot, Cfg.id);
%     Cfg.env.paths.analysisRoot = Cfg.env.paths.ctapRoot;
% 
%     % Channel location file
%     Cfg.eeg.chanlocs = Cfg.env.paths.projectRoot;
% 
%     % Define other important stuff
%     Cfg.eeg.reference = {'average'};
% 
%     % NOTE! EOG channel specification for artifact detection purposes.
%     Cfg.eeg.heogChannelNames = {'EXG1' 'EXG4'};
%     Cfg.eeg.veogChannelNames = {'H24' 'EXG2'};
% 
%     % dummy var
%     out = struct([]);
% end


% %% Configure pipe 1
% function [Cfg, out] = sbf_pipe1(Cfg)
% 
%     %%%%%%%% Define hierarchy %%%%%%%%
%     Cfg.id = 'pipe1';
%     Cfg.srcid = {''};
% 
%     %%%%%%%% Define pipeline %%%%%%%%
%     % Load
%     i = 1; %stepSet 1
%     stepSet(i).funH = { @CTAP_load_data,...
%                         @CTAP_load_chanlocs,...
%                         @CTAP_reref_data,... 
%                         @CTAP_blink2event,...
%                         @CTAP_fir_filter,...
%                         @CTAP_run_ica };
%     stepSet(i).id = [num2str(i) '_load'];
% 
%     out.load_chanlocs = struct(...
%         'overwrite', true,...
%         'delchan', 1,...
%         'index_match', false);
%     out.load_chanlocs.field = {{{'EXG1' 'EXG2' 'EXG3' 'EXG4'} 'type' 'EOG'}...
%      , {{'EXG5' 'EXG6' 'EXG7' 'EXG8' '1EX5' '1EX6' '1EX7' '1EX8'} 'type' 'NA'}};
%     out.load_chanlocs.tidy  = {{'type' 'FID'} {'type' 'NA'}};
% 
%     out.fir_filter = struct(...
%         'locutoff', 1);
% 
%     out.run_ica = struct(...
%         'method', 'fastica',...
%         'overwrite', true);
%     out.run_ica.channels = {'EEG' 'EOG'};
% 
% 
%     %%%%%%%% Store to Cfg %%%%%%%%
%     Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
%     Cfg.pipe.stepSets = stepSet; % record of all step sets
% end


% %% Configure pipe 2A
% function [Cfg, out] = sbf_pipe2A(Cfg)
% 
%     %%%%%%%% Define hierarchy %%%%%%%%
%     Cfg.id = 'pipe2A';
%     Cfg.srcid = {'pipe1#1_load'};
% 
%     %%%%%%%% Define pipeline %%%%%%%%
%     % IC correction
%     i = 1;  %stepSet
%     stepSet(i).funH = { @CTAP_detect_bad_comps,... %ADJUST for horiz eye moves
%                         @CTAP_reject_data,...
%                         @CTAP_detect_bad_comps,... %detect blink related ICs
%                         @CTAP_filter_blink_ica,...
%                         @CTAP_detect_bad_channels,...%bad channels by variance
%                         @CTAP_reject_data,...
%                         @CTAP_interp_chan };
%     stepSet(i).id = [num2str(i) '_artifact_correction'];
% 
%     out.detect_bad_comps = struct(...
%         'method', {'adjust' 'blink_template'},...
%         'adjustarg', {'horiz' ''});
% 
%     out.detect_bad_channels = struct(...
%         'method', 'variance',...
%         'bounds', [-5; 2.5],...
%         'take_worst_n', 2,...
%         'channelType', {'EEG'}); %tune thresholds compared to basic pipe!
%     
%     %%%%%%%% Store to Cfg %%%%%%%%
%     Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
%     Cfg.pipe.stepSets = stepSet; % record of all step sets
% end


% %% Configure pipe 2B
% function [Cfg, out] = sbf_pipe2B(Cfg)
% 
%     %%%%%%%% Define hierarchy %%%%%%%%
%     Cfg.id = 'pipe2B';
%     Cfg.srcid = {'pipe1#1_load'};
% 
%     %%%%%%%% Define pipeline %%%%%%%%
%     % IC correction
%     i = 1;  %stepSet
%     stepSet(i).funH = { @CTAP_detect_bad_comps,... %FASTER bad IC detection
%                         @CTAP_reject_data,...
%                         @CTAP_detect_bad_channels,...%bad channels by spectra
%                         @CTAP_reject_data,...
%                         @CTAP_interp_chan };
%     stepSet(i).id = [num2str(i) '_artifact_correction'];
% 
%     out.detect_bad_comps = struct(...
%         'method', 'faster',...
%         'bounds', [-2.5 2.5],...
%         'match_logic', @any);
% 
%     out.detect_bad_channels = struct(...
%         'method', 'rejspec',...
%         'channelType', {'EEG'});
%     
%     %%%%%%%% Store to Cfg %%%%%%%%
%     Cfg.pipe.runSets = {stepSet(:).id}; % step sets to run, default: whole thing
%     Cfg.pipe.stepSets = stepSet; % record of all step sets
% end


% %% Configure pipe for peeking at other pipe outputs
% function [Cfg, out] = sbf_peekpipe(Cfg)
% 
%     %%%%%%%% Define hierarchy %%%%%%%%
%     Cfg.id = 'peekpipe';
%     Cfg.srcid = {'pipe1#1_load'...
%                 'pipe1#pipe2A#1_artifact_correction'... 
%                 'pipe1#pipe2B#1_artifact_correction'};
% 
%     %%%%%%%% Define pipeline %%%%%%%%
%     i = 1; %next stepSet
%     stepSet(i).funH = { @CTAP_peek_data };
%     stepSet(i).id = [num2str(i) '_final_peek'];
%     stepSet(i).save = false;
% 
%     out.peek_data = struct(...
%         'secs', [10 30],... %start few seconds after data starts
%         'peekStats', true,... %get statistics for each peek!
%         'overwrite', false,...
%         'plotAllPeeks', false,...
%         'savePeekData', true,...
%         'savePeekICA', true);
% 
%     %%%%%%%% Store to Cfg %%%%%%%%
%     Cfg.pipe.stepSets = stepSet;
%     Cfg.pipe.runSets = {stepSet(:).id};
% end
