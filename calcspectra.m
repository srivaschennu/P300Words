function calcspectra(basename)

loadpaths

freqlist = [

    0.5000    3.0000
    3.0000    7.0000
    7.0000   13.0000
   13.0000   25.0000
   25.0000   40.0000
   ];

EEG = pop_loadset([filepath basename '.set']);
chanlocs = EEG.chanlocs;

[spectra,freqs,speccomp,contrib,specstd] = pop_spectopo(EEG,1,[],'EEG','plot','off','percent',100);

for f = 1:size(freqlist,1)
    bandpower(f) = mean(mean(spectra(:,freqs >= freqlist(f,1) & freqs <= freqlist(f,2)),2));
end

save([basename '_spec.mat'], 'chanlocs', 'freqs', 'spectra', 'bandpower', 'specstd', 'freqlist');
