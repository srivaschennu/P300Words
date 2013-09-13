function plotgfp2(stats,varargin)

colorlist = {
    'explicit'     [0         0    1.0000]
    'implicit'     [0    0.5000         0]
    'distractor'   [1.0000    0         0]
    };

param = finputcheck(varargin, { 'ylim', 'real', [], [-5 15]; ...
    'fontsize','integer', [], 28; ...
    'legendstrings', 'cell', {}, stats{1}.condlist; ...
    'legendposition', 'string', {}, 'NorthWest'; ...
    'ttesttail', 'integer', [-1 0 1], 0; ...
    'plotinfo', 'string', {'on','off'}, 'on'; ...
    });

if ~isfield(stats{1},'inddata')
    stats{1}.inddata{1} = stats{1}.condavg(:,:,1);
    stats{1}.inddata{2} = stats{1}.condavg(:,:,2);
end

if ~isfield(stats{2},'inddata')
    stats{2}.inddata{1} = stats{2}.condavg(:,:,1);
    stats{2}.inddata{2} = stats{2}.condavg(:,:,2);
end

%% figure plotting

fontname = 'Helvetica';
linewidth = 2;

if length(stats{1}.condlist) == 2
    figname = sprintf('%s-%s',stats{1}.condlist{1},stats{1}.condlist{2});
else
    figname = sprintf('%s',stats{1}.condlist{1});
end
figfile = sprintf('figures/%s_%s_%s_gfp',stats{1}.statmode,num2str(stats{1}.subjinfo),figname);

figure('Name',figname,'Color','white','FileName',[figfile '.fig']);
figpos = get(gcf,'Position');
set(gcf,'Position',[figpos(1) figpos(2) figpos(3) figpos(3)]);


for s = 1:length(stats)
    
    if ~isempty(stats{s}.pclust)
        latpnt = find(stats{s}.times-stats{s}.timeshift >= stats{s}.pclust(1).win(1) & stats{s}.times-stats{s}.timeshift <= stats{s}.pclust(end).win(2));
    else
        latpnt = find(stats{s}.times-stats{s}.timeshift >= stats{s}.param.latency(1) & stats{s}.times-stats{s}.timeshift <= stats{s}.param.latency(2));
    end
    
    %pick time point at max of condition 1
    [~, maxidx] = max(stats{s}.condgfp(1,latpnt,1),[],2);
    
    %pick time point at max of difference
    %[~, maxidx] = max(stats{s}.gfpdiff(1,latpnt),[],2);
    
    stats{s}.plotpnt = latpnt(1)-1+maxidx;
    
    subplot(2,2,s);
    plotvals = mean(stats{s}.inddata{1}(:,stats{s}.plotpnt,:),3);
    topoplot(plotvals,stats{s}.chanlocs);
    cb_h = colorbar('FontSize',param.fontsize);
    if s == 1
        cb_labels = num2cell(get(cb_h,'YTickLabel'),2);
        cb_labels{1} = [cb_labels{1} ' uV'];
        set(cb_h,'YTickLabel',cb_labels);
    end
    
    if ~isempty(stats{s}.pclust)
        text(0,-0.9,sprintf('%dms\nt = %.1f, p = %.2f',round(stats{s}.times(stats{s}.plotpnt)),stats{s}.pclust(1).tstat, stats{s}.pclust(1).prob),...
            'FontSize',param.fontsize,'FontName',fontname,'HorizontalAlignment','center');
    else
        text(0,-0.9,sprintf('%dms',round(stats{s}.times(stats{s}.plotpnt))),...
            'FontSize',param.fontsize,'FontName',fontname,'HorizontalAlignment','center');
        %         text(0,-0.9,sprintf('%dms\nt = %.2f, p = %.2f',round(stats{s}.times(stats{s}.plotpnt)),stats{s}.valu(stats{s}.plotpnt),stats{s}.pprob(stats{s}.plotpnt)),...
        %             'FontSize',param.fontsize,'FontName',fontname,'HorizontalAlignment','center');
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

plotdata = squeeze(stats{1}.condgfp(1,:,1));
%plotdata = stats{1}.gfpdiff(1,:);
%param.legendstrings{end+1} = 'difference';

if strcmp(stats{1}.statmode,'trial')
    plot((stats{1}.times(1):1000/stats{1}.srate:stats{1}.times(end))-stats{1}.timeshift,plotdata,'LineWidth',linewidth*1.5);
elseif strcmp(stats{1}.statmode,'cond') || strcmp(stats{1}.statmode,'subj')
    H = shadedErrorBar((stats{1}.times(1):1000/stats{1}.srate:stats{1}.times(end))-stats{1}.timeshift,plotdata(1,:),...
        std(stats{1}.indgfp{1}'),{'LineWidth',linewidth*1.5,'Color',colororder(1,:)});
    hAnnotation = get(H.patch,'Annotation');
    hLegendEntry = get(hAnnotation','LegendInformation');
    set(hLegendEntry,'IconDisplayStyle','off');
    for e = 1:length(H.edge)
        hAnnotation = get(H.edge(e),'Annotation');
        hLegendEntry = get(hAnnotation','LegendInformation');
        set(hLegendEntry,'IconDisplayStyle','off');
    end
    
%     if length(stats{1}.condlist) == 2
%         H = shadedErrorBar((stats{1}.times(1):1000/stats{1}.srate:stats{1}.times(end))-stats{1}.timeshift,plotdata(2,:),...
%             std(stats{1}.indgfp{2}'),{'LineWidth',linewidth*1.5,'Color',colororder(2,:)});
%         hAnnotation = get(H.patch,'Annotation');
%         hLegendEntry = get(hAnnotation','LegendInformation');
%         set(hLegendEntry,'IconDisplayStyle','off');
%         for e = 1:length(H.edge)
%             hAnnotation = get(H.edge(e),'Annotation');
%             hLegendEntry = get(hAnnotation','LegendInformation');
%             set(hLegendEntry,'IconDisplayStyle','off');
%         end
%     end
end

set(gca,'XLim',[stats{1}.times(1) stats{1}.times(end)]-stats{1}.timeshift,'XTick',stats{1}.times(1)-stats{1}.timeshift:200:stats{1}.times(end)-stats{1}.timeshift,'YLim',param.ylim,...
    'FontSize',param.fontsize,'FontName',fontname);
line([0 0],param.ylim,'Color','black','LineStyle',':','LineWidth',linewidth);
line([stats{1}.times(1) stats{1}.times(end)]-stats{1}.timeshift,[0 0],'Color','black','LineStyle',':','LineWidth',linewidth);

if strcmp(param.plotinfo,'on')
    xlabel('Time (ms) ','FontSize',param.fontsize,'FontName',fontname);
    ylabel('Global field power ','FontSize',param.fontsize,'FontName',fontname);
else
    xlabel(' ','FontSize',param.fontsize,'FontName',fontname);
    ylabel(' ','FontSize',param.fontsize,'FontName',fontname);
end
legend(param.legendstrings,'Location',param.legendposition);

%% plot clusters

for s = 1:length(stats)
    line([stats{s}.times(stats{s}.plotpnt) stats{s}.times(stats{s}.plotpnt)]-stats{s}.timeshift,param.ylim,'Color','red','LineWidth',linewidth,'LineStyle','--');
    if param.ttesttail >= 0
        if ~isempty(stats{s}.pclust)
            for p = 1:length(stats{s}.pclust)
                line([stats{s}.pclust(p).win(1) stats{s}.pclust(p).win(2)],[0 0],'Color','blue','LineWidth',8);
            end
        end
    end
    
    if param.ttesttail <= 0
        if ~isempty(stats{s}.nclust)
            for p = 1:length(stats{s}.nclust)
                line([stats{s}.nclust(n).win(1) stats{s}.nclust(n).win(2)],[0 0],'Color','red','LineWidth',8);
            end
        end
    end
end

set(gcf,'Color','white');
%saveas(gcf,[figfile '.fig']);
export_fig(gcf,[figfile '.eps']);
