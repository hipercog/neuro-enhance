 function example_starter(source)

s = {'Finland' 'China'};
sidx = startsWith(s, source);
% set the input directory where your data is stored
if isunix
    % Code to run on Linux platform
    linux = {'~/Benslab', fullfile(filesep, 'media', 'ben', 'Transcend')};
    proj_root = fullfile(linux{2}, 'PROJECT_NEUROENHANCE', s{sidx}, '');
elseif ispc
    % Code to run on Windows platform
    pc3 = 'D:\LocalData\bcowley';
    proj_root = fullfile(pc3, 'PROJECT_NEUROENHANCE', s{sidx}, '');
else
    error('Platform not supported')
end

switch find(sidx)
    case 1
        neuroenhance_branch_fin(proj_root) %using all defaults
    case 2
        neuroenhance_branch_bei(proj_root) %using all defaults
end
        