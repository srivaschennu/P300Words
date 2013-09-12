function p_overall = tctfdr(gfp)

nIter = size(gfp,1);
nDataPoints = size(gfp,2);

% Count test
threshold = 0.05;
for i = 1:nIter
    for t = 1:nDataPoints
        p_fake(t,i) = (sum(gfp(:,t) >= gfp(i,t)))/nIter;
    end
% p-values under the
% null-hypothesis
    Hits(i) = sum(p_fake(:,i) < threshold);     % Count of false positives
end
p_overall = sum(Hits(1) <= Hits) / nIter;