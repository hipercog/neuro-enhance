function [treeStats, treeRej, bestpipe] = report_bei_stats(anew, plvls)

%% INIT
if nargin < 2
    plvls = {{'2A' '2B' '2C'}; {'3A' '3B'}; {'epout'}};
end
%make paths
name = './';
proj = fullfile(name, 'China', 'ANALYSIS', 'neuroenhance_bei_pre');
ind = proj;
oud = fullfile(proj, 'STAT_REP');
if ~isfolder(oud), mkdir(oud); end

%specify groups, protocols, and pipe levels
grps = {'Control'  'English'  'Music'};
cnds = {'atten' 'AV' 'multi' 'melody'};

% READ SUBJxGROUP INFO
if exist(fullfile(oud, 'subjectXgroup.mat'), 'file') == 2
    sbjXgrp = load(fullfile(oud, 'subjectXgroup.mat'));
    sbjXgrp = sbjXgrp.sbjXgrp;
else
    %read list of subjects per group
    sbjXgrp = map_bei_subj_grps;
    save(fullfile(oud, 'subjectXgroup.mat'), 'sbjXgrp')
end


%% CALL FUNCTIONS TO READ & PROCESS STATS LOGS
[treeStats, peek_stat_files] = ctap_get_peek_stats(ind, oud, 'anew', anew...
                                    , 'post_pipe_part', 'peekpipe/this/');
[treeStats, new_rows] = ctap_compare_branchstats(treeStats, grps, cnds...
                                                    , plvls(1:2), 1:9, 1:9);
save(fullfile(oud, 'peek_stats.mat'), 'treeStats')


%% CALL FUNCTIONS TO READ & PROCESS REJECTION LOGS
[treeRej, rej_files] = ctap_get_rejections(ind, oud, 'anew', anew...
                        , 'post_pipe_part', 'this/logs/all_rejections.txt');
treeRej = ctap_parse_rejections(treeRej, grps, cnds, 1:9);
treeRej = ctap_compare_branch_rejs(treeRej, grps, cnds, plvls);
save(fullfile(oud, 'rej_stats.mat'), 'treeRej')


%% JUDGEMENT : THE COMBININING
bestpipe = ctap_get_bestpipe(treeStats, treeRej, oud, plvls, 'anew', anew);
