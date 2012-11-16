function batchrun(listnum)

loadpaths
loadsubj


subjlist = subjlists{listnum};

for s = 1:length(subjlist)
    basename = subjlist{s};
    batchres{s,1} = basename;
    

%     dataimport(basename);
%     epochdata(basename,1);
    
%   rejartifacts2([basename '_epochs'],1,4);
    
    computeic([basename '_epochs']);

%     rejectic(basename);
%     rejartifacts2(basename,2,3);
    
%     compgfp(basename,{'TRG1','DIST'},'latency',[300 800],'numrand',200);
%     compgfp(basename,{'TRG2','DIST'},'latency',[200 400],'numrand',200);

%     filenames = dir(sprintf('%s%s*', filepath, basename));
%     mfffiles = filenames(logical(cell2mat({filenames.isdir})));
%     filename = mfffiles.name;
%     info = read_mff_info([filepath filename]);
%     
%     batchres{s,2} = info.date;
end
% [~,sortidx] = sort(batchres(:,2));
% batchres(sortidx,:)