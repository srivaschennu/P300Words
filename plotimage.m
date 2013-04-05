function plotimage(subjinfo,varargin)

loadpaths
loadsubj

param = finputcheck(varargin, { 'fontsize','integer', [], 22; ...
    });

%% figure plotting

fontname = 'Helvetica';
linewidth = 2;
ranklist = [0.5 0.4 0.3 0.2 0.1 0.01 0.001 0.0001];

subjlist = subjlists{subjinfo};

condlist = {'TRG1','TRG2','DIST'};

plotdata = zeros(length(subjlist),250,length(condlist));

for s = 1:length(subjlist)
    basename = subjlist{s};
    plotidx = 0;
    
    for c1 = 1:3
        for c2 = 1:3
            if c2 > c1
                load(sprintf('trial_%s_%s-%s_gfp.mat',basename,condlist{c1},condlist{c2}));
                stat.valu(stat.pprob >= stat.param.alpha) = 0;
                stat.pprob = rankvals(stat.pprob,ranklist);
                plotidx = plotidx+1;
                plotdata(s,:,plotidx) = stat.valu;
                plotorder{plotidx} = sprintf('%s-%s',condlist{c1},condlist{c2});
            end
        end
    end
    
end

for c = 1:size(plotdata,3)
    figure;
    figpos = get(gcf,'Position');
    figpos(4) = figpos(4)/3;
    set(gcf,'Position',figpos);
    
    imagesc(stat.times,1:length(subjlist),plotdata(:,:,c));
    %caxis([ranklist(end) ranklist(1)]);
    colorbar
    set(gca,'YDir','normal','XLim',[stat.times(1) stat.times(end)]-stat.timeshift,...
        'XTick',stat.times(1)-stat.timeshift:200:stat.times(end)-stat.timeshift,...
        'FontSize',param.fontsize,'FontName',fontname);
    
    line([0 0],ylim,'Color','black','LineStyle',':','LineWidth',linewidth);
    if c == 2
        xlabel('Time (ms) ','FontSize',param.fontsize,'FontName',fontname);
        ylabel('Participant ','FontSize',param.fontsize,'FontName',fontname);
    else
        xlabel('  ','FontSize',param.fontsize,'FontName',fontname);
        ylabel('  ','FontSize',param.fontsize,'FontName',fontname);
    end        
    box on
    figfile = sprintf('figures/img_%s_%s_tval',num2str(subjinfo),plotorder{c});
    set(gcf,'Color','white','Name',figfile,'FileName',figfile);
    export_fig(gcf,[figfile '.eps']);
end

function [pvals] = rankvals(pvals,ranklist)

pvals(pvals >= ranklist(1)) = 1;

for r = 2:length(ranklist)
    pvals(pvals < ranklist(r-1) & pvals >= ranklist(r)) = ranklist(r-1);
end
pvals(pvals < ranklist(end)) = ranklist(end);