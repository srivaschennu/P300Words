function plotgfpclusters(statgfp,stat,varargin)

colorlist = {
    'explicit'    [0         0    1.0000]
    'implicit'     [0    0.5000         0]
    'distractor'   [1.0000    0         0]
    };

param = finputcheck(varargin, {
    'legendstrings', 'cell', {}, statgfp.condlist; ...
    'legendposition', 'string', {}, 'NorthWest'; ...
    'ylim', 'real', [], [0 20]; ...
    'title','string', {}, ' '; ...
    });


fontname = 'Helvetica';
fontsize = 20;
linewidth = 2;

%% plot significant clusters

posclustidx = [];
if isfield(statgfp,'posclusters') && ~isempty(statgfp.posclusters)
    for cidx = 1:length(statgfp.posclusters)
        if statgfp.posclusters(cidx).prob < statgfp.cfg.alpha && isempty(posclustidx) ...
                || (~isempty(posclustidx) && statgfp.posclusters(cidx).prob < statgfp.posclusters(posclustidx).prob)
            posclustidx = cidx;
        end
    end
end

negclustidx = [];
if isfield(statgfp,'negclusters') && ~isempty(statgfp.negclusters)
    for cidx = 1:length(statgfp.negclusters)
        if statgfp.negclusters(cidx).prob < statgfp.cfg.alpha && isempty(negclustidx) ...
                || (~isempty(negclustidx) && statgfp.negclusters(cidx).prob < statgfp.negclusters(negclustidx).prob)
            negclustidx = cidx;
        end
    end
end

if statgfp.cfg.tail >= 0
    fprintf('Plotting positive clusters.\n');
    
    figfile = sprintf('figures/%s_%s_%s-%s_pos',statgfp.statmode,num2str(statgfp.subjinfo),statgfp.condlist{1},statgfp.condlist{2});
    figure('Name',sprintf('%s-%s: Positive Clusters',statgfp.condlist{1},statgfp.condlist{2}),'Color','white','FileName',[figfile '.fig']);
    figpos = get(gcf,'Position');
    figpos(4) = figpos(3);
    set(gcf,'Position',figpos);
    
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
    
    clust_t = statgfp.diffcond.avg(statgfp.diffcond.time >= statgfp.time(1) & statgfp.diffcond.time <= statgfp.time(end));
    if ~isempty(posclustidx)
        clust_t(~(statgfp.posclusterslabelmat == posclustidx)) = 0;
    end
    [~,maxidx] = max(clust_t);
    maxtime = find(statgfp.time(maxidx) == statgfp.diffcond.time);
    
    subplot(2,1,1);
    plotvals = stat.diffcond.avg(:,maxtime);
    topoplot(plotvals,stat.chanlocs);
    
    colorbar('FontName',fontname,'FontSize',fontsize);
    title(param.title,'FontName',fontname,'FontSize',fontsize);
    
    subplot(2,1,2);
    set(gca,'ColorOrder',cat(1,colororder,[0 0 0]));
    hold all;
    
    plot(statgfp.diffcond.time-statgfp.timeshift,[statgfp.diffcond.cond1avg statgfp.diffcond.cond2avg],'LineWidth',linewidth*1.5);
    %ylim = get(gca,'YLim');
    %ylim = ylim*2;
    ylim = param.ylim;
    set(gca,'YLim',ylim,'XLim',[statgfp.diffcond.time(1) statgfp.diffcond.time(end)]-statgfp.timeshift,'XTick',statgfp.diffcond.time(1)-statgfp.timeshift:0.2:statgfp.diffcond.time(end)-statgfp.timeshift,...
        'FontName',fontname,'FontSize',fontsize);
    legend(param.legendstrings,'Location',param.legendposition);
    
    line([statgfp.diffcond.time(1) statgfp.diffcond.time(end)]-statgfp.timeshift,[0 0],'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([-0.60 -0.60],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([-0.45 -0.45],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([-0.30 -0.30],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([-0.15 -0.15],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([    0     0],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([statgfp.diffcond.time(maxtime) statgfp.diffcond.time(maxtime)]-statgfp.timeshift,ylim,'LineWidth',linewidth,'LineStyle','--','Color','red');
    xlabel('Time relative to word onset (s) ','FontName',fontname,'FontSize',fontsize);
    ylabel('Global field power','FontName',fontname,'FontSize',fontsize);
    box on
    if ~isempty(posclustidx)
        clustwinidx = find(clust_t);
        %         rectangle('Position',[statgfp.time(clustwinidx(1))-statgfp.timeshift ylim(1) ...
        %             statgfp.time(clustwinidx(end))-statgfp.time(clustwinidx(1)) ylim(2)-ylim(1)],'LineStyle','--','EdgeColor','black','LineWidth',linewidth);
        line([statgfp.time(clustwinidx(1)) statgfp.time(clustwinidx(end))]-statgfp.timeshift,[0 0],'Color','blue','LineWidth',8);
        title(sprintf('Cluster @ %.3f sec (t = %.2f, p = %.3f)', statgfp.diffcond.time(maxtime)-statgfp.timeshift, statgfp.posclusters(posclustidx).clusterstat,statgfp.posclusters(posclustidx).prob),...
            'FontName',fontname,'FontSize',fontsize);
    else
        title(sprintf('%.3f sec', statgfp.diffcond.time(maxtime)-statgfp.timeshift),'FontName',fontname,'FontSize',fontsize);
    end
    set(gcf,'Color','white');
    export_fig(gcf,[figfile '.eps']);
else
    fprintf('No significant positive clusters found.\n');
end

% if statgfp.cfg.tail <= 0
%     fprintf('Plotting negative clusters.\n');
%     
%     figfile = sprintf('figures/%s_%s_%s-%s_neg',statgfp.statmode,num2str(statgfp.subjinfo),statgfp.condlist{1},statgfp.condlist{2});
%     figure('Name',sprintf('%s-%s: Negative Clusters',statgfp.condlist{1},statgfp.condlist{2}),'Color','white','FileName',[figfile '.fig']);
%     figpos = get(gcf,'Position');
%     figpos(4) = figpos(3);
%     set(gcf,'Position',figpos);
%     
%     curcolororder = get(gca,'ColorOrder');
%     colororder = zeros(length(param.legendstrings),3);
%     for str = 1:length(param.legendstrings)
%         cidx = strcmp(param.legendstrings{str},colorlist(:,1));
%         if sum(cidx) == 1
%             colororder(str,:) = colorlist{cidx,2};
%         else
%             colororder(str,:) = curcolororder(str,:);
%         end
%     end
%     
%     set(gca,'ColorOrder',cat(1,colororder,[0 0 0]));
%     hold all;
%     
%     clust_t = statgfp.diffcond.avg(:,find(min(abs(statgfp.diffcond.time-statgfp.cfg.latency(1))) == abs(statgfp.diffcond.time-statgfp.cfg.latency(1))):...
%         find(min(abs(statgfp.diffcond.time-statgfp.cfg.latency(2))) == abs(statgfp.diffcond.time-statgfp.cfg.latency(2))));
%     if ~isempty(negclustidx)
%         clust_t(~(statgfp.negclusterslabelmat == negclustidx)) = 0;
%     end
%     [~,minidx] = min(clust_t);
%     mintime = find(statgfp.time(minidx) == statgfp.diffcond.time);
%     
%     subplot(2,1,1);
%     plotvals = stat.diffcond.avg(:,mintime);
%     topoplot(plotvals,statgfp.chanlocs);
%     
%     colorbar('FontName',fontname,'FontSize',fontsize);
%     title(param.title,'FontName',fontname,'FontSize',fontsize);
%     
%     subplot(2,1,2);
%     set(gca,'ColorOrder',cat(1,colororder,[0 0 0]));
%     hold all;
%     
%     plot(statgfp.diffcond.time-statgfp.timeshift,[statgfp.diffcond.cond1avg(minchan,:); statgfp.diffcond.cond2avg(minchan,:)]','LineWidth',linewidth*1.5);
%     %ylim = get(gca,'YLim');
%     %ylim = ylim*2;
%     ylim = param.ylim;
%     set(gca,'YLim',ylim,'XLim',[statgfp.diffcond.time(1) statgfp.diffcond.time(end)]-statgfp.timeshift,'XTick',statgfp.diffcond.time(1)-statgfp.timeshift:0.2:statgfp.diffcond.time(end)-statgfp.timeshift,...
%         'FontName',fontname,'FontSize',fontsize);
%     legend(param.legendstrings,'Location',param.legendposition);
%     line([statgfp.diffcond.time(1) statgfp.diffcond.time(end)]-statgfp.timeshift,[0 0],'LineWidth',linewidth,'Color','black','LineStyle',':');
%     line([-0.60 -0.60],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
%     line([-0.45 -0.45],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
%     line([-0.30 -0.30],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
%     line([-0.15 -0.15],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
%     line([    0     0],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
%     line([statgfp.diffcond.time(mintime) statgfp.diffcond.time(mintime)]-statgfp.timeshift,ylim,'LineWidth',linewidth,'LineStyle','--','Color','red');
%     xlabel('Time relative to 5th tone (sec) ','FontName',fontname,'FontSize',fontsize);
%     ylabel('Amplitude (uV)','FontName',fontname,'FontSize',fontsize);
%     box on
%     if ~isempty(negclustidx)
%         clustwinidx = find(minval);
%         %         rectangle('Position',[statgfp.time(clustwinidx(1))-statgfp.timeshift ylim(1) ...
%         %             statgfp.time(clustwinidx(end))-statgfp.time(clustwinidx(1)) ylim(2)-ylim(1)],'EdgeColor','black','LineStyle','--','LineWidth',linewidth);
%         line([statgfp.time(clustwinidx(1)) statgfp.time(clustwinidx(end))]-statgfp.timeshift,[0 0],'Color','blue','LineWidth',8);
%         title(sprintf('Cluster @ %.3f sec (t = %.2f, p = %.3f)', statgfp.diffcond.time(mintime)-statgfp.timeshift, statgfp.negclusters(negclustidx).clusterstat,statgfp.negclusters(negclustidx).prob),...
%             'FontName',fontname,'FontSize',fontsize);
%     else
%         title(sprintf('%.3f sec', statgfp.diffcond.time(mintime)-statgfp.timeshift),'FontName',fontname,'FontSize',fontsize);
%     end
%     set(gcf,'Color','white');
%     export_fig(gcf,[figfile '.eps']);
% else
%     fprintf('No significant negative clusters found.\n');
% end