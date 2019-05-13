%% INIT
%make paths
% name = 'project_NEUROENHANCE';
name = './';
proj = fullfile(name, 'China', 'ANALYSIS', 'neuroenhance_bei_pre');
% ind = fullfile(filesep, 'media', 'bcowley', 'Maxtor', proj);
% oud = fullfile(filesep, 'home', 'bcowley', 'Benslab', proj, 'STAT_REP');
ind = proj;
oud = fullfile(proj, 'STAT_REP');

%specify groups, protocols, and pipe levels
grps = {'Control'  'English'  'Music'};
cnds = {'atten' 'AV' 'multi' 'melody'};
plvls = {{'2A' '2B' '2C'}; {'3A' '3B'}; {'epout'}};
plotnsave = false;

% READ SUBJxGROUP INFO
if exist(fullfile(oud, 'subjectXgroup.mat'), 'file') == 2
    load(fullfile(oud, 'subjectXgroup.mat'))
else
    %read list of subjects per group
    sbjXgrp = map_bei_subj_grps;
    save(fullfile(oud, 'subjectXgroup.mat'), 'sbjXgrp')
end


%% CALL FUNCTIONS TO READ & PROCESS STATS LOGS
[treeStats, peek_stat_files] = ctap_get_peek_stats(ind, oud...
                                    , 'post_pipe_part', 'peekpipe/this/');
[treeStats, new_rows] = ctap_compare_branchstats(treeStats, grps, cnds...
                                                    , plvls(1:2), 1:9, 1:9);


%% CALL FUNCTIONS TO READ & PROCESS REJECTION LOGS
[treeRej, rej_files] = ctap_get_rejections(ind, oud...
                        , 'post_pipe_part', 'this/logs/all_rejections.txt');
treeRej = ctap_parse_rejections(treeRej, grps, cnds, 1:9);
treeRej = ctap_compare_branch_rejs(treeRej, grps, cnds, plvls);


%% JUDGEMENT : THE COMBININING
bestpipe = ctap_get_bestpipe(treeStats, treeRej, oud, plvls);


%% GROUP-WISE AND CONDITION-WISE HISTOGRAMS OF PIPE STATS
% pidx = new_rows(end);
% for g = grps
%     ix = ismember({treeStats(pidx).pipe.group}, g);
%     dat = [treeStats(pidx).pipe(ix).bestn];
%     figure('Name', g{:}); histogram(dat, numel(unique(dat)));
% end
% for c = cnds
%     ix = ismember({treeStats(pidx).pipe.proto}, c);
%     dat = [treeStats(pidx).pipe(ix).bestn];
%     figure('Name', c{:}); histogram(dat, numel(unique(dat)));
% end


%% SCRATCH
% for pidx = 1:numel(peek_stat_files)
%     peek_stat_files(pidx).name = strrep(peek_stat_files(pidx).name...
%                             , 'neuroenhance_base', 'neuroenhance_bei_pre');
%     peek_stat_files(pidx).folder = strrep(peek_stat_files(pidx).folder...
%                             , 'neuroenhance_base', 'neuroenhance_bei_pre');
% end