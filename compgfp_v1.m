function stat = compgfp(subjinfo,condlist,varargin)

loadpaths

global chanidx

timeshift = 0; %milliseconds

param = finputcheck(varargin, {
    'numrand', 'integer', [], 1000; ...
    'latency', 'real', [], []; ...
    'chanlist', 'cell', {}, {}; ...
    'wori', 'cell', {}, cell(1,length(condlist)), ...
    });

if isempty(param.latency)
    param.latency = [0 EEG.times(end)-timeshift];
end

if isempty(param.chanlist)
    chanidx = [];
else
    for c = 1:length(param.chanlist)
        chanidx(c) = find(param.chanlist{c},{chanlocs.labels});
    end
end

%% SELECTION OF SUBJECTS AND LOADING OF DATA
loadsubj

if ischar(condlist)
    condlist = {condlist,'base'};
elseif iscell(condlist) && length(condlist) == 1
    condlist{2} = 'base';
end

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
    
    % rereference
    EEG = rereference(EEG,1);
    %
    %     %%%%% baseline correction relative to 5th tone
    %     bcwin = [-200 0];
    %     bcwin = bcwin+(timeshift*1000);
    %     EEG = pop_rmbase(EEG,bcwin);
    %     %%%%%
    
    % THIS ASSUMES THAT ALL DATASETS HAVE SAME NUMBER OF ELECTRODES
    if s == 1
        chanlocs = EEG.chanlocs;
        times = EEG.times - timeshift;
        corrwin = find(times >= param.latency(1) & times <= param.latency(2));
    end
    
    for c = 1:numcond
        if strcmp(subjcond{s,c},'base')
            selectevents = subjcond{s,1};
        else
            selectevents = subjcond{s,c};
        end
        selectsnum = 3:8;
        %selectpred = 1;
%         selectwori = param.wori{c};
        
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
        
%         if strcmp(statmode,'trial') && c == numcond
%             if conddata{s,1}.trials > conddata{s,2}.trials
%                 fprintf('Equalising trials in condition %s.\n',subjcond{s,1});
%                 randtrials = 1:conddata{s,1}.trials;%randperm(conddata{s,1}.trials);
%                 conddata{s,1} = pop_select(conddata{s,1},'trial',randtrials(1:conddata{s,2}.trials));
%             elseif conddata{s,2}.trials > conddata{s,1}.trials
%                 fprintf('Equalising trials in condition %s.\n',subjcond{s,2});
%                 randtrials = 1:conddata{s,2}.trials;%randperm(conddata{s,2}.trials);
%                 conddata{s,2} = pop_select(conddata{s,2},'trial',randtrials(1:conddata{s,1}.trials));
%             end
%         end
        
        if strcmp(subjcond{s,c},'base')
            conddata{s,c}.data(:,corrwin,:) = conddata{s,1}.data(:,1:length(corrwin),:);
        end
    end
end

if strcmp(statmode,'trial')
    cond1data = conddata{1}.data;
    cond2data = conddata{2}.data;
    mergedata = cat(3,conddata{1,1}.data,conddata{1,2}.data);
    condavg = cat(3,mean(cond1data,3),mean(cond2data,3));
    diffcond = mean(cond1data,3) - mean(cond2data,3);
    
elseif strcmp(statmode,'cond')
    cond1data = zeros(conddata{1,1}.pnts,numsubj);
    cond2data = zeros(conddata{1,2}.pnts,numsubj);
    condavg = zeros(conddata{1,1}.nbchan,conddata{1,1}.pnts,numcond,numsubj);
    
    for s = 1:numsubj
        cond1data(:,s) = calcgfp(mean(conddata{s,1}.data,3),EEG.times);
        cond2data(:,s) = calcgfp(mean(conddata{s,2}.data,3),EEG.times);
        condavg(:,:,1,s) = mean(conddata{s,1}.data,3);
        condavg(:,:,2,s) = mean(conddata{s,2}.data,3);
        
        if size(conddata,2) > 2
            condsub = calcgfp(mean(conddata{s,3}.data,3),EEG.times);
            cond1data(:,s) = cond1data(:,s) - condsub';
            cond2data(:,s) = cond2data(:,s) - condsub';
            condavg(:,:,1,s) = condavg(:,:,1,s) - mean(conddata{s,3}.data,3);
            condavg(:,:,2,s) = condavg(:,:,2,s) - mean(conddata{s,3}.data,3);
        end
    end
    mergedata = cat(2,cond1data,cond2data);
    diffcond = condavg(:,:,1,:) - condavg(:,:,2,:);
    condavg = mean(condavg,4);
    diffcond = mean(diffcond,4);
    
elseif strcmp(statmode,'subj')
    condavg = zeros(conddata{1,1}.nbchan,conddata{1,1}.pnts,numsubj);
    cond1data = zeros(conddata{1,1}.pnts,numsubj1);
    for s = 1:numsubj1
        cond1data(:,s) = calcgfp(mean(conddata{s,1}.data,3),EEG.times);
        condavg(:,:,s) = mean(conddata{s,1}.data,3);
        
        if size(conddata,2) > 1
            cond1sub = calcgfp(mean(conddata{s,2}.data,3),EEG.times);
            cond1data(:,s) = cond1data(:,s) - cond1sub';
            condavg(:,:,s) = condavg(:,:,s) - mean(conddata{s,2}.data,3);
        end
    end
    
    cond2data = zeros(conddata{numsubj1+1,1}.pnts,numsubj2);
    for s = 1:numsubj2
        cond2data(:,s) = calcgfp(mean(conddata{numsubj1+s,1}.data,3),EEG.times);
        condavg(:,:,numsubj1+s) = mean(conddata{numsubj1+s,1}.data,3);
        
        if size(conddata,2) > 1
            cond2sub = calcgfp(mean(conddata{numsubj1+s,2}.data,3),EEG.times);
            cond2data(:,s) = cond2data(:,s) - cond2sub';
            condavg(:,:,numsubj1+s) = condavg(:,:,numsubj1+s) - mean(conddata{numsubj1+s,2}.data,3);
        end
    end
    
    mergedata = cat(2,cond1data,cond2data);
    diffcond = mean(condavg(:,:,1:numsubj1),3) - mean(condavg(:,:,numsubj1+1:end),3);
    condavg = cat(3,mean(condavg(:,:,1:numsubj1),3),mean(condavg(:,:,numsubj1+1:end),3));
end

gfpdiff = zeros(param.numrand+1,conddata{1,1}.pnts);
stat.condgfp = zeros(param.numrand+1,conddata{1,1}.pnts,numcond);
stat.cond1data = cond1data;
stat.cond2data = cond2data;

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

stat.valu = zeros(1,size(gfpdiff,2));
stat.pprob = ones(1,size(gfpdiff,2));
stat.nprob = ones(1,size(gfpdiff,2));
stat.pdist = max(gfpdiff(2:end,corrwin),[],2);
stat.ndist = min(gfpdiff(2:end,corrwin),[],2);

for p = corrwin
    stat.valu(p) = (gfpdiff(1,p) - mean(gfpdiff(2:end,p)))/(std(gfpdiff(2:end,p))/sqrt(size(gfpdiff,1)-1));
    stat.pprob(p) = sum(stat.pdist >= gfpdiff(1,p))/param.numrand;
    stat.nprob(p) = sum(stat.ndist <= gfpdiff(1,p))/param.numrand;
end

stat.gfpdiff = gfpdiff;
stat.condavg = condavg;
stat.diffcond = diffcond;
stat.times = EEG.times;
stat.condlist = condlist;
stat.timeshift = timeshift;
stat.subjinfo = subjinfo;
stat.statmode = statmode;
stat.param = param;
stat.chanlocs = chanlocs;
stat.srate = EEG.srate;

if nargout == 0
    save2file = sprintf('%s_%s_%s-%s_%d-%d_gfp.mat',statmode,num2str(subjinfo),...
        condlist{1},condlist{2},param.latency(1),param.latency(2));
    save(save2file,'stat');
end

function gfp = calcgfp(data,times)
%data in channels x timepoints

global chanidx
if isempty(chanidx)
    [~,gfp] = evalc('eeg_gfp(data'',0)''');
    gfp = rmbase(gfp,[],1:find(times == 0));
else
    gfp = mean(data(chanidx,:),1);
end