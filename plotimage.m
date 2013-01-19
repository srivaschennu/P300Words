function plotimage(subjinfo)

loadpaths
loadsubj

subjlist = subjlists{subjinfo};

condlist = {'TRG1','TRG2','DIST'};

plotdata = zeros(length(subjlist),250,length(condlist));


for s = 1:length(subjlist)
    basename = subjlist{s};
    
    load(sprintf('trial_%s_%s-%s.mat',basename,condlist{1},condlist{3}));
    %stat.valu(stat.pprob == 1) = 0;
    plotdata(s,:,1) = stat.valu;
    
    load(sprintf('trial_%s_%s-%s.mat',basename,condlist{2},condlist{3}));
    %stat.valu(stat.pprob == 1) = 0;
    plotdata(s,:,2) = stat.valu;
    
    load(sprintf('trial_%s_%s-%s.mat',basename,condlist{1},condlist{2}));
    %stat.valu(stat.pprob == 1) = 0;
    plotdata(s,:,3) = stat.valu;
end

figure;
for c = 1:size(plotdata,3)
    subplot(3,1,c);
    imagesc(stat.times,1:length(subjlist),plotdata(:,:,c));
    colorbar
    set(gca,'YDir','normal');
end