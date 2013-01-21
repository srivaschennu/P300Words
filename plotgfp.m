function plotgfp(stat,varargin)

colorlist = {
    'explicit'     [0         0    1.0000]
    'implicit'     [0    0.5000         0]
    'distractor'   [1.0000    0         0]
    };

param = finputcheck(varargin, { 'ylim', 'real', [], [-5 20]; ...
    'fontsize','integer', [], 26; ...
    'legendstrings', 'cell', {}, stat.condlist; ...
    'legendposition', 'string', {}, 'NorthEast'; ...
    });

%% figure plotting

fontname = 'Helvetica';
linewidth = 2;

figfile = sprintf('figures/%s_%s_%s-%s_gfp',stat.statmode,num2str(stat.subjinfo),stat.condlist{1},stat.condlist{2});

figure('Name',sprintf('%s-%s',stat.condlist{1},stat.condlist{2}),'Color','white','FileName',[figfile '.fig']);
figpos = get(gcf,'Position');
set(gcf,'Position',[figpos(1) figpos(2) figpos(3) figpos(3)]);

if isfield(stat,'pclust')
    latpnt = find(stat.times-stat.timeshift >= stat.pclust(1).win(1) & stat.times-stat.timeshift <= stat.pclust(end).win(2));
else
    latpnt = find(stat.times-stat.timeshift >= stat.param.latency(1) & stat.times-stat.timeshift <= stat.param.latency(2));
end
[~, maxidx] = max(stat.condgfp(1,latpnt,1),[],2);
plotpnt = latpnt(1)-1+maxidx;

for c = 1:length(stat.condlist)
    subplot(2,2,c);
    plotvals = stat.condavg(:,plotpnt,c);
    topoplot(plotvals,stat.chanlocs);
    if c == 1
        cscale = caxis;
    else
        caxis(cscale);
    end
    title(param.legendstrings{c},'FontSize',param.fontsize,'FontName',fontname);
    cb_h = colorbar('FontSize',param.fontsize);
    if c == 1
        cb_labels = num2cell(get(cb_h,'YTickLabel'),2);
        cb_labels{1} = [cb_labels{1} ' uV'];
        set(cb_h,'YTickLabel',cb_labels);
    end
end


subplot(2,2,3:4);
curcolororder = get(gca,'ColorOrder');
colororder = zeros(length(param.legendstrings),3);
for str = 1:length(param.legendstrings)
    cidx = strcmp(param.legendstrings{str},colorlist(:,1));
    if sum(cidx) == 1
        colororder(str,:) = colorlist{cidx,2};
    else
        colororder(str,:) = curcolororder(str,:);
    end
end

set(gca,'ColorOrder',cat(1,colororder,[0 0 0]));
hold all;
plot((stat.times(1):1000/stat.srate:stat.times(end))-stat.timeshift,squeeze(stat.condgfp(1,:,:)),'LineWidth',linewidth*1.5);
%plot((stat.times(1):1000/stat.srate:stat.times(end))-stat.timeshift,stat.gfpdiff(1,:),'LineWidth',linewidth*1.5);
%param.legendstrings{end+1} = 'difference';

set(gca,'XLim',[stat.times(1) stat.times(end)]-stat.timeshift,'XTick',stat.times(1)-stat.timeshift:200:stat.times(end)-stat.timeshift,'YLim',param.ylim,...
    'FontSize',param.fontsize,'FontName',fontname);
line([0 0],param.ylim,'Color','black','LineStyle',':','LineWidth',linewidth);
line([stat.times(1) stat.times(end)]-stat.timeshift,[0 0],'Color','black','LineStyle',':','LineWidth',linewidth);
line([stat.times(plotpnt) stat.times(plotpnt)]-stat.timeshift,param.ylim,'Color','red','LineWidth',linewidth,'LineStyle','--');
xlabel('Time (ms) ','FontSize',param.fontsize,'FontName',fontname);
ylabel('Global field power ','FontSize',param.fontsize,'FontName',fontname);
legend(param.legendstrings,'Location',param.legendposition);
box on
title(sprintf('%dms', round(stat.times(plotpnt))),'FontSize',param.fontsize,'FontName',fontname);

%% plot clusters

if isfield(stat,'pclust')
    for p = 1:length(stat.pclust)
        line([stat.pclust(p).win(1) stat.pclust(p).win(2)],[0 0],'Color','blue','LineWidth',8);
        title(sprintf('%dms\nCluster t = %.2f, p = %.3f', round(stat.times(plotpnt)), stat.pclust(p).tstat, stat.pclust(p).prob),...
            'FontSize',param.fontsize,'FontName',fontname);
    end
else
    fprintf('No positive clusters found.\n');
end

% for n = 1:length(stat.nclust)
%     rectangle('Position',[stat.nclust(n).win(1) param.ylim(1) ...
%         stat.nclust(n).win(2)-stat.nclust(n).win(1) param.ylim(2)-param.ylim(1)],...
%         'EdgeColor','blue','LineWidth',linewidth,'LineStyle','--');
%     title(sprintf('Cluster t = %.2f, p = %.3f', stat.nclust(n).tstat, stat.nclust(n).prob),...
%         'FontSize',param.fontsize,'FontName',fontname);
% end

set(gcf,'Color','white');
%saveas(gcf,[figfile '.fig']);
export_fig(gcf,[figfile '.eps']);
