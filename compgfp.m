function stat = compgfp(subjinfo,condlist,varargin)

global chanlocs

loadpaths

timeshift = 0; %milliseconds

colorlist = {
    'local standard'    [0         0    1.0000]
    'local deviant'     [0    0.5000         0]
    'global standard'   [1.0000    0         0]
    'global deviant'    [0    0.7500    0.7500]
    'inter-aural dev.'  [0.7500    0    0.7500]
    'inter-aural ctrl.' [0.7500    0.7500    0]
    'attend tones'      [0    0.5000    0.5000]
    'attend sequences'  [0.5000    0    0.5000]
    'attend visual'     [0    0.2500    0.7500]
    'early glo. std.'   [0.5000    0.5000    0]
    'late glo. std.'    [0.2500    0.5000    0]
    };

param = finputcheck(varargin, { 'ylim', 'real', [], [-5 20]; ...
    'alpha' , 'real' , [], 0.05; ...
    'numrand', 'integer', [], 1000; ...
    'corrp', 'string', {'none','fdr','cluster'}, 'cluster'; ...
    'latency', 'real', [], []; ...
    'clustsize', 'integer', [], 10; ...
    'fontsize','integer', [], 20; ...
    'legendstrings', 'cell', {}, condlist; ...
    });

%% SELECTION OF SUBJECTS AND LOADING OF DATA
loadsubj

if ischar(subjinfo)
    %%%% perform single-trial statistics
    subjlist = {subjinfo};
    subjcond = condlist;
    statmode = 'trial';
    
elseif isnumeric(subjinfo) && length(subjinfo) == 1
    %%%% perform within-subject statistics
    subjlist = subjlists{subjinfo};
    subjcond = repmat(condlist,length(subjlist),1);
    if length(condlist) == 3
        condlist = {sprintf('%s-%s',condlist{1},condlist{3}),sprintf('%s-%s',condlist{2},condlist{3})};
    end
    statmode = 'cond';
    
elseif isnumeric(subjinfo) && length(subjinfo) == 2
    %%%% perform across-subject statistics
    subjlist1 = subjlists{subjinfo(1)};
    subjlist2 = subjlists{subjinfo(2)};
    
    numsubj1 = length(subjlist1);
    numsubj2 = length(subjlist2);
    subjlist = cat(1,subjlist1,subjlist2);
    subjcond = cat(1,repmat(condlist(1),numsubj1,1),repmat(condlist(2),numsubj2,1));
    if length(condlist) == 3
        subjcond = cat(2,subjcond,repmat(condlist(3),numsubj1+numsubj2,1));
        condlist = {sprintf('%s-%s',condlist{1},condlist{3}),sprintf('%s-%s',condlist{2},condlist{3})};
    end
    statmode = 'subj';
end

numsubj = length(subjlist);
numcond = size(subjcond,2);

conddata = cell(numsubj,numcond);

%% load and prepare individual subject datasets

for s = 1:numsubj
    EEG = pop_loadset('filename', sprintf('%s.set', subjlist{s}), 'filepath', filepath);
    EEG = sortchan(EEG);
    
    % %     % rereference
    % EEG = rereference(EEG,1);
    %
    %     %%%%% baseline correction relative to 5th tone
    %     bcwin = [-200 0];
    %     bcwin = bcwin+(timeshift*1000);
    %     EEG = pop_rmbase(EEG,bcwin);
    %     %%%%%
    
    % THIS ASSUMES THAT ALL DATASETS HAVE SAME NUMBER OF ELECTRODES
    if s == 1
        chanlocs = EEG.chanlocs;
    end
    
    for c = 1:numcond
        selectevents = subjcond{s,c};
        selectsnum = 3;
        %selectpred = 1;
        
        typematches = false(1,length(EEG.epoch));
        snummatches = false(1,length(EEG.epoch));
        predmatches = false(1,length(EEG.epoch));
        for ep = 1:length(EEG.epoch)
            
            epochtype = EEG.epoch(ep).eventtype;
            if iscell(epochtype)
                epochtype = epochtype{cell2mat(EEG.epoch(ep).eventlatency) == 0};
            end
            if sum(strcmp(epochtype,selectevents)) > 0
                typematches(ep) = true;
            end
            
            epochcodes = EEG.epoch(ep).eventcodes;
            if iscell(epochcodes{1,1})
                epochcodes = epochcodes{cell2mat(EEG.epoch(ep).eventlatency) == 0};
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
        end
        
        selectepochs = find(typematches & snummatches & predmatches);
        fprintf('Condition %s: found %d matching epochs.\n',subjcond{s,c},length(selectepochs));
        
        conddata{s,c} = pop_select(EEG,'trial',selectepochs);
        
%                         if (strcmp(statmode,'trial') || strcmp(statmode,'cond')) && c == numcond
%                             if conddata{s,1}.trials > conddata{s,2}.trials
%                                 fprintf('Equalising trials in condition %s.\n',subjcond{s,1});
%                                 conddata{s,1} = pop_select(conddata{s,1},'trial',1:conddata{s,2}.trials);
%                             elseif conddata{s,2}.trials > conddata{s,1}.trials
%                                 fprintf('Equalising trials in condition %s.\n',subjcond{s,2});
%                                 conddata{s,2} = pop_select(conddata{s,2},'trial',1:conddata{s,1}.trials);
%                             end
%                         end
    end
end

if strcmp(statmode,'trial')
    cond1data = conddata{1}.data;
    cond2data = conddata{2}.data;
    mergedata = cat(3,conddata{1,1}.data,conddata{1,2}.data);
    diffcond = mean(cond1data,3) - mean(cond2data,3);
    
elseif strcmp(statmode,'cond')
    cond1data = zeros(conddata{1,1}.pnts,numsubj);
    cond2data = zeros(conddata{1,2}.pnts,numsubj);
    diffcond = zeros(conddata{1,1}.nbchan,conddata{1,1}.pnts,numcond,numsubj);
    
    for s = 1:numsubj
        cond1data(:,s) = calcgfp(mean(conddata{s,1}.data,3),EEG.times);
        cond2data(:,s) = calcgfp(mean(conddata{s,2}.data,3),EEG.times);
        diffcond(:,:,1,s) = mean(conddata{s,1}.data,3);
        diffcond(:,:,2,s) = mean(conddata{s,2}.data,3);
        
        if size(conddata,2) > 2
            condsub = calcgfp(mean(conddata{s,3}.data,3),EEG.times);
            cond1data(:,s) = cond1data(:,s) - condsub';
            cond2data(:,s) = cond2data(:,s) - condsub';
            diffcond(:,:,1,s) = diffcond(:,:,1,s) - mean(conddata{s,3}.data,3);
            diffcond(:,:,2,s) = diffcond(:,:,2,s) - mean(conddata{s,3}.data,3);
        end
    end
    mergedata = cat(2,cond1data,cond2data);
    diffcond = diffcond(:,:,1,:) - diffcond(:,:,2,:);
    diffcond = mean(diffcond,4);
    
elseif strcmp(statmode,'subj')
    diffcond = zeros(conddata{1,1}.nbchan,conddata{1,1}.pnts,numsubj);
    cond1data = zeros(conddata{1,1}.pnts,numsubj1);
    for s = 1:numsubj1
        cond1data(:,s) = calcgfp(mean(conddata{s,1}.data,3),EEG.times);
        diffcond(:,:,s) = mean(conddata{s,1}.data,3);
        
        if size(conddata,2) > 1
            cond1sub = calcgfp(mean(conddata{s,2}.data,3),EEG.times);
            cond1data(:,s) = cond1data(:,s) - cond1sub';
            diffcond(:,:,s) = diffcond(:,:,s) - mean(conddata{s,2}.data,3);
        end
    end
    
    cond2data = zeros(conddata{numsubj1+1,1}.pnts,numsubj2);
    for s = 1:numsubj2
        cond2data(:,s) = calcgfp(mean(conddata{numsubj1+s,1}.data,3),EEG.times);
        diffcond(:,:,numsubj1+s) = mean(conddata{numsubj1+s,1}.data,3);
        
        if size(conddata,2) > 1
            cond2sub = calcgfp(mean(conddata{numsubj1+s,2}.data,3),EEG.times);
            cond2data(:,s) = cond2data(:,s) - cond2sub';
            diffcond(:,:,numsubj1+s) = diffcond(:,:,numsubj1+s) - mean(conddata{numsubj1+s,2}.data,3);
        end
    end
    
    mergedata = cat(2,cond1data,cond2data);
    diffcond = mean(diffcond(:,:,1:numsubj1),3) - mean(diffcond(:,:,numsubj1+1:end),3);
end

gfpdiff = zeros(param.numrand+1,conddata{1,1}.pnts);
stat.condgfp = zeros(param.numrand+1,conddata{1,1}.pnts,numcond);

h_wait = waitbar(0,'Please wait...');
set(h_wait,'Name',[mfilename ' progress']);

for n = 1:param.numrand+1
    
    if strcmp(statmode,'trial')
        if n > 1
            waitbar((n-1)/param.numrand,h_wait,sprintf('Permutation %d...',n-1));
            mergedata = mergedata(:,:,randperm(size(mergedata,3)));
            cond1data = mergedata(:,:,1:size(cond1data,3));
            cond2data = mergedata(:,:,size(cond1data,3)+1:end);
        end
        
        cond1gfp = calcgfp(mean(cond1data,3),EEG.times);
        cond2gfp = calcgfp(mean(cond2data,3),EEG.times);
        gfpdiff(n,:) = cond1gfp - cond2gfp;
        
    elseif strcmp(statmode,'cond')
        if n > 1
            waitbar((n-1)/param.numrand,h_wait,sprintf('Permutation %d...',n-1));
            mergedata = mergedata(:,randperm(size(mergedata,2)));
            cond1data(:,:) = mergedata(:,1:numsubj);
            cond2data(:,:) = mergedata(:,numsubj+1:end);
        end
        
        cond1gfp = mean(cond1data,2);
        cond2gfp = mean(cond2data,2);
        gfpdiff(n,:) = mean(cond1data - cond2data,2);
        
    elseif strcmp(statmode,'subj')
        if n > 1
            waitbar((n-1)/param.numrand,h_wait,sprintf('Permutation %d...',n-1));
            mergedata = mergedata(:,randperm(size(mergedata,2)));
            cond1data(:,:) = mergedata(:,1:numsubj1);
            cond2data(:,:) = mergedata(:,numsubj1+1:end);
        end
        
        cond1gfp = mean(cond1data,2);
        cond2gfp = mean(cond2data,2);
        gfpdiff(n,:) = cond1gfp - cond2gfp;
    end
    stat.condgfp(n,:,1) = cond1gfp;
    stat.condgfp(n,:,2) = cond2gfp;
end
close(h_wait);

stat.gfpdiff = gfpdiff;
stat.times = EEG.times;

for p = 1:size(gfpdiff,2)
    stat.valu(p) = (gfpdiff(1,p) - mean(gfpdiff(2:end,p)))/(std(gfpdiff(2:end,p))/sqrt(size(gfpdiff,1)-1));
    stat.pprob(p) = sum(gfpdiff(2:end,p) >= gfpdiff(1,p))/param.numrand;
    stat.nprob(p) = sum(gfpdiff(2:end,p) <= gfpdiff(1,p))/param.numrand;
end

if isempty(param.latency)
    param.latency = [0 EEG.times(end)-timeshift];
end

times = EEG.times - timeshift;
corrwin = find(times >= param.latency(1) & times <= param.latency(2));
stat.pprob([1:corrwin(1)-1,corrwin(end)+1:end]) = 1;
stat.nprob([1:corrwin(1)-1,corrwin(end)+1:end]) = 1;

if strcmp(param.corrp,'fdr')
    % fdr correction
    stat.pmask = zeros(size(stat.pprob));
    [~,stat.pmask(corrwin)] = fdr(stat.pprob(corrwin),param.alpha);
    stat.pprob(~stat.pmask) = 1;
    
    stat.nmask = zeros(size(stat.nprob));
    [~,stat.nmask(corrwin)] = fdr(stat.nprob(corrwin),param.alpha);
    stat.nprob(~stat.nmask) = 1;
    
elseif strcmp(param.corrp,'cluster')
    %cluster-based pvalue correction
    nsigidx = find(stat.pprob >= param.alpha);
    for n = 1:length(nsigidx)-1
        if nsigidx(n+1)-nsigidx(n) > 1 && nsigidx(n+1)-nsigidx(n) < param.clustsize
            stat.pprob(nsigidx(n)+1:nsigidx(n+1)-1) = 1;
        end
    end
    
    nsigidx = find(stat.nprob >= param.alpha);
    for n = 1:length(nsigidx)-1
        if nsigidx(n+1)-nsigidx(n) > 1 && nsigidx(n+1)-nsigidx(n) < param.clustsize
            stat.nprob(nsigidx(n)+1:nsigidx(n+1)-1) = 1;
        end
    end
end


%% figure plotting

fontname = 'Helvetica';
linewidth = 2;

figfile = sprintf('figures/%s_%s_%s-%s_gfp',statmode,num2str(subjinfo),condlist{1},condlist{2});

figure('Name',sprintf('%s-%s',condlist{1},condlist{2}),'Color','white','FileName',[figfile '.fig']);
figpos = get(gcf,'Position');
set(gcf,'Position',[figpos(1) figpos(2) figpos(3) figpos(3)]);

subplot(2,1,1);
latpnt = find(EEG.times-timeshift >= param.latency(1) & EEG.times-timeshift <= param.latency(2));
[maxval, maxidx] = max(abs(gfpdiff(1,latpnt)),[],2);
[~, maxmaxidx] = max(maxval);
plotpnt = latpnt(1)-1+maxidx(maxmaxidx);

plotvals = diffcond(:,plotpnt);
topoplot(plotvals,chanlocs);
title(sprintf('%d ms',EEG.times(plotpnt)-timeshift),'FontSize',param.fontsize,'FontName',fontname);

subplot(2,1,2);

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
plot((EEG.times(1):1000/EEG.srate:EEG.times(end))-timeshift,squeeze(stat.condgfp(1,:,:)),'LineWidth',linewidth*1.5);
plot((EEG.times(1):1000/EEG.srate:EEG.times(end))-timeshift,gfpdiff(1,:),'LineWidth',linewidth*1.5);
param.legendstrings{end+1} = 'difference';

set(gca,'XLim',[EEG.times(1) EEG.times(end)]-timeshift,'XTick',EEG.times(1)-timeshift:200:EEG.times(end)-timeshift,'YLim',param.ylim,...
    'FontSize',param.fontsize,'FontName',fontname);
line([0 0],param.ylim,'Color','black','LineStyle',':','LineWidth',linewidth);
line([EEG.times(1) EEG.times(end)]-timeshift,[0 0],'Color','black','LineStyle',':','LineWidth',linewidth);
line([EEG.times(plotpnt) EEG.times(plotpnt)]-timeshift,param.ylim,'Color','black','LineWidth',linewidth,'LineStyle','--');
xlabel('Time (ms) ','FontSize',param.fontsize,'FontName',fontname);
ylabel('Global field power ','FontSize',param.fontsize,'FontName',fontname);
legend(param.legendstrings,'Location','NorthWest');
box on


%% identfy and plot clusters

pstart = 1; nstart = 1;
pclustidx = 0; nclustidx = 0;
for p = 2:EEG.pnts
    if stat.pprob(p) < param.alpha && stat.pprob(p-1) >= param.alpha
        pstart = p;
    elseif (stat.pprob(p) >= param.alpha || p == EEG.pnts) && stat.pprob(p-1) < param.alpha
        pend = p;
        
        pclustidx = pclustidx+1;
        stat.pclust(pclustidx).tstat = mean(stat.valu(pstart:pend-1));
        stat.pclust(pclustidx).prob = mean(stat.pprob(pstart:pend-1));
        stat.pclust(pclustidx).win = [EEG.times(pstart) EEG.times(pend-1)]-timeshift;
        
        rectangle('Position',[EEG.times(pstart)-timeshift param.ylim(1) ...
            EEG.times(pend)-EEG.times(pstart) param.ylim(2)-param.ylim(1)],...
            'EdgeColor','red','LineWidth',linewidth,'LineStyle','--');
        title(sprintf('Cluster t = %.2f, p = %.3f', stat.pclust(pclustidx).tstat, stat.pclust(pclustidx).prob),...
            'FontSize',param.fontsize,'FontName',fontname);
    end
    
    if stat.nprob(p) < param.alpha && stat.nprob(p-1) >= param.alpha
        nstart = p;
    elseif (stat.nprob(p) >= param.alpha || p == EEG.pnts) && stat.nprob(p-1) < param.alpha
        nend = p;
        
        nclustidx = nclustidx+1;
        stat.nclust(nclustidx).tstat = mean(stat.valu(nstart:nend-1));
        stat.nclust(nclustidx).prob = mean(stat.pprob(nstart:nend-1));
        stat.nclust(nclustidx).win = [EEG.times(nstart) EEG.times(nend-1)]-timeshift;
        
        rectangle('Position',[times(nstart) param.ylim(1) ...
            times(nend)-times(nstart) param.ylim(2)-param.ylim(1)],...
            'EdgeColor','blue','LineWidth',linewidth,'LineStyle','--');
        title(sprintf('Cluster t = %.2f, p = %.3f', stat.nclust(nclustidx).tstat, stat.nclust(nclustidx).prob),...
            'FontSize',param.fontsize,'FontName',fontname);
    end
end

set(gcf,'Color','white');
%saveas(gcf,[figfile '.fig']);
export_fig(gcf,[figfile '.eps']);

function gfp = calcgfp(data,times)
%data in channels x timepoints
[~,gfp] = evalc('eeg_gfp(data'')''');
gfp = rmbase(gfp,[],1:find(times == 0));

% global chanlocs
% 
% chanlist = {'E10'};
% chanidx = zeros(size(chanlist));
% for c = 1:length(chanlist)
%     chanidx(c) = find(strcmp(chanlist{c},{chanlocs.labels}));
% end
% gfp = mean(data(chanidx,:),1);