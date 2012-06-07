function compgfp(subjname,condlist,varargin)

loadpaths

if ~isempty(varargin) && ~isempty(varargin{1})
    alpha = varargin{1};
else
    alpha = 0.05;
end

timeshift = 0; %seconds
timeshift = timeshift * 1000;

conddata = cell(1,2);

EEG = pop_loadset('filename', sprintf('%s.set', subjname), 'filepath', filepath);

% %     % rereference
% EEG = rereference(EEG,1);
%
%     %%%%% baseline correction relative to 5th tone
%     bcwin = [-200 0];
%     bcwin = bcwin+(timeshift*1000);
%     EEG = pop_rmbase(EEG,bcwin);
%     %%%%%

for c = 1:2
    selectevents = condlist{c};
    
    typematches = false(1,length(EEG.epoch));
    for ep = 1:length(EEG.epoch)
        
        epochtype = EEG.epoch(ep).eventtype;
        if iscell(epochtype)
            epochtype = epochtype{cell2mat(EEG.epoch(ep).eventlatency) == 0};
        end
        if sum(strcmp(epochtype,selectevents)) > 0
            typematches(ep) = true;
        end
    end
    
    selectepochs = find(typematches);
    
    fprintf('Condition %s: found %d matching epochs.\n',condlist{c},length(selectepochs));
    
    if isempty(selectepochs)
        fprintf('Skipping...\n');
        return;
    end
    
    conddata{c} = pop_select(EEG,'trial',selectepochs);
end

numrand = 200;
cond1data = conddata{1}.data;
cond2data = conddata{2}.data;
mergedata = cat(3,conddata{1,1}.data,conddata{1,2}.data);

gfpdiff = zeros(numrand+1,EEG.pnts);
h_wait = waitbar(0,'Please wait...');
set(h_wait,'Name',[mfilename ' progress']);

for n = 1:numrand+1
    
    if n > 1
        waitbar((n-1)/numrand,h_wait,sprintf('Permutation %d...',n-1));
        mergedata = mergedata(:,:,randperm(size(mergedata,3)));
        cond1data = mergedata(:,:,1:size(cond1data,3));
        cond2data = mergedata(:,:,size(cond1data,3)+1:end);
    end

    [~, cond1gfp] = evalc('eeg_gfp(mean(cond1data,3)'')');
    [~, cond2gfp] = evalc('eeg_gfp(mean(cond2data,3)'')');

    gfpdiff(n,:) = cond1gfp - cond2gfp;
end
close(h_wait);

figure('Name',sprintf('%s %s: %s-%s',mfilename,subjname,condlist{1},condlist{2}),'Color','white');
figpos = get(gcf,'Position');
set(gcf,'Position',[figpos(1) figpos(2) figpos(3)*2 figpos(4)]);

hold all
plot(EEG.times-timeshift,eeg_gfp(mean(conddata{1}.data,3)'),'LineWidth',2,'DisplayName',condlist{1});
plot(EEG.times-timeshift,eeg_gfp(mean(conddata{2}.data,3)'),'LineWidth',2,'DisplayName',condlist{2});
plot(EEG.times-timeshift,gfpdiff(1,:),'LineWidth',2,'DisplayName',sprintf('%s-%s',condlist{2},condlist{1}));

set(gca,'XLim',[EEG.times(1) EEG.times(end)]-timeshift);
ylim = get(gca,'YLim');
xlabel('Time (ms)');
ylabel('GFP');
legend('show');

line([EEG.times(1) EEG.times(end)]-timeshift, [0 0],'Color','black','LineStyle',':','LineWidth',0.75);
line([0 0],ylim,'Color','black','LineStyle',':','LineWidth',0.75);

for p = 1:EEG.pnts
    stat.valu(p) = (gfpdiff(1,p) - mean(gfpdiff(2:end,p)))/std(gfpdiff(2:end,p));
    stat.pprob(p) = sum(gfpdiff(2:end,p) >= gfpdiff(1,p))/numrand;
    stat.nprob(p) = sum(gfpdiff(2:end,p) <= gfpdiff(1,p))/numrand;
end

% % fdr correction
% [~,stat.pmask] = fdr(stat.pprob,alpha);
% stat.pprob(~stat.pmask) = 1;
% 
% [~,stat.nmask] = fdr(stat.nprob,alpha);
% stat.nprob(~stat.nmask) = 1;


% cluster-based pvalue correction
minclustsize = 10;
nsigidx = find(stat.pprob >= alpha);
for n = 1:length(nsigidx)-1
    if nsigidx(n+1)-nsigidx(n) > 1 && nsigidx(n+1)-nsigidx(n) < minclustsize
        stat.pprob(nsigidx(n)+1:nsigidx(n+1)-1) = 1;
    end
end

nsigidx = find(stat.nprob >= alpha);
for n = 1:length(nsigidx)-1
    if nsigidx(n+1)-nsigidx(n) > 1 && nsigidx(n+1)-nsigidx(n) < minclustsize
        stat.nprob(nsigidx(n)+1:nsigidx(n+1)-1) = 1;
    end
end


for p = 1:EEG.pnts
    if stat.pprob(p) < alpha
        text(EEG.times(p)-timeshift,1,'+','FontSize',16,'FontWeight','bold');
    end
    if stat.nprob(p) < alpha
        text(EEG.times(p)-timeshift,-1,'-','FontSize',16,'FontWeight','bold');
    end
end
