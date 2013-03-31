function corrp(stat)

param = finputcheck(varargin, {
    'corrp', 'string', {'none','fdr','cluster'}, 'cluster'; ...
    'latency', 'real', [], []; ...
    'clustsize', 'integer', [], 10; ...
    });

if isempty(param.latency)
    param.latency = [0 EEG.times(end)-timeshift];
end

times = stat.times - stat.timeshift;

corrwin = find(times >= param.latency(1) & times <= param.latency(2));

for p = 1:size(gfpdiff,2)
    stat.valu(p) = (gfpdiff(1,p) - mean(gfpdiff(2:end,p)))/(std(gfpdiff(2:end,p))/sqrt(size(gfpdiff,1)-1));
    stat.pprob(p) = sum(max(gfpdiff(2:end,corrwin),[],2) >= gfpdiff(1,p))/param.numrand;
    stat.nprob(p) = sum(min(gfpdiff(2:end,corrwin),[],2) <= gfpdiff(1,p))/param.numrand;
end

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

%% identfy clusters

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
    end
    
    if stat.nprob(p) < param.alpha && stat.nprob(p-1) >= param.alpha
        nstart = p;
    elseif (stat.nprob(p) >= param.alpha || p == EEG.pnts) && stat.nprob(p-1) < param.alpha
        nend = p;
        
        nclustidx = nclustidx+1;
        stat.nclust(nclustidx).tstat = mean(stat.valu(nstart:nend-1));
        stat.nclust(nclustidx).prob = mean(stat.pprob(nstart:nend-1));
        stat.nclust(nclustidx).win = [EEG.times(nstart) EEG.times(nend-1)]-timeshift;
    end
end