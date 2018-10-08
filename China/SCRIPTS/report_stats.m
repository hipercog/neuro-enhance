%% INIT
ind = '/media/ben/Maxtor/PROJECT_NEUROENHANCE/China/ANALYSIS/neuroenhance_base';
oud = '/home/ben/Benslab/PROJECT_NEUROENHANCE/China/ANALYSIS';


%% LOADING 
if exist(fullfile(oud, 'peek_stat_files.mat'), 'file') == 2
    load(fullfile(oud, 'peek_stat_files.mat'))
else
    % This takes about 20 mins
    peek_stat_files = subdir(fullfile(ind, 'peek_stats_log.xlsx'));
    save(fullfile(oud, 'peek_stat_files.mat'), 'peek_stat_files')
end

tmp = fieldnames(peek_stat_files);
tmp = cellfun(@(y) strrep(y, 'peekpipe/this/logs/peek_stats_log.xlsx', '')...
    , cellfun(@(x) strrep(x, ind, '')...
    , struct2cell(rmfield(peek_stat_files, tmp(2:end))), 'Un', 0), 'Un', 0);
treeStats = cell2struct(tmp, 'pipename', 1);

if exist(fullfile(oud, 'peek_stats.mat'), 'file') == 2
    load(fullfile(oud, 'peek_stats.mat'))
else
    % This takes about 6 hours! 'readtable()' takes a LONG time.
    for pidx = 1:numel(peek_stat_files)
        [isxl, xlsheets] = xlsfinfo(peek_stat_files(pidx).name);
        xlsheets = xlsheets(~startsWith(xlsheets, 'Sheet'));
        for sidx = 1:numel(xlsheets)
            treeStats(pidx).pipe(sidx).sbjXpro = xlsheets{sidx};
            treeStats(pidx).pipe(sidx).stat =...
                readtable(peek_stat_files(pidx).name...
                , 'ReadRowNames', true...
                , 'Sheet', xlsheets{sidx});
        end
    end
    save(fullfile(oud, 'peek_stats.mat'), 'treeStats')
end
%read list of subjects per group
sbjXpro = readtable(fullfile(ind, 'subjectXgroup.csv'));


%% COMPARING

p1_p2A3A = 