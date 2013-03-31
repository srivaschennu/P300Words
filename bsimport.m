function bsimport(statmode,subjinfo,condlist)
% Script generated by Brainstorm v3.1 (30-Nov-2012)

loadpaths
loadsubj

subjlist = subjlists{subjinfo};

% Input files
FileNamesA = [];

% Start a new report
bst_report('Start', FileNamesA);

for s = 1:length(subjlist)
    for c = 1:length(condlist)
        % Process: Import MEG/EEG: Events
        sFiles = bst_process(...
            'CallProcess', 'process_import_data_time', ...
            FileNamesA, [], ...
            'datafile', {{sprintf('%s%s_%s_%s.set',filepath,statmode,subjlist{s},condlist{c})}, 'EEG-EEGLAB', 'open', 'Import EEG/MEG recordings...', 'ImportData', 'multiple', 'files_and_dirs', {{'.meg4', '.res4'}, 'MEG/EEG: CTF (*.ds;*.meg4;*.res4)', 'CTF'; {'.fif'}, 'MEG/EEG: Neuromag FIFF (*.fif)', 'FIF'; {'.*'}, 'MEG/EEG: 4D-Neuroimaging/BTi (*.*)', '4D'; {'.lena', '.header'}, 'MEG/EEG: LENA (*.lena)', 'LENA'; {'.cnt'}, 'EEG: ANT EEProbe (*.cnt)', 'EEG-ANT-CNT'; {'.bdf'}, 'EEG: BDF (*.bdf)', 'EEG-BDF'; {'.eeg'}, 'EEG: BrainVision BrainAmp (*.eeg)', 'EEG-BRAINAMP'; {'.edf', '.rec'}, 'EEG: EDF / EDF+ (*.rec;*.edf)', 'EEG-EDF'; {'.set'}, 'EEG: EEGLAB (*.set)', 'EEG-EEGLAB'; {'.raw'}, 'EEG: EGI Netstation RAW (*.raw)', 'EEG-EGI-RAW'; {'.mb2'}, 'EEG: MANSCAN (*.mb2)', 'EEG-MANSCAN'; {'.cnt', '.avg', '.eeg'}, 'EEG: Neuroscan (*.cnt;*.eeg;*.avg)', 'EEG-NEUROSCAN'; {'.mat'}, 'NIRS: MFIP (*.mat)', 'NIRS-MFIP'}, 'DataIn'}, ...
            'subjectname', subjlist{s}, ...
            'condition', sprintf('cond_%d_%s',subjinfo,condlist{c}), ...
            'timewindow', [-0.2, 0.796], ...
            'split', 0, ...
            'channelalign', 0, ...
            'usectfcomp', 0, ...
            'usessp', 0, ...
            'freq', [], ...
            'baseline', []);

    end
end

% Save and display report
ReportFile = bst_report('Save', sFiles);
bst_report('Open', ReportFile);
