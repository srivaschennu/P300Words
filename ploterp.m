function ploterp(subjinfo,condlist,varargin)

loadpaths

timeshift = 0; %milliseconds

param = finputcheck(varargin, { 'ylim', 'real', [], [-12 12]; ...
    'subcond', 'string', {'on','off'}, 'off'; ...
    'topowin', 'real', [], [400 700]; ...
    'fontsize','integer', [], 28; ...
    'plotinfo', 'string', {'on','off'}, 'on'; ...
    'caxis', 'real', [], 15; ...
    });

if isempty(param.topowin)
    param.topowin = [0 EEG.times(end)-timeshift];
end

%% SELECTION OF SUBJECTS AND LOADING OF DATA

loadsubj;

if ischar(subjinfo)
    %%%% perform single-trial statistics
    subjlist = {subjinfo};
    subjcond = condlist;
    statmode = 'trial';
    
elseif isnumeric(subjinfo) && length(subjinfo) == 1
    %%%% perform within-subject statistics
    subjlist = subjlists{subjinfo};
    subjcond = repmat(condlist,length(subjlist),1);
    statmode = 'cond';
end

numsubj = length(subjlist);
numcond = size(subjcond,2);

conddata = cell(numsubj,numcond);

%% load and prepare individual subject datasets

for s = 1:numsubj
    EEG = pop_loadset('filename', sprintf('%s.set', subjlist{s}), 'filepath', filepath);
    EEG = sortchan(EEG);
    
    %rereference
    EEG = rereference(EEG,1);
    
    %     %%%%% baseline correction relative to 5th tone
    %     bcwin = [-200 0];
    %     bcwin = bcwin+(timeshift*1000);
    %     EEG = pop_rmbase(EEG,bcwin);
    %     %%%%%
    
    % THIS ASSUMES THAT ALL DATASETS HAVE SAME NUMBER OF ELECTRODES
    if s == 1
        chanlocs = EEG.chanlocs;
        times = EEG.times;
        erpdata = zeros(EEG.nbchan,EEG.pnts,numcond,numsubj);
    end
    
    for c = 1:numcond
        selectevents = subjcond{s,c};
        selectsnum = 3:8;
        %selectpred = 1;
        %selectwnum = 2;
%         selectwori = [2 8]; %eccentric distractors
%         selectwori = [5]; %central distractors
        
        typematches = false(1,length(EEG.epoch));
        snummatches = false(1,length(EEG.epoch));
        predmatches = false(1,length(EEG.epoch));
        wnummatches = false(1,length(EEG.epoch));
        worimatches = false(1,length(EEG.epoch));
        
        for ep = 1:length(EEG.epoch)
            
            epochtype = EEG.epoch(ep).eventtype;
            if iscell(epochtype)
                if length(epochtype) > 1
                    epochtype = epochtype{cell2mat(EEG.epoch(ep).eventlatency) == 0};
                else
                    epochtype = epochtype{1};
                end
            end
            if sum(strncmp(epochtype,selectevents,length(selectevents))) > 0
                typematches(ep) = true;
            end
            
            epochcodes = EEG.epoch(ep).eventcodes;
            if ~isempty(epochcodes) && iscell(epochcodes{1})
                if length(epochcodes) > 1
                    epochcodes = epochcodes{cell2mat(EEG.epoch(ep).eventlatency) == 0};
                else
                    epochcodes = epochcodes{1};
                end
            end
            
            snumidx = strcmp('SNUM',epochcodes(:,1)');
            if exist('selectsnum','var') && ~isempty(selectsnum) && sum(snumidx) > 0
                if sum(epochcodes{snumidx,2} == selectsnum) > 0
                    snummatches(ep) = true;
                end
            else
                snummatches(ep) = true;
            end
            
            predidx = strcmp('PRED',epochcodes(:,1)');
            if exist('selectpred','var') && ~isempty(selectpred) && sum(predidx) > 0
                if sum(epochcodes{predidx,2} == selectpred) > 0
                    predmatches(ep) = true;
                end
            else
                predmatches(ep) = true;
            end

            wnumidx = strcmp('WNUM',epochcodes(:,1)');
            if exist('selectwnum','var') && ~isempty(selectwnum) && sum(wnumidx) > 0
                if sum(epochcodes{wnumidx,2} == selectwnum) > 0
                    wnummatches(ep) = true;
                end
            else
                wnummatches(ep) = true;
            end
            
            woriidx = strcmp('WORI',epochcodes(:,1)');
            if exist('selectwori','var') && ~isempty(selectwori) && sum(woriidx) > 0
                if sum(epochcodes{woriidx,2} == selectwori) > 0
                    worimatches(ep) = true;
                end
            else
                worimatches(ep) = true;
            end
        end
        
        selectepochs = find(typematches & snummatches & predmatches & wnummatches & worimatches);
        %selectepochs = find(typematches & snummatches & predmatches);
        fprintf('Condition %s: found %d matching epochs.\n',subjcond{s,c},length(selectepochs));
        
        conddata{s,c} = pop_select(EEG,'trial',selectepochs);
        conddata{s,c} = pop_editeventfield( conddata{s,c}, 'codes',[]);
        conddata{s,c} = pop_editeventfield( conddata{s,c}, 'init_index',[]);
        conddata{s,c} = pop_editeventfield( conddata{s,c}, 'init_time',[]);
        conddata{s,c}.setname = sprintf('%s_%s_%s',statmode,num2str(subjinfo),condlist{c});
        %pop_saveset(conddata{s,c},'filepath',filepath,'filename',[conddata{s,c}.setname '.set']);

        erpdata(:,:,c,s) = mean(conddata{s,c}.data,3);
%         erpdata(:,:,c,s) = valdasmean(conddata{s,c}.data,3);
    end
end

%% PLOTTING

if strcmp(param.subcond, 'on')
    for s = 1:size(erpdata,4)
        erpdata(:,:,1,s) = erpdata(:,:,1,s) - erpdata(:,:,2,s);
    end
    erpdata = erpdata(:,:,1,:);
    condlist = {sprintf('%s-%s',condlist{1},condlist{2})};
end

erpdata = mean(erpdata,4);

fontname = 'Helvetica';
linewidth = 2;
latpnt = find(EEG.times-timeshift >= param.topowin(1) & EEG.times-timeshift <= param.topowin(2));

for c = 1:size(erpdata,3)
    plotdata = erpdata(:,:,c);
        
    %plot ERP data
    figfile = sprintf('figures/%s_%s_%s_erp',statmode,num2str(subjinfo),condlist{c});
    
    figure('Name',condlist{c},'Color','white','FileName',[figfile '.fig']);
    figpos = get(gcf,'Position');
    set(gcf,'Position',[figpos(1) figpos(2) figpos(3) figpos(3)]);
    
    if size(param.topowin,1) == 1
        [maxval, maxidx] = max(plotdata(:,latpnt),[],2);
        [~, maxchan] = max(maxval);
        plotpnt = latpnt(1)-1+maxidx(maxchan);
        
        subplot(2,2,1:2);
        plotvals = plotdata(:,plotpnt);
        topoplot(plotvals,chanlocs);%,'emarker2',{maxchan,'o','green',14,1});
        cb_h = colorbar('FontSize',param.fontsize);
        cb_labels = num2cell(get(cb_h,'YTickLabel'),2);
        cb_labels{1} = [cb_labels{1} ' uV'];
        set(cb_h,'YTickLabel',cb_labels);
        text(0,-0.7,sprintf('%dms', round(times(plotpnt))),...
            'FontSize',param.fontsize,'FontName',fontname,'HorizontalAlignment','center');
    else
        for s = 1:size(param.topowin,1)
            latpnt = find(EEG.times-timeshift >= param.topowin(s,1) & EEG.times-timeshift <= param.topowin(s,2));
            [maxval, maxidx] = max(plotdata(:,latpnt),[],2);
            [~, maxchan] = max(maxval);
            plotpnt(s) = latpnt(1)-1+maxidx(maxchan);
            
            subplot(2,2,s);
            plotvals = plotdata(:,plotpnt(s));
            topoplot(plotvals,chanlocs);
            cb_h = colorbar('FontSize',param.fontsize);
            cb_labels = num2cell(get(cb_h,'YTickLabel'),2);
            cb_labels{1} = [cb_labels{1} ' uV'];
            set(cb_h,'YTickLabel',cb_labels);
            text(0,-0.7,sprintf('%dms', round(times(plotpnt(s)))),...
                'FontSize',param.fontsize,'FontName',fontname,'HorizontalAlignment','center');
        end
    end

    subplot(2,2,3:4);
    plot(times-timeshift,plotdata');

    set(gca,'XLim',[times(1) times(end)]-timeshift,'XTick',times(1)-timeshift:200:times(end)-timeshift,'YLim',param.ylim,...
        'FontSize',param.fontsize,'FontName',fontname);
    line([0 0],param.ylim,'Color','black','LineStyle',':','LineWidth',linewidth);
    line([times(1) times(end)]-timeshift,[0 0],'Color','black','LineStyle',':','LineWidth',linewidth);
    
    for s = 1:length(plotpnt)
        line([times(plotpnt(s)) times(plotpnt(s))]-timeshift,param.ylim,'Color','red','LineWidth',linewidth,'LineStyle','--');
    end
    
    if strcmp(param.plotinfo,'on')
        xlabel('Time (ms) ','FontSize',param.fontsize,'FontName',fontname);
        ylabel('Voltage ({\mu}V) ','FontSize',param.fontsize,'FontName',fontname);
    else
        xlabel(' ','FontSize',param.fontsize,'FontName',fontname);
        ylabel(' ','FontSize',param.fontsize,'FontName',fontname);
    end
    box off
    
%     subplot(3,2,5:6);
% %     imgdata = conddata{c}.data(maxchan,:,:);
%     imgdata = zeros(conddata{c}.pnts,conddata{c}.trials);
%     smoothwin = 3;
%     for t = 1:smoothwin:conddata{c}.trials-smoothwin+1
%         [~,imgdata(:,t)] = evalc('eeg_gfp(mean(conddata{c}.data(:,:,t:t+smoothwin-1),3)'',0)');
%         imgdata(:,t+1:t+smoothwin-1) = repmat(imgdata(:,t),1,smoothwin-1);
%     end
%     
%     [~,~,~,~,axhndls] = erpimage(imgdata, ones(1, conddata{c}.trials)*conddata{c}.xmax*1000,...
%         linspace(conddata{c}.xmin*1000, conddata{c}.xmax*1000, conddata{c}.pnts),...
%         '', 20, 1 , 'yerplabel', '', 'erp', 'off', 'cbar', 'on','caxis',[0 abs(param.caxis)]);
%     set(axhndls(1),'FontName',fontname,'FontSize',param.fontsize);
%     set(get(axhndls(1),'XLabel'),'String','Time (ms)','FontName',fontname,'FontSize',param.fontsize)
%     set(get(axhndls(1),'YLabel'),'String','Global field power','FontName',fontname,'FontSize',param.fontsize);
%     set(axhndls(2),'FontName',fontname,'FontSize',param.fontsize);
%     
    close(gcf);
    figure;
    timtopo(plotdata,chanlocs,...
        'limits',[EEG.times(1)-timeshift EEG.times(end)-timeshift, param.ylim],...
        'plottimes',times(plotpnt(s))-timeshift);
%     
%     saveEEG = EEG;robust
%     saveEEG.data = plotdata;
%     saveEEG.setname = sprintf('%s_%s_%s',statmode,num2str(subjinfo),condlist{c});
%     saveEEG.filename = [saveEEG.setname '.set'];
%     saveEEG.trials = 1;
%     saveEEG.event = saveEEG.event(1);
%     saveEEG.event(1).type = saveEEG.setname;
%     saveEEG.epoch = saveEEG.epoch(1);
%     saveEEG.epoch(1).eventtype = saveEEG.setname;
%     pop_saveset(saveEEG,'filepath',filepath,'filename',saveEEG.filename);    
    set(gcf,'Color','white');
    %saveas(gcf,[figfile '.fig']);
    export_fig(gcf,[figfile '.eps']);

end

% gadiff = diffdata{1};
% gadiff.data = erpdata(:,:,2)-erpdata(:,:,1);
% gadiff.setname = sprintf('%s-%s',condlist{2},condlist{1});
% pop_saveset(gadiff,'filepath',filepath,'filename',[gadiff.setname '.set']);