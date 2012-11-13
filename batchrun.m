function batchrun(listnum)

loadsubj

subjlist = subjlists{listnum};

for s = 1:length(subjlist)
    basename = subjlist{s};
    
    dataimport(basename);
    epochdata(basename);
    
    %rejartifacts2(basename,2,3);
    
end