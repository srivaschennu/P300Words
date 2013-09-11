function stat = tct(subjinfo,condlist,varargin)

loadpaths

global chanidx

timeshift = 0; %milliseconds

param = finputcheck(varargin, {
    'numrand', 'integer', [], 1000; ...
    'latency', 'real', [], []; ...
    'chanlist', 'cell', {}, {}; ...
    'wori', 'cell', {}, cell(1,length(condlist)), ...
    });

if isempty(param.chanlist)
    chanidx = [];
else
    for c = 1:length(param.chanlist)
        chanidx(c) = find(param.chanlist{c},{chanlocs.labels});
    end
end

%% SELECTION OF SUBJECTS AND LOADING OF DATA
loadsubj

if ~iscell(condlist) || iscell(condlist) && length(condlist) ~= 1
    error('condlist must be a cell array with one string');
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
    statmode = 'cond';
    
elseif isnumeric(subjinfo) && length(subjinfo) == 2
    %%%% perform across-subject statistics
    subjlist1 = subjlists{subjinfo(1)};
    subjlist2 = subjlists{subjinfo(2)};
    
    numsubj1 = length(subjlist1);
    numsubj2 = length(subjlist2);
    subjlist = cat(1,subjlist1,subjlist2);
    subjcond = cat(1,repmat(condlist(1),numsubj1,1),repmat(condlist(2),numsubj2,1));
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
        
        
        if strcmp(subjcond{s,c},'base')
            conddata{s,c}.data(:,corrwin,:) = conddata{s,1}.data(:,1:length(corrwin),:);
        end
    end
end

if isempty(param.latency)
    param.latency = [0 EEG.times(end)-timeshift];
end

if strcmp(statmode,'trial')
    inddata{1} = conddata{1}.data;
    indgfp{1} = calcgfp(mean(inddata{1},3),EEG.times);
    
elseif strcmp(statmode,'cond')
    inddata{1} = zeros(conddata{1,1}.nbchan,conddata{1,1}.pnts,numsubj);
    indgfp{1} = zeros(conddata{1,1}.pnts,numsubj);
    
    for s = 1:numsubj
        inddata{1}(:,:,s) = mean(conddata{s,1}.data,3);
        indgfp{1}(:,s) = calcgfp(inddata{1}(:,:,s),EEG.times);
    end
    
elseif strcmp(statmode,'subj')
    inddata{1} = zeros(conddata{1,1}.nbchan,conddata{1,1}.pnts,numsubj1);
    indgfp{1} = zeros(conddata{1,1}.pnts,numsubj1);
    for s = 1:numsubj1
        inddata{1}(:,:,s) = mean(conddata{s,1}.data,3);
        indgfp{1}(:,s) = calcgfp(inddata{1}(:,:,s),EEG.times);
    end
end

stat.condgfp = zeros(param.numrand+1,conddata{1,1}.pnts,numcond);
stat.inddata = inddata;
stat.indgfp = indgfp;

h_wait = waitbar(0,'Please wait...');
set(h_wait,'Name',[mfilename ' progress']);

for n = 1:param.numrand+1
    if n > 1
        waitbar((n-1)/param.numrand,h_wait,sprintf('Permutation %d...',n-1));
        for s = 1:size(inddata{1},3)
            inddata{1}(:,:,s) = inddata{1}(randperm(size(inddata{1},1)),:,s);
        end
    end
    cond1gfp = calcgfp(mean(inddata{1},3),EEG.times);
    stat.condgfp(n,:,1) = cond1gfp;
end
close(h_wait);

stat.valu = zeros(1,size(stat.condgfp,2));
stat.pprob = ones(1,size(stat.condgfp,2));
stat.nprob = ones(1,size(stat.condgfp,2));
stat.pdist = max(stat.condgfp(2:end,corrwin),[],2);
stat.ndist = min(stat.condgfp(2:end,corrwin),[],2);

for p = corrwin
    stat.valu(p) = (stat.condgfp(1,p) - mean(stat.condgfp(2:end,p)))/...
        (std(stat.condgfp(2:end,p))/sqrt(size(stat.condgfp,1)-1));
    stat.pprob(p) = sum(stat.pdist >= stat.condgfp(1,p))/param.numrand;
    stat.nprob(p) = sum(stat.ndist <= stat.condgfp(1,p))/param.numrand;
end

stat.times = EEG.times;
stat.condlist = condlist;
stat.timeshift = timeshift;
stat.subjinfo = subjinfo;
stat.statmode = statmode;
stat.param = param;
stat.chanlocs = chanlocs;
stat.srate = EEG.srate;

if nargout == 0
    save2file = sprintf('%s/%s_%s_%s_%d-%d_tct.mat',filepath,statmode,num2str(subjinfo),...
        condlist{1},param.latency(1),param.latency(2));
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