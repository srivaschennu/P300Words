function EEG = epochdata(basename,icamode)

if ~exist('icamode','var') || isempty(icamode)
    icamode = false;
end
keepica = false;

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

fprintf('Epoching and baselining.\n');

EEG = pop_epoch(EEG,eventlist,[-0.2 1]);

EEG = eeg_detrend(EEG);

EEG = pop_rmbase(EEG, [-200 0]);

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
        end
    end
    
    fprintf('Saving set %s%s.\n',filepath,EEG.filename);
    pop_saveset(EEG,'filename', EEG.filename, 'filepath', filepath);
end