function [EEG, Cfg] = CTAP_peek_data(EEG, Cfg)
%CTAP_peek_data - Take a peek at the data and save it as an image
%
% Description:
%   Generate EEG data stats. Make a histogram thereof. Make eegplot of a random
%   (or user-specified) window of raw EEG data, and raw IC data. 
%   Save stats in tables, and figures to disk for later viewing.
%
% Syntax:
%   [EEG, Cfg] = CTAP_peek_data(EEG, Cfg);
%
% Inputs:
%   EEG         struct, EEGLAB structure
%   Cfg         struct, CTAP configuration structure
%   Cfg.ctap.peek_data:
%       .plotEEGHist    logical, Plot EEG histogram?, default: Cfg.grfx.on
%       .plotEEG        logical, Plot EEG data?, default: Cfg.grfx.on
%       .plotICA        logical, Plot ICA components?, default: Cfg.grfx.on
%       .plotAllPeeks   logical, Plot all peeks or 1 random one?, default: true
%       .savePeekData   logical, Save EEG data from each peek, default: false
%       .savePeekICA    logical, Save IC values from each peek, default: false
%       .logStats       logical, compute stats for whole data, default: true
%       .peekStats      logical, compute stats for each peek, default: false
%       .secs           numeric, seconds to plot from min to max, default: 0 16
%       .peekevent      cellstring array, event name(s) to base peek windows on
%       .peekindex      vector, index of such events to use, default (only if 
%                       .peekevent is defined): uniform distribution of 10
%       .hists          scalar, square number histograms per figure, default: 16
%       .channels       cellstring array, chanlocs labels or type, default: 'EEG'
%       .overwrite      logical, wipe existing output from prior peek_data runs
%
% Outputs:
%   EEG         struct, EEGLAB structure modified by this function
%   Cfg         struct, Cfg struct is updated by parameters,values actually used
%
% Notes: 
%   To check raw EEG latencies, we create new peeks, options are:
%   1. explicitly user guided by choosing some existing events
%   2. use the events user has defined for selecting data (because we know
%      such latencies won't be deleted, except by bad segment/epoch reject)
%   3. select random set of 10 latencies (or less if data is short)
%
% See also:  
%
% Copyright(c) 2015 FIOH:
% Benjamin Cowley (Benjamin.Cowley@ttl.fi), Jussi Korpela (jussi.korpela@ttl.fi)
%
% This code is released under the MIT License
% http://opensource.org/licenses/mit-license.php
% Please see the file LICENSE for details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Set optional arguments
% plot settings follow the global flag, unless specified by user!
Arg.plotEEGHist = Cfg.grfx.on;
Arg.plotEEG = Cfg.grfx.on;
Arg.plotICA = Cfg.grfx.on;
Arg.plotAllPeeks = true;
Arg.savePeekData = false;
Arg.savePeekICA = false;
Arg.logStats = true;
Arg.peekStats = false;
Arg.numpeeks = 10;
Arg.secs = [0 16];
Arg.hists = 16; %number of histograms per figure, should be a square number
Arg.channels = 'EEG';
Arg.overwrite = true;

% Override defaults with user parameters...
if isfield(Cfg.ctap, 'peek_data')
    Arg = joinstruct(Arg, Cfg.ctap.peek_data); %override with user params
end
%...but ICs must be present
Arg.plotICA = Arg.plotICA & ~isempty(EEG.icaweights);
%...and seconds must be a relative [min max] pair of positive integers
if isscalar(Arg.secs), Arg.secs = [0 Arg.secs]; end
Arg.secs = round(sort(abs(Arg.secs)));
dur = diff(Arg.secs);
if ~isscalar(dur) || (dur < 1)
    error('CTAP_peek_data:inputError', 'Arg.secs must be [min max], max-min>1.'); 
end
%...and we treat only EEG channels
if ismember('EEG', Arg.channels)
    chidx = get_eeg_inds(EEG, {'EEG'});
else
    chidx = find(ismember({EEG.chanlocs.labels}, Arg.channels));
end
if numel(chidx) == 0
   error('CTAP_peek_data:inputError', 'Channels not found. Check Arg.channels'); 
end
nchan = numel(chidx);


%% Define directory to save stuff to
args = logical([Arg.plotEEGHist Arg.plotEEG Arg.plotICA Arg.logStats]);
if any(args)
    savepath = get_savepath(Cfg, mfilename, 'qc');
    savepath = fullfile(savepath, EEG.CTAP.measurement.casename);
    prepare_savepath(savepath, 'deleteExisting', Arg.overwrite);
    
    plotz = {'Histogram' 'Raw EEG' 'Independent Components' 'Channel stats'};
    myReport(newline, Cfg.env.logFile);
    msg = myReport(sprintf('Saving Diagnostics to ''%s''\nFor %s'...
        , savepath, sprintf('''%s'', ', plotz{args})), Cfg.env.logFile);

else
    return;
end


%% make and save stats to log file
if Arg.logStats
    % get stats of each channel in the file, build a matrix of stats
    [~, ~, statab] = ctapeeg_stats_table(EEG, 'channels', chidx...
        , 'outdir', savepath, 'id', 'peekall');
    
    % Write the stats for each peek for each subject to 1 log file
    stalog = fullfile(Cfg.env.paths.logRoot, 'peek_stats_log.xlsx');
    rptname = strrep(EEG.CTAP.measurement.casename, '_session_meas', '');
    rptname = sprintf('%s_set%d_fun%d'...
        , rptname(1:min(17, length(rptname)))...
        , Cfg.pipe.current.set...
        , Cfg.pipe.current.funAtSet);
    myReport(sprintf('Writing channel-wise peek statistics for %s to %s.'...
        , rptname, stalog), Cfg.env.logFile);
    writetable(statab, stalog, 'WriteRowNames', true, 'Sheet', rptname)

end


%% Plot histograms of all channels
if Arg.plotEEGHist
    % Loop the channels so not all plots are forced onto one page
    fx = Arg.hists;
    for i = 1:fx:nchan
        fh = eeglab_plot_channel_properties(EEG, fx...
            , 'chans', chidx(i:min(i+fx-1, nchan)));
        %named after channels shown
        savename = sprintf('EEGHIST_chan%d-%d.png', i, min(i+fx-1, nchan));
        print(fh, '-dpng', fullfile(savepath, savename));
        close(fh);
    end
end


%% Define latencies to peek at
peekmatch = ismember({EEG.event.type}, 'ctapeeks');
if any(peekmatch)%peek events are present - use them
    starts = [EEG.event(peekmatch).latency]; 
else
    %create new peeks from existing user-defined events
    if isfield(Arg, 'peekevent')
        % based on events
        peekidx = find(ismember({EEG.event.type}, Arg.peekevent));
        if isfield(Arg, 'peekindex')
            peekidx = peekidx(Arg.peekindex);
        else
            npk = numel(peekidx);
            if npk > Arg.numpeeks
                peekidx = peekidx(1:round(npk / Arg.numpeeks):end);
            end
        end
        starts = [EEG.event(peekidx).latency];
        starts = starts(0 < starts); %remove possible negative values

    %create new peeks from data-selection events (as this data will not be cut!)
    elseif isfield(Cfg.ctap, 'select_evdata') &&...
            isfield(Cfg.ctap.select_evdata, 'evtype')
        peekmatch = ismember({EEG.event.type}, Cfg.ctap.select_evdata.evtype);
        starts = [EEG.event(peekmatch).latency] + 1;

    %create new peeks at uniformly-distributed random times
    else
        %num peeks = as many as will fit with space at the end, < Arg.numpeeks
        npk = min(Arg.numpeeks, round((EEG.xmax * EEG.trials - Arg.secs(2)) / dur));
        % start latency of peeks is linear spread, randomly jittered
        starts = (linspace(1, EEG.xmax * EEG.trials - Arg.secs(2), npk) +...
                                       [rand(1, npk - 1) .* dur 0]) * EEG.srate;
    end
    
    % add peek positions as events
    labels = cellfun(@(x) sprintf('peek%d',x), num2cell(1:numel(starts)),'Un', 0);
    EEG.event = eeglab_merge_event_tables(EEG.event,...
                eeglab_create_event(starts, 'ctapeeks', 'label', labels),...
                'ignoreDiscontinuousTime');
            
    peekmatch = ismember({EEG.event.type}, 'ctapeeks'); %assumed to exist later
end
% Find labels for peeks
if isfield(EEG.event, 'label')
    labels = {EEG.event(peekmatch).label};
else
    % dangerous to resort to this, make sure labels always exist!
    labels = cellfun(@(x) sprintf('peek%d',x), num2cell(1:sum(peekmatch)), 'Un', 0);
end
starts = int64(starts);

% Save defined peek-times
peektab = table(ascol(starts / EEG.srate)...
            , 'RowNames', labels...
            , 'VariableNames', {'peekLatencySecs'});
writetable(peektab, fullfile(savepath, 'peek_times'), 'WriteRowNames', true)


%% save EEG data from each peek
if Arg.savePeekData
    % grab data for a number of "peek" windows and save matrices as mat files
    for i = 1:numel(starts)
        latency = int16(starts(i) + Arg.secs(1) * EEG.srate);
        duration = int16(latency + dur * EEG.srate);
        outdata = EEG.data(chidx, latency:duration); %#ok<*NASGU>
        save(fullfile(savepath, sprintf('signal_%s', labels{i})), 'outdata')
    end
end


%% save ICA data from each peek
if Arg.savePeekICA && ~isempty(EEG.icaweights)
    activations = icaact(EEG.data(EEG.icachansind, :),...
                         EEG.icaweights * EEG.icasphere, 0);
    % grab ICA values for a number of "peek" windows, save matrices as mat files
    for i = 1:numel(starts)
        latency = int16(starts(i) + Arg.secs(1) * EEG.srate);
        duration = int16(latency + dur * EEG.srate);
        outdata = activations(:, latency:duration);
        save(fullfile(savepath, sprintf('ICA_%s', labels{i})), 'outdata')
    end
end


%% calculate stats for each peek separately
if Arg.peekStats
    % grab stats for a number of "peek" windows and save tables as mat files
    for i = 1:numel(starts)
        ctapeeg_stats_table(EEG, 'channels', chidx...
            , 'latency', starts(i) + Arg.secs(1) * EEG.srate...
            , 'duration', dur * EEG.srate...
            , 'outdir', savepath, 'id', labels{i});
    end
end


%% Plot raw data from channels
% for either all peeks, or just one (if plotting all would be a mountain)
if ~Arg.plotAllPeeks
    pkidx = 1;
    starts = starts(pkidx);
    labels = labels(pkidx);
end

if Arg.plotEEG

    % set channels to plot in red
    if isfield(EEG.CTAP, 'badchans') &&...
       isfield(EEG.CTAP.badchans, 'detect')
        markChannels = EEG.CTAP.badchans.detect.chans;
    else
        markChannels = {};
    end
        
    % plot a number of "peek" windows and save as png(s)
    for i = 1:numel(starts)
        % plot n save one peek window over 'idx' EEG channels, max 32 chans/png
        plotNsave_raw(EEG, savepath, sprintf('rawEEG_%s', labels{i})...
                , 'channels', {EEG.chanlocs(chidx).labels}...
                , 'markChannels', markChannels...
                , 'startSample', starts(i)...
                , 'secs', Arg.secs...
                , 'paperwh', [-1 -1]);
    end
    
end


%% Plot raw data from ICA components
if Arg.plotICA
    % Make a dataset to plot
    activations = icaact(EEG.data(EEG.icachansind,:),...
                         EEG.icaweights*EEG.icasphere, 0);
    ch_labels = cellfun(@num2str, num2cell(1:size(activations,1))', 'Uni', 0);
    ch_labels = strcat('IC', ch_labels);
    ICAEEG = create_eeg(activations,...
                        'fs', EEG.srate,...
                        'channel_labels', ch_labels');
    ICAEEG.setname = sprintf('%s_ICA', EEG.setname);
                    
    % plot data in "peek" windows and save as png(s)
    for i = 1:numel(starts)
        % plot and save
        plotNsave_raw(ICAEEG, savepath, sprintf('rawICA_%s', labels{i})...
                , 'dataname', 'IC activations'...
                , 'channels', {ICAEEG.chanlocs.labels}...
                , 'startSample', starts(i)...
                , 'secs', Arg.secs...
                , 'paperwh', [-1 -1]...
                , 'plotEvents', false);
    end

end


%% ERROR/REPORT
EEG.CTAP.history(end+1) = create_CTAP_history_entry(msg, mfilename, Arg);

end %CTAP_peek_data()
