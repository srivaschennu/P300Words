function batchrun(listnum)

loadpaths
loadsubj


subjlist = subjlists{listnum};

for s = 1:length(subjlist)
    basename = subjlist{s};
    batchres{s,1} = basename;

%     dataimport(basename);
%     epochdata(basename,1);
    
%    rejartifacts2([basename '_epochs'],1,4);
    
    computeic([basename '_epochs']);
%     filenames = dir(sprintf('%s%s*', filepath, basename));
%     mfffiles = filenames(logical(cell2mat({filenames.isdir})));
%     filename = mfffiles.name;
%     info = read_mff_info([filepath filename]);
%     
%     batchres{s,2} = info.date;
end
% [~,sortidx] = sort(batchres(:,2));
% batchres(sortidx,:)