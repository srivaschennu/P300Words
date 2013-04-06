function EEG = epochdata_base(basename,icamode)

if ~exist('icamode','var') || isempty(icamode)
    icamode = false;
end
keepica = true;

loadpaths

if ischar(basename)
    EEG = pop_loadset('filename', [basename '_orig.set'], 'filepath', filepath);
else
    EEG = basename;
end

fprintf('Renaming markers.\n');
prevbnum = 0;
for e = 1:length(EEG.event)
    switch EEG.event(e).type
        case {'TRG1','TRG2','DIST'}
            curbnum = EEG.event(e).codes{strcmp('BNUM',EEG.event(e).codes(:,1)),2};
            if curbnum <= 20 && curbnum >= prevbnum
                EEG.event(e).type = [EEG.event(e).type '_BASE'];
            else
                break
            end
            prevbnum = curbnum;
    end
end

eventlist = {
    'TRG1_BASE'
    'TRG2_BASE'
    'DIST_BASE'
    };

fprintf('Epoching and baselining.\n');

EEG = pop_epoch(EEG,eventlist,[-1 0]);

%EEG = eeg_detrend(EEG);

EEG = pop_rmbase(EEG, [-1000 -800]);

EEG = eeg_checkset(EEG);

if ischar(basename)
    EEG.setname = basename;
    
    if icamode
        EEG.filename = [basename '_base_epochs.set'];
        oldfilename = [basename '_epochs.set'];
    else
        EEG.filename = [basename '_base.set'];
    end
    
    if icamode == true && keepica == true && exist([filepath EEG.filename],'file') == 2
        oldEEG = pop_loadset('filepath',filepath,'filename',oldfilename,'loadmode','info');
        if isfield(oldEEG,'icaweights') && ~isempty(oldEEG.icaweights)
            fprintf('Loading existing ICA info from %s%s.\n',filepath,oldfilename);
            
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