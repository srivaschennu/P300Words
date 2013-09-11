function p_overall = tctfdr(p,gfp)

nDataPoints = length(p);
nIter = size(gfp,1)-1;

% False discovery rate
FDR = 0.05; % This is the FDR that we choose to be acceptable
p_exp = (1:nDataPoints) / nIter;    % This is the distribution of p-values under
                                    % the null-hypothesis
p_corr = p_exp * FDR;               % This is the distribution of the accepted
                                    % false positives
p_sorted = sort(p);
FDR_threshold = p_sorted(max(find(p_sorted <=p_corr)));
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