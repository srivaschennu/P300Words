function batchrun(listnum)

loadsubj

subjlist = subjlists{listnum};

for s = 1:length(subjlist)
    basename = subjlist{s};
    
%     dataimport(basename);
    %epochdata(basename,1);
%rejartifacts2([basename '_epochs'],1,4,[],[],1000,500);
computeic([basename '_epochs']);
end