ind = '/media/ben/Maxtor/PROJECT_NEUROENHANCE/China/ANALYSIS/neuroenhance_base';
load(fullfile(ind, 'peek_stat_files.mat'))

% for pidx = 1:numel(peek_stats)
%     for sidx = ??
%         for tidx = 1:4
%             T = readtable(peek_stats(pidx).name...
%                 , 'ReadRowNames', true...
%                 , 'Sheet', sidx); %TODO: get sheet from subject * proto
%         end
%     end
% end