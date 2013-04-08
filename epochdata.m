function EEG = epochdata(basename,icamode)

if ~exist('icamode','var') || isempty(icamode)
    icamode = false;
end
keepica = true;

eventlist = {
    'TRG1'
    'TRG2'
    'DIST'
    };

loadpaths

if ischar(basename)
    EEG = pop_loadset('filename', [basename '_orig.set'], 'filepath', filepath);
else
    EEG = basename;
end

fprintf('Retaining only first 20 epochs.\n');
bendevents = EEG.event(strcmp('BEND',{EEG.event.type}));
for b = 1:length(bendevents)
    bendcodes = bendevents(b).codes;
    if bendcodes{strcmp('BNUM',bendcodes(:,1)),2} == 20
        EEG = pop_select(EEG,'point',[1 bendevents(b).latency]);
    end
end

fprintf('Epoching and baselining.\n');

EEG = pop_epoch(EEG,eventlist,[-0.3 0.8]);

%EEG = eeg_detrend(EEG);

EEG = pop_rmbase(EEG, [EEG.times(1) 0]);

EEG = eeg_checkset(EEG);

if ischar(basename)
    EEG.setname = basename;
    
    if icamode
        EEG.filename = [basename '_epochs.set'];
    else
        EEG.filename = [basename '.set'];
    end
    
    if icamode == true && keepica == true && exist([filepath EEG.filename],'file') == 2
        oldEEG = pop_loadset('filepath',filepath,'filename',EEG.filename,'loadmode','info');
        if isfield(oldEEG,'icaweights') && ~isempty(oldEEG.icaweights)
            fprintf('Loading existing ICA info from %s%s.\n',filepath,EEG.filename);

            EEG.icaact = oldEEG.icaact;
            EEG.icawinv = oldEEG.icawinv;
            EEG.icasphere = oldEEG.icasphere;
            EEG.icaweights = oldEEG.icaweights;
            EEG.icachansind = oldEEG.icachansind;
            EEG.reject.gcompreject = oldEEG.reject.gcompreject;
            keepchan = [];
            for c = 1:length(EEG.chanlocs)
                if ismember({EEG.chanlocs(c).labels},{oldEEG.chanlocs.labels})
                    keepchan = [keepchan c];
                end
                EEG.chanlocs(c).badchan = 0;
            end
            rejchan = EEG.chanlocs(setdiff(1:length(EEG.chanlocs),keepchan));
            EEG = pop_select(EEG,'channel',keepchan);
            
            EEG.icaact = oldEEG.icaact;
            EEG.icawinv = oldEEG.icawinv;
            EEG.icasphere = oldEEG.icasphere;
            EEG.icaweights = oldEEG.icaweights;
            EEG.icachansind = oldEEG.icachansind;
            EEG.reject.gcompreject = oldEEG.reject.gcompreject;
            if isfield('oldEEG','rejchan')
                EEG.rejchan = oldEEG.rejchan;
            else
                EEG.rejchan = rejchan;
            end
            
        end
    end
    
    fprintf('Saving set %s%s.\n',filepath,EEG.filename);
    pop_saveset(EEG,'filename', EEG.filename, 'filepath', filepath);
end