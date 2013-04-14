function plotimage(subjinfo,varargin)

loadpaths
loadsubj

param = finputcheck(varargin, { 'fontsize','integer', [], 26; ...
    });

%% figure plotting

fontname = 'Helvetica';
linewidth = 2;
ranklist = [0.11 0.1 0.05 0.01 0.001];
ranklabel = {'','p < 0.1', 'p < 0.05', 'p < 0.01',''};
subjlist = subjlists{subjinfo};

condlist = {
    'TRG1' 'explicit'
    'TRG2' 'implicit'
    'DIST' 'distractor'
    };

timewin = {
    [100 400]
    [400 700]
    };

for s = 1:length(subjlist)
    basename = subjlist{s};
    plotidx = 0;
    
    for c = 1:size(condlist,1)
        plotidx = plotidx+1;
        
        load(sprintf('trial_%s_%s-base_%d-%d_gfp.mat',basename,condlist{c,1},timewin{1}(1),timewin{1}(2)));
        
        if s == 1 && c == 1
            plotdata = zeros(length(subjlist),length(stat.times),length(condlist));
        end
        if strcmp(condlist{c,1},'TRG1')
            stat2 = load(sprintf('trial_%s_%s-base_%d-%d_gfp.mat',basename,condlist{c,1},timewin{2}(1),timewin{2}(2)));
            stat.pprob(stat2.stat.times >= stat2.stat.param.latency(1) & stat2.stat.times <= stat2.stat.param.latency(2)) = ...
                stat2.stat.pprob(stat2.stat.times >= stat2.stat.param.latency(1) & stat2.stat.times <= stat2.stat.param.latency(2));
        end
        plotdata(s,:,plotidx) = 1-rankvals(stat.pprob,ranklist);
        plotinfo{plotidx} = sprintf('%s-base',condlist{c,1});
    end
end

for c = 1:size(plotdata,3)
    figure;
    figpos = get(gcf,'Position');
    figpos(4) = figpos(3);
    figpos(4) = figpos(4)/3;
    set(gcf,'Position',figpos);
    
    imagesc(stat.times,1:length(subjlist),plotdata(:,:,c));
    set(gca,'YDir','normal','XLim',[stat.times(1) stat.times(end)]-stat.timeshift,...
        'XTick',stat.times(1)-stat.timeshift:200:stat.times(end)-stat.timeshift,...
        'FontSize',param.fontsize,'FontName',fontname);
    
    caxis(1-[ranklist(1) ranklist(end)]);
    
    line([0 0],ylim,'Color','black','LineStyle',':','LineWidth',linewidth);
    if c == 1
        xlabel('Time (ms) ','FontSize',param.fontsize,'FontName',fontname);
        ylabel('Participant ','FontSize',param.fontsize,'FontName',fontname);
    else
        xlabel('  ','FontSize',param.fontsize,'FontName',fontname);
        ylabel('  ','FontSize',param.fontsize,'FontName',fontname);
    end
    figfile = sprintf('figures/img_%s_%s',num2str(subjinfo),plotinfo{c});
    set(gcf,'Color','white','Name',figfile,'FileName',figfile);
    export_fig(gcf,[figfile '.eps']);
end

figure;
figpos = get(gcf,'Position');
figpos(4) = figpos(3);
figpos(4) = figpos(4)/3;
set(gcf,'Position',figpos);
set(gca,'Visible','off');
cb_h=colorbar;
caxis(1-[ranklist(1) ranklist(end)]);
set(cb_h,'YTick',1-ranklist,'YTickLabel',ranklabel,...
    'FontSize',param.fontsize,'FontName',fontname);

figfile = sprintf('figures/img_colorbar',num2str(subjinfo),plotinfo{c});
set(gcf,'Color','white','Name',figfile,'FileName',figfile);
export_fig(gcf,[figfile '.eps']);

function [pvals] = rankvals(pvals,ranklist)

pvals(pvals >= ranklist(1)) = 1;

for r = 2:length(ranklist)
    pvals(pvals < ranklist(r-1) & pvals >= ranklist(r)) = ranklist(r-1);
end
pvals(pvals < ranklist(end)) = ranklist(end);