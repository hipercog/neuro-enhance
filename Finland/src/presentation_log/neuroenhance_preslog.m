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

% If number of events and triggers don't match, combining might fail
% Prompt mode asks for some parameters and allows retrying manually
% prompt = true;
% Prompt nothing:
prompt = false;
% Instead, we can try to estimate the correct trigger by minimising the drift
auto = true;


%% Combine events in EEG
[EEG, allclear, ~, ~] = combine_events(EEG, Arg.src, isswitch, prompt, auto);

EEG.CTAP.err.preslog_evt = allclear;

end