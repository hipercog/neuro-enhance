function [EEG] = neuroenhance_preslog(EEG, eventfile, varargin)

% Params
p = inputParser;
p.KeepUnmatched = true;%unspecified varargin name-value pairs go in p.Unmatched

p.addRequired('EEG', @isstruct)
p.addRequired('eventfile', @ischar)

p.addParameter('proto', {'av' 'Multi_novel' 'Switching_task'}, @iscell)

p.parse(EEG, eventfile, varargin{:});
Arg = p.Results;


%% Settings
% switching paradigm requires special attention
% px = min(cellfun(@(x) strdist(x, eventfile), Arg.proto));
px = cell2mat(cellfun(@(x) contains(eventfile, x, 'Ig', true), Arg.proto, 'Un', 0));
isswitch = px(3);

% prompt mode asks for some parameters and allows retrying
%   -->  disable if looping
% prompt = false;


%% Combine events in EEG
[EEG, allclear, preslog, eegfname] = combine_events(EEG, eventfile, isswitch);


%% Save events as separate files.
%NOTE: THIS IS ALREADY DONE, NEED ONLY BE DONE ONCE, AND IS SKIPPED
%{
[savepath, eegfn, ~] = fileparts(eegfname);
eventpath = fullfile(savepath, [eegfn '-' Arg.proto{px} '-recoded.evt']);
savename = [eegfn '-' Arg.proto{px} '-recoded.set'];

if allclear == 1
    writeEVT(EEG.event, EEG.srate, eventpath, Arg.proto)
    EEG = pop_saveset(EEG, 'filename', savename, 'filepath', savepath);
else
    eventpath_notOK = fullfile(savepath...
        , [eegfn '-' Arg.proto{px} '-recoded_missingTriggers.evt']);
    writeEVT(EEG.event, EEG.srate, eventpath_notOK, Arg.proto{px})
end
%}

end