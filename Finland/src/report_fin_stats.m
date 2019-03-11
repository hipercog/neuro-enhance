%% INIT
%make paths
proj = {'_fin_pre', '_fin_post'};
t = 1;%PICK PRE-POST STAGE!!

root = fullfile('/media', 'bcowley', 'Transcend');
rootNE = fullfile('PROJECT_NEUROENHANCE', 'Finland', 'ANALYSIS');
ind = fullfile(root, rootNE, ['neuroenhance' proj{t}]);
oud = fullfile(root, rootNE, ['report' proj{t}]);
if ~isfolder(oud), mkdir(oud); end
%spec groups and protocol conditions
grps = {'A_movement' 'B_control' 'C_music' 'D_musicmove'};
cnds = {'AV' 'multiMMN' 'switching'};
% cnds = cnds(2);

plvls = {{'2A' '2B' '2C'}; {'3A' '3B'}};

plotnsave = false;
if plotnsave && ~isfolder(fullfile(oud, 'STAT_HISTS'))
    mkdir(fullfile(oud, 'STAT_HISTS'))
end


%% FIND PEEK STAT FILES 
if exist(fullfile(oud, 'peek_stat_files.mat'), 'file') == 2
    load(fullfile(oud, 'peek_stat_files.mat'))
else
    %% READ CODE
    % WARNING: This can take a long time!!!
    peek_stat_files = subdir(fullfile(ind, '*_stats.dat'));
%     peek_stat_dirs = subdir(fullfile(ind, '*', 'log_stats', filesep));
    save(fullfile(oud, 'peek_stat_files.mat'), 'peek_stat_files')
end


%% READ IN PEEK STAT FILES 
if exist(fullfile(oud, 'peek_stats.mat'), 'file') == 2
    load(fullfile(oud, 'peek_stats.mat'))
else
    %% READ CODE
    % This can take a long time! because 'readtable()' takes a LONG time.
    %create & fill structure of peek stat tables per participant/recording
    [treeStats, sort_ix] = subdir_parse(peek_stat_files...
        , ind, 'peekpipe/this/', 'pipename');
    for tidx = 1:numel(treeStats)
        for stix = 1:numel(treeStats(tidx).name)
            treeStats(tidx).pipe(stix).stat = readtable(...
                fullfile(treeStats(tidx).path, treeStats(tidx).name{stix})...
                , 'ReadRowNames', true);
        end
    end
    save(fullfile(oud, 'peek_stats.mat'), 'treeStats')
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
    MATS = cell(1, numel(lvl));
    vnmi = treeStats(1).pipe(1).stat.Properties.VariableNames;
    stmn = zeros(1, numel(lvl));
    nups = numel(treeStats) + 1:numel(treeStats) + numel(lvl) + 1;
    treeStats(nups(end)).pipename = 'best_pipes';
    for ldx = 1:numel(lvl)
        treeStats(nups(ldx)).pipename = lvl_nms{ldx};
    end
    
    for s = 1:numel(treeStats(1).pipe)
        rowname = treeStats(1).name{s};
        grpname = grps{cellfun(@(x) contains(rowname, x, 'Ig', 0), grps)};
        cndname = cnds{cellfun(@(x) contains(rowname, x, 'Ig', 0), cnds)};
        
        for ldx = 1:numel(lvl)
            rni = ismember(treeStats(lvl(ldx)).name, rowname);
            if ~any(rni), continue; end            
            treeStats(lvl(ldx)).pipe(rni).subj = rowname(1:5);
            treeStats(lvl(ldx)).pipe(rni).subj_num = str2double(rowname(3:5));
            treeStats(lvl(ldx)).pipe(rni).group = grpname;
            treeStats(lvl(ldx)).pipe(rni).proto = cndname;

            treeStats(nups(ldx)).pipe(rni).subj = rowname(1:5);
            treeStats(nups(ldx)).pipe(rni).subj_num = str2double(rowname(3:5));
            treeStats(nups(ldx)).pipe(rni).group = grpname;
            treeStats(nups(ldx)).pipe(rni).proto = cndname;
            
            [MATS{ldx}, nrow, nvar] = ctap_compare_stat(...
                                        treeStats(1).pipe(s).stat...
                                        , treeStats(lvl(ldx)).pipe(rni).stat);
            treeStats(nups(ldx)).pipe(rni).stat = MATS{ldx};
            stmn(ldx) = mean((MATS{ldx}{:,:} + 1) * 50, 'all', 'omitnan') - 50;
            treeStats(nups(ldx)).pipe(rni).mean_stat = stmn(ldx);

            if plotnsave
                fh = ctap_stat_hists(MATS{ldx}, 'xlim', [-1 1]); %#ok<*UNRCH>
                print(fh, '-dpng', fullfile(oud, 'STAT_HISTS'...
                    , sprintf('%s_%s_%s_%s_stats.png', grpname...
                    , cndname, rowname(1:5), lvl_nms{ldx})))
            end
        end
        % make entry holding best pipe info
        treeStats(nups(end)).name{rni} = rowname;
        treeStats(nups(end)).pipe(rni).subj = rowname(1:5);
        treeStats(nups(end)).pipe(rni).group = grpname;
        treeStats(nups(end)).pipe(rni).proto = cndname;
        MATS = cellfun(@(x) x{:,:}, MATS, 'Un', 0);
        MAT = reshape(cell2mat(MATS), nrow, nvar, numel(MATS));
        [treeStats(nups(end)).pipe(rni).stat, I] = max(MAT, [], 3);
        [~, sortn] = sort(hist(I(:), numel(unique(I))), 'descend');
        bestn = mode(I, [1 2]);
        treeStats(nups(end)).pipe(rni).best = lvl_nms{bestn};
        treeStats(nups(end)).pipe(rni).bestn = bestn;
        treeStats(nups(end)).pipe(rni).best2wrst = sortn;
        treeStats(nups(end)).pipe(rni).mean_stats = stmn;

    end
    save(fullfile(oud, 'peek_stats.mat'), 'treeStats')
end


%% FIND REJECTION TEXT FILES
if exist(fullfile(oud, 'rej_files.mat'), 'file') == 2
    load(fullfile(oud, 'rej_files.mat'))
else
    %% FIND CODE
    % WARNING: This can take a long time!!!
    rej_txts = subdir(fullfile(ind, 'all_rejections.txt'));
    save(fullfile(oud, 'rej_files.mat'), 'rej_txts')
end


%% READ REJECTION TEXT FILES TO TABLES
if exist(fullfile(oud, 'rej_stats.mat'), 'file') == 2
    load(fullfile(oud, 'rej_stats.mat'))
else
    %% READ CODE
    %get pipenames from sbudir structure
    [treeRej, sort_rejtxt] = subdir_parse(rej_txts, ind...
        , 'this/logs/all_rejections.txt', 'pipename');
    %load rejection data text files to structure
    for tidx = 1:numel(treeRej)
        for stix = 1:numel(treeRej(tidx).name)
            treeRej(tidx).pipe = table2struct(readtable(...
                fullfile(treeRej(tidx).path, treeRej(tidx).name{stix})...
                , 'Delimiter', ',', 'Format', '%s%s%s'));
        end
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
    for p = 1:size(treeRej)
        vars = fieldnames(treeRej(p).pipe);
        bad = vars{contains(vars, 'bad')};
        pc = vars{contains(vars, 'pc')};
        % massage the rows to clean and prep the data
        for r = 1:size(treeRej(p).pipe)
            rowname = treeRej(p).pipe(r).Row;
            treeRej(p).pipe(r).subj = rowname(1:5);
            treeRej(p).pipe(r).group =...
                grps{cellfun(@(x) contains(rowname, x, 'Ig', 0), grps)};
            treeRej(p).pipe(r).proto =...
                cnds{cellfun(@(x) contains(rowname, x, 'Ig', 0), cnds)};
            treeRej(p).pipe(r).(pc) = str2double(treeRej(p).pipe(r).(pc));
            bdnss = strsplit(treeRej(p).pipe(r).(bad));
            if any(isnan(cellfun(@str2double, bdnss)))
                treeRej(p).pipe(r).(bad) = bdnss;
            else
                treeRej(p).pipe(r).(bad) = cellfun(@str2double, bdnss);
            end
            treeRej(p).pipe(r).badcount = numel(treeRej(p).pipe(r).(bad));
        end
    end
    save(fullfile(oud, 'rej_stats.mat'), 'treeRej')
    %% COMPARING
    bases = setdiff(1:6, lvl);
    for lix = lvl
        vars = fieldnames(treeRej(lix).pipe);
        badpc = vars{contains(vars, '_pc')};
        root = bases(round(lix ./ 3));
        vars = fieldnames(treeRej(root).pipe);
        rootpc = vars{contains(vars, '_pc')};
        for s = {treeRej(lix).pipe.subj}
            for p = cnds
                sidx = ismember({treeRej(lix).pipe.subj}, s) &...
                       ismember({treeRej(lix).pipe.proto}, p);
                rsdx = ismember({treeRej(root).pipe.subj}, s) &...
                       ismember({treeRej(root).pipe.proto}, p);
                if sum(sidx) ~= 1 || sum(rsdx) ~= 1, continue; end
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
        clear testvec
        for lix = lvl
            if isfield(treeRej(lix).pipe(idx), 'total_badpc')
%                     ~isempty([treeRej(lix).pipe(idx).total_badpc])
                testvec(lvl == lix) = [treeRej(lix).pipe(idx).total_badpc];
            end
        end
        if exist('testvec', 'var') == 1
            low_lvl = lvl(testvec ==  min(testvec));
            treeRej(end).pipe(idx).subj = treeRej(lvl(1)).pipe(idx).subj;
            treeRej(end).pipe(idx).badness = testvec;
            treeRej(end).pipe(idx).bestn = find(ismember(lvl, low_lvl));
        end
    end
    save(fullfile(oud, 'rej_stats.mat'), 'treeRej')
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
    figure('Name', g{:}); histogram(dat, numel(unique(dat)));
end
for c = cnds
    ix = ismember({treeStats(nups(end)).pipe.proto}, c);
    dat = [treeStats(nups(end)).pipe(ix).bestn];
    figure('Name', c{:}); histogram(dat, numel(unique(dat)));
end


%% SCRATCH

for pidx = 1:numel(peek_stat_files)
    peek_stat_files(pidx).name = strrep(peek_stat_files(pidx).name, 'neuroenhance_base', 'neuroenhance_bei_pre');
    peek_stat_files(pidx).folder = strrep(peek_stat_files(pidx).folder, 'neuroenhance_base', 'neuroenhance_bei_pre');
end