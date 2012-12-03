function batchrun(listnum)

loadpaths
loadsubj


subjlist = subjlists{listnum};

for s = 1:length(subjlist)
    basename = subjlist{s};
    batchres{s,1} = basename;
    EEG = pop_loadset('filepath',filepath,'filename',[basename '_orig.set'],'loadmode','info');
    fprintf('%s %s %d\n',basename,EEG.event(end).codes{1,1},EEG.event(end).codes{1,2});
    
    %     dataimport(basename);
    %     epochdata(basename,1);
    
    %   rejartifacts2([basename '_epochs'],1,4);
    
    %     computeic([basename '_epochs']);
    
%         rejectic(basename);
%         rejartifacts2(basename,2,3);
    
%     compgfp(basename,{'TRG1','DIST'},'latency',[200 700],'numrand',200);
%     load(['trial_' basename '_TRG1-DIST.mat']);
%     plotclusters(stat);
%     
%     compgfp(basename,{'TRG2','DIST'},'latency',[150 400],'numrand',200);
%     load(['trial_' basename '_TRG2-DIST.mat']);
%     plotclusters(stat);
%     
%     compgfp(basename,{'TRG1','TRG2'},'latency',[200 700],'numrand',200);
%     load(['trial_' basename '_TRG1-TRG2.mat']);
%     plotclusters(stat);
%     
%     %     filenames = dir(sprintf('%s%s*', filepath, basename));
%     %     mfffiles = filenames(logical(cell2mat({filenames.isdir})));
%     %     filename = mfffiles.name;
%     %     info = read_mff_info([filepath filename]);
%     %
%     %     batchres{s,2} = info.date;
end
% [~,sortidx] = sort(batchres(:,2));
% batchres(sortidx,:)

%save(sprintf('batch %s.mat',datestr(now)),'batchres');