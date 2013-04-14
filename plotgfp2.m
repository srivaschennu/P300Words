function plotgfp2(stat,varargin)

colorlist = {
    'explicit'     [0         0    1.0000]
    'implicit'     [0    0.5000         0]
    'distractor'   [1.0000    0         0]
    };

param = finputcheck(varargin, { 'ylim', 'real', [], [-5 15]; ...
    'fontsize','integer', [], 26; ...
    'legendstrings', 'cell', {}, stat(1).condlist; ...
    'legendposition', 'string', {}, 'NorthWest'; ...
    'ttesttail', 'integer', [-1 0 1], 0; ...
    'plotinfo', 'string', {'on','off'}, 'on'; ...
    });

%% figure plotting

fontname = 'Helvetica';
linewidth = 2;

figfile = sprintf('figures/%s_%s_%s-%s_gfp',stat(1).statmode,num2str(stat(1).subjinfo),stat(1).condlist{1},stat(1).condlist{2});

figure('Name',sprintf('%s-%s',stat(1).condlist{1},stat(1).condlist{2}),'Color','white','FileName',[figfile '.fig']);
figpos = get(gcf,'Position');
set(gcf,'Position',[figpos(1) figpos(2) figpos(3) figpos(3)]);


for s = 1:length(stat)
    latpnt = find(stat(s).times-stat(s).timeshift >= stat(s).param.latency(1) & stat(s).times-stat(s).timeshift <= stat(s).param.latency(2));
    %pick time point at max of condition 1
    [~, maxidx] = max(stat(s).condgfp(1,latpnt,1),[],2);

    %pick time point at max of difference
    %[~, maxidx] = max(stat(s).gfpdiff(1,latpnt),[],2);

    stat(s).plotpnt = latpnt(1)-1+maxidx;
    
    subplot(2,2,s);
    plotvals = stat(s).condavg(:,stat(s).plotpnt,1);
    topoplot(plotvals,stat(s).chanlocs);
    cb_h = colorbar('FontSize',param.fontsize);
    if s == 1
        cb_labels = num2cell(get(cb_h,'YTickLabel'),2);
        cb_labels{1} = [cb_labels{1} ' uV'];
        set(cb_h,'YTickLabel',cb_labels);
    end
    text(0,-0.9,sprintf('%dms\nt = %.2f, p = %.2f',round(stat(s).times(stat(s).plotpnt)),stat(s).valu(stat(s).plotpnt),stat(s).pprob(stat(s).plotpnt)),...
        'FontSize',param.fontsize,'FontName',fontname,'HorizontalAlignment','center');
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

plotdata = squeeze(stat(1).condgfp(1,:,1));
plot((stat(1).times(1):1000/stat(1).srate:stat(1).times(end))-stat(1).timeshift,plotdata,'LineWidth',linewidth*1.5);

set(gca,'XLim',[stat(1).times(1) stat(1).times(end)]-stat(1).timeshift,'XTick',stat(1).times(1)-stat(1).timeshift:200:stat(1).times(end)-stat(1).timeshift,'YLim',param.ylim,...
    'FontSize',param.fontsize,'FontName',fontname);
line([0 0],param.ylim,'Color','black','LineStyle',':','LineWidth',linewidth);
line([stat(1).times(1) stat(1).times(end)]-stat(1).timeshift,[0 0],'Color','black','LineStyle',':','LineWidth',linewidth);

if strcmp(param.plotinfo,'on')
    xlabel('Time (ms) ','FontSize',param.fontsize,'FontName',fontname);
    ylabel('Global field power ','FontSize',param.fontsize,'FontName',fontname);
else
    xlabel(' ','FontSize',param.fontsize,'FontName',fontname);
    ylabel(' ','FontSize',param.fontsize,'FontName',fontname);
end
legend(param.legendstrings,'Location',param.legendposition);

%% plot clusters

for s = 1:length(stat)
    line([stat(s).times(stat(s).plotpnt) stat(s).times(stat(s).plotpnt)]-stat(s).timeshift,param.ylim,'Color','red','LineWidth',linewidth,'LineStyle','--');
    if param.ttesttail >= 0
        if isfield(stat(s),'pclust')
            for p = 1:length(stat(s).pclust)
                line([stat(s).pclust(p).win(1) stat(s).pclust(p).win(2)],[0 0],'Color','blue','LineWidth',8);
            end
        end
    end
    
    if param.ttesttail <= 0
        if isfield(stat(s),'nclust')
            for n = 1:length(stat(s).nclust)
                line([stat(s).nclust(p).win(1) stat(s).nclust(p).win(2)],[0 0],'Color','red','LineWidth',8);
            end
        end
    end
end

set(gcf,'Color','white');
%saveas(gcf,[figfile '.fig']);
export_fig(gcf,[figfile '.eps']);
