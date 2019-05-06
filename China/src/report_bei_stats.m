%% INIT
%make paths
name = 'project_NEUROENHANCE';
% name = 'neuroenhance';
proj = fullfile(name, 'China', 'ANALYSIS', 'neuroenhance_bei_pre');
ind = fullfile(filesep, 'media', 'bcowley', 'Maxtor', proj);
oud = fullfile(filesep, 'home', 'bcowley', 'Benslab', proj, 'STAT_REP');
% ind = fullfile(filesep, 'wrk', 'grp', proj);
% oud = fullfile(ind, 'STAT_REP');

% if ~isfolder(oud), mkdir(oud); end
% if ~isfolder(fullfile(oud, 'STAT_HISTS'))
%     mkdir(fullfile(oud, 'STAT_HISTS'))
% end

%specify groups, protocols, and pipe levels
grps = {'Control'  'English'  'Music'};
cnds = {'atten' 'AV' 'multi' 'melody'};
plvls = {{'2A' '2B' '2C'}; {'3A' '3B'}; {'epout'}};
plotnsave = false;


%% READ SUBJxGROUP INFO
if exist(fullfile(oud, 'subjectXgroup.mat'), 'file') == 2
    load(fullfile(oud, 'subjectXgroup.mat'))
else
    %read list of subjects per group
    sbjXgrp = readtable(fullfile(ind, 'subjectXgroup.csv'));
    save(fullfile(oud, 'subjectXgroup.mat'), 'sbjXgrp')
end


%% FIND PEEK STAT FILES 
if exist(fullfile(oud, 'peek_stat_files.mat'), 'file') == 2
    load(fullfile(oud, 'peek_stat_files.mat'))
else
    % WARNING: This takes about 20 mins!!!
    peek_stat_files = subdir(fullfile(ind, 'peek_stats_log.xlsx'));
    save(fullfile(oud, 'peek_stat_files.mat'), 'peek_stat_files')
end


%% FIND REJECTION TEXT FILES
if exist(fullfile(oud, 'rej_files.mat'), 'file') == 2
    load(fullfile(oud, 'rej_files.mat'))
else
    % WARNING: This takes about 20 mins!!!
    rej_txts = subdir(fullfile(ind, 'all_rejections.txt'));
    save(fullfile(oud, 'rej_files.mat'), 'rej_txts')
end


%% READ PEEK STAT FILES 
if exist(fullfile(oud, 'peek_stats.mat'), 'file') == 2
    load(fullfile(oud, 'peek_stats.mat'))
else
    % This takes about 6 hours! because 'readtable()' takes a LONG time.
    %create & fill structure of peek stat tables per participant/recording
    treeStats = subdir_parse(peek_stat_files, ind...
        , 'peekpipe/this/logs/peek_stats_log.xlsx', 'pipename');
    for pidx = 1:numel(peek_stat_files)
        [isxl, xlsheets] = xlsfinfo(peek_stat_files(pidx).name);
        xlsheets = xlsheets(~startsWith(xlsheets, 'Sheet'));
        for sid1 = 1:numel(xlsheets)
            treeStats(pidx).pipe(sid1).sbjXpro = xlsheets{sid1};
            treeStats(pidx).pipe(sid1).stat =...
                readtable(peek_stat_files(pidx).name...
                , 'ReadRowNames', true...
                , 'Sheet', xlsheets{sid1});
        end
    end
    save(fullfile(oud, 'peek_stats.mat'), 'treeStats')
end


%% READ REJECTION TEXT FILES TO TABLES
if exist(fullfile(oud, 'rej_stats.mat'), 'file') == 2
    load(fullfile(oud, 'rej_stats.mat'))
else
    %get pipenames from sbudir structure
    [treeRej, sort_rejtxt] = subdir_parse(rej_txts, ind...
        , 'this/logs/all_rejections.txt', 'pipename');
    %load rejection data text files to structure
    for r = 1:numel(sort_rejtxt)
        treeRej(r).pipe =...
            table2struct(readtable(sort_rejtxt(r).name, 'Delimiter', ','));
    end
    lvl = [];
    lvl_nms = {};
    for l2 = plvls(1:2)
        for l3 = plvls(3:4)
            lvl(end + 1) = find(contains({treeRej.pipename}, l2) &...
                                contains({treeRej.pipename}, l3));
            lvl_nms{end + 1} = ['rej_p' l2{:} l3{:}];  %#ok<*SAGROW>
        end
    end
    save(fullfile(oud, 'rej_stats.mat'), 'treeRej')
end


%% GET PARSED REJECTION DATA
if exist(fullfile(oud, 'rej_stats.mat'), 'file') == 2
    load(fullfile(oud, 'rej_stats.mat'))
else
    %% PARSE REJECTION TABLE DATA
    %go through each pipe, group, protocol and subject to parse the data
    for r = 1:numel(sort_rejtxt)
        vars = fieldnames(treeRej(r).pipe);
        bad = vars{contains(vars, 'bad')};
        for g = 1:numel(grps)
            tmp = table2array(sbjXgrp(:, grps{g}));
            tmp(isnan(tmp)) = [];
            for c = 1:numel(cnds)
                for s = 1:numel(tmp)
                    sid = startsWith({treeRej(r).pipe.Row}, num2str(tmp(s))) &...
                        contains({treeRej(r).pipe.Row}, cnds{c}, 'Ig', true);
                    if ~any(sid), continue; end
                    treeRej(r).pipe(sid).subj = tmp(s);
                    treeRej(r).pipe(sid).group = grps{g};
                    treeRej(r).pipe(sid).proto = cnds{c};
                    treeRej(r).pipe(sid).badness =...
                        str2double(strsplit(strrep(strrep(...
                        treeRej(r).pipe(sid).(bad), 'E', ''), 'none', '0')));
                    treeRej(r).pipe(sid).badcount =...
                        numel(treeRej(r).pipe(sid).([bad '_nums']));
                end
            end
        end
    end
    save(fullfile(oud, 'rej_stats.mat'), 'treeRej')
    %% COMPARING
    bases = setdiff(1:6, lvl);
    for lix = lvl
%         all([treeRej(1).pipe.subj] == [treeRej(lix).pipe.subj])    end
        vars = fieldnames(treeRej(lix).pipe);
        badpc = vars{contains(vars, '_pc')};
        root = bases(round(lix ./ 3));
        vars = fieldnames(treeRej(root).pipe);
        rootpc = vars{contains(vars, '_pc')};
        for s = [treeRej(lix).pipe.subj]
            for p = cnds
                sidx = find(s == [treeRej(lix).pipe.subj] &...
                    ismember({treeRej(lix).pipe.proto}, p));
                rsdx = find(s == [treeRej(root).pipe.subj] &...
                     ismember({treeRej(root).pipe.proto}, p));
                if isempty(sidx) || isempty(rsdx), continue; end
                root_badpc = treeRej(root).pipe(rsdx).(rootpc);
                treeRej(lix).pipe(sidx).root_badpc = root_badpc;
                treeRej(lix).pipe(sidx).total_badpc = root_badpc +...
                    treeRej(lix).pipe(sidx).(badpc);
            end
        end
    end
    save(fullfile(oud, 'rej_stats.mat'), 'treeRej')
    %% BUILD RANK PIPE
    treeRej(end +1).pipename = 'rank_pipes';
    %for each row, find lowest-scoring of four node pipes and copy
    for idx = 1:numel(treeRej(lvl(1)).pipe)
        for lix = lvl
            testvec(lvl == lix) = [treeRej(lix).pipe(idx).total_badpc];
        end
        low_lvl = lvl(testvec ==  min(testvec));
        treeRej(end).pipe(idx).subj = treeRej(lvl(1)).pipe(idx).subj;
        treeRej(end).pipe(idx).badness = testvec;
        treeRej(end).pipe(idx).bestn = find(ismember(lvl, low_lvl));

    end
    save(fullfile(oud, 'rej_stats.mat'), 'treeRej')
end


%% GET PEEK STAT COMPARISON DATA
if exist(fullfile(oud, 'peek_stats.mat'), 'file') == 2
    load(fullfile(oud, 'peek_stats.mat'))
else
    %% COMPARING PEEK STATS
    lvl = [];
    lvl_nms = {};
    for l2 = plvls(1:2)
        for l3 = plvls(3:4)
            lvl(end + 1) = find(contains({treeStats.pipename}, l2) &...
                                contains({treeStats.pipename}, l3));
            lvl_nms{end + 1} = ['p1_p' l2{:} l3{:}];  %#ok<*SAGROW>
        end
    end
    MATS = cell(1, 4);
    vnmi = treeStats(1).pipe(1).stat.Properties.VariableNames;
    nups = 1 + numel(treeStats):numel(treeStats) + numel(lvl) + 1;
    statmn = zeros(1, 4);
    
    for g = 1:numel(grps)
        tmp = table2array(sbjXgrp(:, grps{g}));
        tmp(isnan(tmp)) = [];
        for c = 1:numel(cnds)
            for s = 1:numel(tmp)
                sid1 = startsWith({treeStats(1).pipe.sbjXpro}, num2str(tmp(s))) &...
                    contains({treeStats(1).pipe.sbjXpro}, cnds{c}, 'Ig', true);
                if ~any(sid1), continue; end
                for ldx = 1:numel(lvl)
                    sbjXpro = {treeStats(lvl(ldx)).pipe.sbjXpro};%base subj
                    sidx = startsWith(sbjXpro, num2str(tmp(s))) &...
                            contains(sbjXpro, cnds{c}, 'IgnoreCase', true);
                    if ~any(sidx), continue; end
                    [MATS{ldx}, nrow, nvar] = ctap_compare_stat(...
                        treeStats(1).pipe(sid1).stat...
                        , treeStats(lvl(ldx)).pipe(sidx).stat);
                    if plotnsave
                        fh = ctap_stat_hists(MATS{ldx}, 'xlim', [-1 1]); %#ok<*UNRCH>
                        print(fh, '-dpng', fullfile(oud, 'STAT_HISTS'...
                            , sprintf('%s_%s_%s_%s_stats.png', grps{g}...
                            , cnds{c}, num2str(tmp(s)), lvl_nms{ldx})))
                    end
                    treeStats(nups(ldx)).pipename = lvl_nms{ldx};
                    treeStats(nups(ldx)).pipe(sidx).sbjXpro = sbjXpro{sidx};
                    treeStats(nups(ldx)).pipe(sidx).subj = tmp(s);
                    treeStats(nups(ldx)).pipe(sidx).group = grps{g};
                    treeStats(nups(ldx)).pipe(sidx).proto = cnds{c};
                    treeStats(nups(ldx)).pipe(sidx).stat = MATS{ldx};
                    statmn(ldx) = mean(...
                        (MATS{ldx}{:,:} + 1) * 50, 'all', 'omitnan') - 50;
                    treeStats(nups(ldx)).pipe(sidx).mean_stat = statmn(ldx);
                end
                % make entry holding best pipe info
                treeStats(nups(end)).pipename = 'best_pipes';
                treeStats(nups(end)).pipe(sidx).sbjXpro = sbjXpro{sidx};
                treeStats(nups(end)).pipe(sidx).subj = tmp(s);
                treeStats(nups(end)).pipe(sidx).group = grps{g};
                treeStats(nups(end)).pipe(sidx).proto = cnds{c};
                MATS = cellfun(@(x) x{:,:}, MATS, 'Un', 0);
                MAT = reshape(cell2mat(MATS), nrow, nvar, numel(MATS));
                [treeStats(nups(end)).pipe(sidx).stat, I] = max(MAT, [], 3);
                [~, sortn] = sort(hist(I(:), numel(unique(I))), 'descend');
                bestn = mode(I, [1 2]);
                treeStats(nups(end)).pipe(sidx).best = lvl_nms{bestn};
                treeStats(nups(end)).pipe(sidx).bestn = bestn;
                treeStats(nups(end)).pipe(sidx).best2wrst = sortn;
                treeStats(nups(end)).pipe(sidx).mean_stats = statmn;
            end
        end
    end
    save(fullfile(oud, 'peek_stats.mat'), 'treeStats')
end


%% JUDGEMENT : THE COMBININING
if exist(fullfile(oud, 'best_pipe.mat'), 'file') == 2
    load(fullfile(oud, 'best_pipe.mat'))
else
    %% BUILD IT
    lvl_nms = {};
    for l2 = plvls(1:2)
        for l3 = plvls(3:4)
            lvl_nms{end + 1} = ['p' l2{:} l3{:}];  %#ok<*SAGROW>
        end
    end
    bestpipe = struct;
    thr = 20;
    for idx = 1:numel(treeRej(end).pipe)
        if treeRej(end).pipe(idx).subj ~= treeStats(end).pipe(idx).subj
            error('something has gone terribly wrong')
        else
            bestpipe(idx).subj = treeStats(end).pipe(idx).subj;
            bestpipe(idx).group = treeStats(end).pipe(idx).group;
            bestpipe(idx).proto = treeStats(end).pipe(idx).proto;
        end
        rejn = treeRej(end).pipe(idx).bestn;
        stan = treeStats(end).pipe(idx).bestn;
        bestpipe(idx).rejbest = rejn;
        bestpipe(idx).statbst = stan;
        
        [rejrank, rjix] = sort(treeRej(end).pipe(idx).badness);
        [srank, stix] = sort(treeStats(end).pipe(idx).mean_stats, 'descend');
        for p = 1:numel(plvls)
            piperank(p) = find(rjix == p) + find(stix == p);
        end
        bestix = find(piperank == min(piperank));
        if numel(bestix) > 1
            [~, bestix] = min(rejrank(bestix));
        end
        bestpipe(idx).bestpipe = bestix;

        if any(ismember(rejn, stan))
            bestpipe(idx).bestn = rejn(ismember(rejn, stan));
        else
            bestpipe(idx).bestn = stan;
        end

        bestpipe(idx).badness1 = treeRej(end).pipe(idx).badness(bestix);
        bestpipe(idx).badness2 =...
                       treeRej(end).pipe(idx).badness(bestpipe(idx).bestn);
        bestpipe(idx).stat1 = treeStats(end).pipe(idx).mean_stats(bestix);
        bestpipe(idx).stat2 =...
                  treeStats(end).pipe(idx).mean_stats(bestpipe(idx).bestn);
    end
    save(fullfile(oud, 'best_pipe.mat'), 'bestpipe')
end


%% GROUP-WISE AND CONDITION-WISE HISTOGRAMS OF PIPE STATS
for g = grps
    ix = ismember({treeStats(nups(end)).pipe.group}, g);
    dat = [treeStats(nups(end)).pipe(ix).bestn];
    figure('Name', g{:}); hist(dat, numel(unique(dat)));
end
for c = cnds
    ix = ismember({treeStats(nups(end)).pipe.proto}, c);
    dat = [treeStats(nups(end)).pipe(ix).bestn];
    figure('Name', c{:}); hist(dat, numel(unique(dat)));
end


%% SCRATCH

for pidx = 1:numel(peek_stat_files)
    peek_stat_files(pidx).name = strrep(peek_stat_files(pidx).name, 'neuroenhance_base', 'neuroenhance_bei_pre');
    peek_stat_files(pidx).folder = strrep(peek_stat_files(pidx).folder, 'neuroenhance_base', 'neuroenhance_bei_pre');
end