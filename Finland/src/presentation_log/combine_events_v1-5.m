% Reading Presentation log for Viertola paradigms
% 
% AUTHOR     jenni.saaristo@helsinki.fi
% DATE       21.1.19
% VERSION    1.5
% NOTES      Tommi's addition on line 354 modified. (Should be compared with
%            size(pres.newlatency, 1), because size(pres.newlatency, 2) is
%            always 1 and comparison comes out false every time.)

function [EEGOUT, allclear, pres] = combine_events(bvpath, bvfile, logpath, logfile, isswitch, prompt)

% Get files
try
    disp(['Attempting to combine ' bvfile ' and ' logfile '.'])
    EEG = pop_loadbv(bvpath, bvfile);
    filename = [logpath logfile];
    fields = loadtxt(filename, 'delim', 9, 'skipline', -2 , 'verbose', 'off');
catch ME
    if strcmp('No such file or directory', ME.message)
        warning('Wrong filenames! See headerfile (below) for correct ones.');
        hdr = readbvconf(bvpath, bvfile);
        disp(hdr.commoninfos);
        if ~prompt
            warning('Skipping file %s.', bvfile);
        end
    else
        rethrow(ME);
    end
    allclear = 0;
    EEGOUT = [];
    pres = [];
    return;
end


% Clean log
pres = clean_log(fields, prompt);

% If is switching, separate pictures
if isswitch
    [pres, pres_pics] = separate_pictures(pres);
end

% Discrepancies?
disp(['There are ' int2str(length(EEG.event)-1) ' eeg triggers.'])
disp(['There are ' int2str(length(pres.type)) ' logged events.'])


% Syncing and matching events
tryagain = 1;
while tryagain
    allclear = 1;
    
    % Define the event no to be used for syncing (in eeg data)
    syncevent = 2;
    % If in prompt mode
    if prompt
        syncevent = input('Which eeg trigger no. should be used for syncing? (To use default, press Enter): ');
        if isempty(syncevent) || ~(isnumeric(syncevent))
            syncevent = 2;
        end
    end
    
    % Try to sync
    pres.newlatency = calculate_latencies(EEG.event, pres, syncevent, bvfile, prompt);
    
    % Define the tolerance
    tolerance = 11;
    % If in prompt mode
    if prompt
        tolerance = input('How many samples of tolerance for matching? (To use default 11, press Enter): ');
        if isempty(tolerance) || ~(isnumeric(tolerance))
           tolerance = 11;
        end
    end

    % Try to match
    [newevent, bad_log_ind, bad_eeg_ind] = match_events(EEG.event, pres, tolerance, syncevent, prompt);
    
    % If there was trouble and not in prompt mode, exit immediately
    if isempty(newevent) && ~prompt
        allclear = 0;
        EEGOUT = [];
        warning('Matching unsuccessful with %s. Quitting.', bvfile);
        return;
    end
    
    % See if unresolved events can be safely added
    if ~isempty(newevent)
        add_ok = true;
        if length(bad_log_ind) > 1
            [add_ok, not_ok_mask] = check_adding(bad_log_ind, pres, tolerance);
            allclear = add_ok;
        end
        if length(bad_eeg_ind) > 1
            warning('Unresolved eeg triggers remain. They will be ignored.');
            allclear = 0;
        end
    end
    
    % Allow for retry or termination (in prompt mode)
    if isempty(newevent) && prompt
        inp = input('Press Enter to try matching again or [x] to give up. ', 's');
        if strcmp(inp, 'x')
            disp('Quitting.');
            allclear = 0;
            EEGOUT = [];
            return;
        else
            tryagain = 1;
        end
    elseif prompt
        inp = input('Press Enter to proceed, [a] to try matching again, or [x] to give up. ', 's');
        if strcmp(inp, 'x')
            disp('Quitting.');
            allclear = 0;
            EEGOUT = [];
            return;
        elseif isempty(inp)
            tryagain = 0;
        end
    else
        tryagain = 0;
    end
end

% Replace old events with new
if prompt
    disp('Replacing old event table...')
end
EEG.event = newevent;
if prompt
    disp('Done.')
end
% NOTE: urevents are not modified!! Should they be?
% If yes, the whole match_events function needs overhaul!

% Add unresolved log events to eeg
if length(bad_log_ind) > 1 && ~add_ok && prompt
    inp = input('Some events cannot be added. Press [a] if you want to add what can be added, otherwise press Enter. ', 's');
    if strcmp(inp, 'a')
        bad_log_ind = bad_log_ind(~not_ok_mask);
        add_ok = 1;
    end
elseif length(bad_log_ind) > 1 && ~add_ok && ~prompt
    % There really should be a log written about these troublemakers!!
    disp('Note: Unadded events remained. Checking these indices by hand is strongly recommended!');
    disp(bad_log_ind(not_ok_mask));
end

if length(bad_log_ind) > 1 && add_ok
    EEG = add_unresolved(EEG, bad_log_ind, syncevent, tolerance, pres, prompt);
end
% NOTE: Pictures in switching are not added!! Should they be?
% Function above is defined with varargin to enable adding this later

disp(['Finished! Allclear is ', int2str(allclear)]);

% Return value
EEGOUT = EEG;

end


function pres = clean_log(fields, prompt)

if prompt
    disp('Cleaning Presentation log...')
end

% Find columns
for c = 1:length(fields(1,:))
    if strcmp(fields(1,c), 'Event Type')
        i_type = c;
    elseif strcmp(fields(1,c), 'Code')
        i_code = c;
    elseif strcmp(fields(1,c), 'Time')
        i_latency = c;
    elseif strcmp(fields(1,c), 'Duration')
        i_dur = c;
    end
end

% Copy and clean
latency = fields(:,i_latency);

for i = 2:length(latency)
    if ~isnumeric(latency{i}) || isempty(latency{i})
        indend = i-1;
        break;
    elseif i == length(latency)
        indend = i;
    end
end

latency = latency(2:indend);

type = fields(:,i_type);
type = type(2:indend);

code = fields(:,i_code);
code = code(2:indend);

duration = fields(:,i_dur);
duration = duration(2:indend);

% replace empty duration cells with zeros
for i = 1:length(duration)
    if isempty(duration{i})
        duration{i} = 0;
    end
end

if prompt
    disp('Done.')
end

% Create table
pres = table;
pres.latency = latency;
pres.duration = duration;
pres.type = type;
pres.code = code;

end

function [pres, pres_pics] = separate_pictures(pres)

% How many pictures
pic_ind = false(1,length(pres.type));
for i  = 1:length(pres.type)
    if strcmp(pres.type{i}, 'Picture')
        pic_ind(i) = 1;
    end
end

pres_pics = pres(pic_ind,:);
pres = pres(~pic_ind,:);

end

function newlatency = calculate_latencies(event, pres, syncevent, bvfile, prompt)

if prompt
    disp('Calculating latencies and drifts...')
end

diff = event(syncevent).latency - pres.latency{1}*0.05;
newlatency = pres.latency;

for i = 1:length(newlatency)
    newlatency{i} = newlatency{i}*0.05 + diff;
end;

% See whether there are drifts
drifts = zeros(1,length(newlatency));
if length(event)-1-syncevent < length(newlatency)
    k = length(event)-syncevent;
else
    k = length(newlatency);
end

for i = 1:k
    drifts(i) = event(syncevent-1+i).latency - newlatency{i};
end;

if prompt
    disp('Done.')
end

% Show plot (only in prompt mode)
if prompt
    figure;
    plot(drifts);
    title(['Drifts between eeg triggers and log events, ', bvfile]);
    xlabel('log event no.');
    ylabel('drift (samples)');
    disp('Note: Drifts are to be expected if amounts of triggers don''t match.')
end

end

function [newevent, bad_log_ind, bad_eeg_ind] = match_events(event, pres, tolerance, syncevent, prompt)

newevent = event;

if prompt
    disp('Matching coincident events...')
end

lkg_j = syncevent-1;
bad_log_ind = zeros;
for i = 1:length(pres.newlatency)
    % if no more event triggers in eeg, stop
    if lkg_j > length(newevent)
        disp(['Stopping at log index ', num2str(i)]);
        break;
    end
    for j = lkg_j+1:length(newevent)
        % a match (inside tolerance limits) and copy
        if abs(newevent(j).latency - pres.newlatency{i}) < tolerance
            % fun stuff bc of editeventvals function!
            if isnumeric(pres.code{i})
                newevent(j).type = int2str(pres.code{i});
            else
                newevent(j).type = pres.code{i};
            end
            newevent(j).code = pres.type{i};
            newevent(j).duration = pres.duration{i};
            % a new last known good index
            lkg_j = j;
            break;
        end;
        % way past useful tolerance -> give up
        if newevent(j).latency-pres.newlatency{i} > 50
            bad_log_ind = horzcat(bad_log_ind, i);
            if length(bad_log_ind) < 10
                disp(['Giving up on log index ', num2str(i)]);
            elseif length(bad_log_ind) == 10
                disp('...etc');
            elseif length(bad_log_ind) > 40
                disp('More than 40 unresolved log events: giving up.');
                newevent=[]; bad_log_ind=[]; bad_eeg_ind=[];
                return;
            end
            break;
        end;
    end;
end;

if prompt
    disp('Done.')
end

% Unresolved eeg triggers
bad_eeg_ind = zeros;
for i = syncevent:length(newevent)
    if newevent(i).duration == 1
        bad_eeg_ind = horzcat(bad_eeg_ind, i);
    end
end


disp(['There are ' int2str(length(bad_eeg_ind)-1) ' unresolved eeg triggers.'])
disp(['There are ' int2str(length(bad_log_ind)-1) ' unresolved log events.'])

end

function [add_ok, not_ok_mask] = check_adding(bad_log_ind, pres, tolerance)

% Calculate minimum distance to neighbours
min_dists = bad_log_ind;
for i = 2:length(bad_log_ind)
    j = bad_log_ind(i);
    if j < size(pres.newlatency,1) && j > 1
        lats = pres.newlatency(j-1:j+1);
        min_dists(i) = floor(min([lats{2}-lats{1} lats{3}-lats{2}]));
    end
end
add_ok = max(min_dists) < tolerance;

% Info and note the bad indices
if add_ok
    disp('All unresolved log events can be added to the data.')
    not_ok_mask = [];
else
    not_ok_mask = (min_dists>=tolerance);
    warning('%d log events cannot be added to the data.', sum(not_ok_mask));
    disp(pres(bad_log_ind(not_ok_mask),:));
end

end

function EEG = add_unresolved(EEG, bad_log_ind, syncevent, tolerance, pres, prompt)

badpres = pres(bad_log_ind(2:end),:);

if prompt
    disp('Adding unresolved events...');
end

% FIX THIS TO INCLUDE MULTIPLE ADDITIONS !!
% Add events with eeg-derived latencies
lkg_j = syncevent-1;
for i = 1:height(badpres)
    % if no more event triggers in eeg, stop
    if lkg_j > length(EEG.event)
        break;
    end
    for j = lkg_j+1:length(EEG.event)
        % a match --> add event
        if abs(EEG.event(j).latency - badpres.newlatency{i}) < tolerance
            eegtime = EEG.event(j).latency;
            row = badpres{i,:};
            % more fun stuff bc of editeventvals!
            code = row{3};
            if isnumeric(row{4}) type = int2str(row{4});
            else type = row{4}; end
            % index latency duration channel bvtime bvmknum type code
            EEG = pop_editeventvals(EEG, 'add', {j+1 eegtime/EEG.srate ...
                row{2}/EEG.srate 0 [] 0 type code});
            if prompt
                disp(['Event was added at latency ' int2str(eegtime) '.']);
            end
            % a new last known good index
            lkg_j = j-1;
            break;
        end;
        % way past useful tolerance -> give up
        if EEG.event(j).latency-badpres.newlatency{i} > 50
            disp('Trouble! This shouldn''t happen - event wasn''t added!');
            break;
        end;
    end;
end;

if prompt
    disp('Done.')
end

end