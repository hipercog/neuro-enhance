ind = '/media/ben/Maxtor/PROJECT_NEUROENHANCE/China/ANALYSIS/neuroenhance_base';

if exist(fullfile(ind, 'peek_stat_files.mat'), 'file') == 2
    load(fullfile(ind, 'peek_stat_files.mat'))
else
    peek_stats = subdir(fullfile(ind, 'peek_stats_log.xlsx'));
end

T = cell(1, numel(peek_stats));

for pidx = 1:numel(peek_stats)
    [isxl, xlsheets] = xlsfinfo(peek_stats(pidx).name);
    xlsheets = xlsheets(~startsWith(xlsheets, 'Sheet'));
    for sidx = 1:numel(xlsheets)
        T{end + 1} = readtable(peek_stats(pidx).name...
            , 'ReadRowNames', true...
            , 'Sheet', xlsheets(sidx));
    end
end