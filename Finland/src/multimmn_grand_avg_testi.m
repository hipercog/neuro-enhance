fIn = '/home/ben/Benslab/PROJECT_NEUROENHANCE/Finland-testi/ANALYSIS/report_fin_pre/MUL_EXPORT';

% g1 = 1; g2 = 4;
c1 = 9; %c2 = 9;
locs = {'F3' 'Fz' 'F4' 'C3' 'Cz' 'C4' 'P3' 'Pz' 'P4'};
% loc = 'F4';
for loc = locs
    for g = 1:4
        for c2 = 1:8
            sbf_multiMMN_ERPs(fIn, g, g, c1, c2, loc{:})
        end
    end
end

    function sbf_multiMMN_ERPs(fIn, g1, g2, c1, c2, loc)
    
        grps = {'Con' 'Mov' 'MMo' 'Mus'};
        cnds = {'dur' 'freq1' 'freq2' 'gap' 'int' 'loc1' 'loc2' 'novel' 'stand'};
        trifecta = unique({grps{[g1 g2]} cnds{[c1 c2]}});
        if numel(trifecta) ~= 3
            error('2 groups x 1 condition OR 1 group x 2 conditions, please!')
        end
        lgnd = allcomb(unique(grps([g1 g2])), unique(cnds([c1 c2])));
        
        ERPxsbj1 = sbf_get_muls(fIn, cnds{c1}, grps{g1}, loc);
        ERPxsbj2 = sbf_get_muls(fIn, cnds{c2}, grps{g2}, loc);

        ttl = sprintf('%s-%s-%s-AT-%s', trifecta{:}, loc);
        % erp, src, pnts, zeropt, srate, tkoffset, lgnd, ttl, savename
        ctap_plot_basic_erp([mean(ERPxsbj1); mean(ERPxsbj2)]...
                        , NaN...
                        , 150, round(150 / 6), 250, 0 ...
                        , {[lgnd{1, :}] [lgnd{2, :}]}...
                        , ttl...
                        , fullfile(fIn, '..', [ttl '-simple.png']))
        ctap_plot_basic_erp([mean(ERPxsbj1); mean(ERPxsbj2)]...
                        , {ERPxsbj1; ERPxsbj2}...
                        , 150, round(150 / 6), 250, 0 ...
                        , {[lgnd{1, :}] [lgnd{2, :}]}...
                        , ttl...
                        , fullfile(fIn, '..', [ttl '-source.png']))
    end

    function ERPs = sbf_get_muls(fIn, cnd, grp, ERPloc)

        mls = struct('Npts', [], 'TSB', [], 'DI', [], 'Scale', []...
                    , 'ChannelLabels', {}, 'data', []);

        fs = dir(fullfile(fIn, ['*' cnd '.mul']));
        fs(~contains({fs.name}, grp)) = [];
        numsbjs = numel(fs);
        for i = 1:numsbjs
            mls(i) = readBESAmul(fullfile(fIn, fs(i).name));
        end

        chidx = contains(mls(1).ChannelLabels, ERPloc);

        ERPs = zeros(numsbjs, size(mls(1).data, 1));

        for i = 1:numsbjs
            ERPs(i, :) = mls(i).data(:, chidx);
        end

    end