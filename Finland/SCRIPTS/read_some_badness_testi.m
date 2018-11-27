inroot = 'D:\LocalData\bcowley\PROJECT_NEUROENHANCE\Finland\ANALYSIS\neuroenhance_fin_pre\pipe1';
bit = 'this\quality_control';
idx = 3;
trg = {'' '' 'segout'};
trg = trg{idx};
dat = {'badchans_rejections.mat'
       '*_detections.mat'
       'badsegev_rejections.mat'};
dat = dat{idx};
idcs  = {'A' 'B' 'C'};
for twos = 1:3
    for threes = 1:2
        pipe = fullfile(['pipe2' idcs{twos}], ['pipe3' idcs{threes}], trg);
        mat = dir(fullfile(inroot, pipe, bit, dat));
        load(fullfile(mat.folder, mat.name))
        badness = cell2mat(rejtab{:,2});
        fprintf('%s BADpc at %s = %0.5f\n', mat.name, pipe, mean(badness))
    end
end