function [EEG] = neuroenhance_preslog(EEG, varargin)

% Params
p = inputParser;
p.KeepUnmatched = true;%unspecified varargin name-value pairs go in p.Unmatched

p.addRequired('EEG', @isstruct)

p.addParameter('src', '', @ischar)
p.addParameter('proto', {'av' 'Multi_novel' 'Switching_task'}, @iscell)

p.parse(EEG, varargin{:});
Arg = p.Results;


%% Settings
% switching paradigm requires special attention
% px = min(cellfun(@(x) strdist(x, eventfile), Arg.proto));
px = cell2mat(cellfun(@(x) contains(Arg.src, x, 'Ig', true), Arg.proto, 'Un', 0));
isswitch = px(3);

% prompt mode asks for some parameters and allows retrying
% prompt = true;
%   -->  disable if looping
prompt = false;


%% Combine events in EEG
[EEG, allclear, ~, ~] = combine_events(EEG, Arg.src, isswitch, prompt);

EEG.CTAP.err.preslog_evt = allclear;

end