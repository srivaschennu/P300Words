function plotsrc(data,varargin)

fontsize = 26;
fontname = 'Helvetica';
linewidth = 2;
timeshift = 0;
scalefactor = 10^12;

figure;
figpos = get(gcf,'Position');
figpos(4) = figpos(3);
figpos(4) = round(figpos(4)/2);
set(gcf,'Position',[figpos(1) figpos(2) figpos(3)*length(data.F) figpos(4)]);

colorlist = {
    'explicit'     [0         0    1.0000]
    'implicit'     [0    0.5000         0]
    'distractor'   [1.0000    0         0]
    };

param = finputcheck(varargin, {
    'legendstrings', 'cell', {}, data.AxesLegend; ...
    'legendposition', 'string', {}, 'NorthWest'; ...
    'title','cell', {}, data.AxesTitle; ...
    'ylim', 'real', [], [0 50]; ...
    'plotlabels','string', {'on','off'}, 'on'; ...
    });


for i = 1:length(data.F)
    subplot(1,length(data.F),i);
    
    legendstrings = param.legendstrings{i};
    curcolororder = get(gca,'ColorOrder');
    colororder = zeros(length(legendstrings),3);
    for str = 1:length(legendstrings)
        cidx = strcmp(legendstrings{str},colorlist(:,1));
        if sum(cidx) == 1
            colororder(str,:) = colorlist{cidx,2};
        else
            colororder(str,:) = curcolororder(str,:);
        end
    end
    set(gca,'ColorOrder',colororder);
    hold all
    
    %remove baseline
    %data.F{i} = rmbase(data.F{i},[],find(data.Time-timeshift >= -0.2 & data.Time-timeshift <= 0));
    %data.F{i} = rmbase(data.F{i},[],find(data.Time >= -0.2 & data.Time <= 0));
    
    data.Time = data.Time*1000;
    
    plot(data.Time-timeshift,data.F{i}*scalefactor,'LineWidth',linewidth*1.5);
    set(gca,'YLim',param.ylim);
    set(gca,'XLim',[data.Time(1) data.Time(end)]-timeshift,...
        'XTick',data.Time(1)-timeshift:200:data.Time(end)-timeshift,...
        'FontName',fontname,'FontSize',fontsize);
    if ~strcmp(param.legendposition,'none')
        legend(legendstrings,'Location',param.legendposition);
    end
    line([data.Time(1) data.Time(end)]-timeshift,[0 0],'LineWidth',linewidth,'Color','black','LineStyle',':');
    line([    0     0],ylim,'LineWidth',linewidth,'Color','black','LineStyle',':');
    %line([param.plottime param.plottime],ylim,'LineWidth',linewidth','Color','red','LineStyle','--');
    if strcmp(param.plotlabels,'on')
        xlabel('Time (ms)','FontName',fontname,'FontSize',fontsize);
    else
        xlabel(' ','FontName',fontname,'FontSize',fontsize);
    end
    
    if strcmp(param.plotlabels,'on')
        ylabel('Activation (pA.m)','FontName',fontname,'FontSize',fontsize);
    else
        ylabel(' ','FontName',fontname,'FontSize',fontsize);
    end
    
    box on
    title(param.title{i},'FontName',fontname,'FontSize',fontsize);
    %title(' ','FontName',fontname,'FontSize',fontsize);
    
    %     timewin = [-0.6 0.2];
    %     timeidx = find(data.Time-timeshift >= timewin(1) & data.Time-timeshift <= timewin(2));
    %     dataslope = zeros(size(data.F{1},1),2);
    %     for d = 1:size(data.F{1},1)
    %         dataslope(d,:) = polyfit(data.Time(timeidx),data.F{1}(d,timeidx)*scalefactor,1);
    %         plot(data.Time-timeshift,polyval(dataslope(d,:),data.Time),...
    %             'LineWidth',2,'LineStyle','--');
    %     end
end
set(gcf,'Color','white','Name',data.AxesTitle{1},'FileName',['figures' filesep 'act_' data.FigTitle]);
export_fig(gcf,['figures' filesep 'act_' data.FigTitle '.eps']);
