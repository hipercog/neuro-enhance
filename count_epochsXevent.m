fs = dir('*.set');
evs = {'dur' 'freq1' 'freq2' 'gap' 'int' 'loc1' 'loc2' 'novel' 'stand'};
epcnt = struct;

for f = 1:numel(fs)
    eeg = ctapeeg_load_data(fs(f).name);
    cles = squeeze(struct2cell(eeg.epoch))';
    testi = cles(:,8);
    for e = 1:numel(evs)
        epcnt(f).(evs{e}) = sum(cellfun(@(x) any(ismember(x, evs{e})), testi));
    end
end

T = struct2table(epcnt, 'RowNames', {fs.name});
writetable(T, 'finn_epoch_counts.csv', 'WriteRowNames', true)