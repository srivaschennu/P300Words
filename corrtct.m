function stat = corrtct(stat,varargin)

param = finputcheck(varargin, {
    'alpha' , 'real' , [], 0.05; ...
    'ttesttail' , 'integer' , [-1 0 1], 1; ...
    });

if param.ttesttail == 0
    param.alpha = param.alpha / 2;
end

stat = rmfield(stat,'gfpdiff');

pprob = ones(1,size(stat.condgfp,2));
nprob = ones(1,size(stat.condgfp,2));
pmask = zeros(size(pprob));
nmask = zeros(size(nprob));
phits = zeros(size(stat.condgfp,1),1);
nhits = zeros(size(stat.condgfp,1),1);
stat.pclust = struct([]);
stat.nclust = struct([]);

corrwin = find(stat.times >= stat.param.latency(1) & stat.times <= stat.param.latency(2));

%% identfy clusters
h_wait = waitbar(0,'Please wait...');
set(h_wait,'Name',[mfilename ' progress']);

for n = 1:size(stat.condgfp,1)
    if n > 1
        waitbar(n/size(stat.condgfp,1),h_wait,sprintf('Permutation %d...',n-1));
    end
    pprob(:) = 1;
    nprob(:) = 1;
    pmask(:) = 0;
    nmask(:) = 0;

    for p = corrwin
        pprob(p) = sum(stat.condgfp(:,p) >= stat.condgfp(n,p))/size(stat.condgfp,1);
        nprob(p) = sum(stat.condgfp(:,p) <= stat.condgfp(n,p))/size(stat.condgfp,1);
    end
    
    pmask(pprob < param.alpha) = 1;
    nmask(nprob < param.alpha) = 1;
    
    if n == 1
        stat.pprob = pprob;
        stat.nprob = nprob;
        stat.pmask = pmask;
        stat.nmask = nmask;
    end
    
    phits(n) = sum(pmask);
    nhits(n) = sum(nmask);
end
close(h_wait);

stat.pclust(1).prob = sum(phits(1) <= phits)/length(phits);
stat.pclust(1).tstat = (phits(1) - mean(phits)) / (std(phits)/sqrt(length(phits)));
stat.pclust(1).win = stat.times([find(stat.pmask,1,'first') find(stat.pmask,1,'last')]);
if stat.pclust.prob > param.alpha
    stat.pclust = struct([]);
end

stat.nclust(1).prob = sum(nhits(1) <= nhits)/length(nhits);
stat.nclust(1).tstat = (nhits(1) - mean(nhits)) / (std(nhits)/sqrt(length(nhits)));
stat.nclust(1).win = [find(stat.nmask,1,'first') find(stat.nmask,1,'last')];
if stat.nclust.prob > param.alpha
    stat.nclust = struct([]);
end

paramlist = fieldnames(param);
for p = 1:length(paramlist)
    stat.param.(paramlist{p}) = param.(paramlist{p});
end
