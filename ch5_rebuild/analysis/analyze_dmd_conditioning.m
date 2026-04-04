function stats = analyze_dmd_conditioning(X_prev)
%ANALYZE_DMD_CONDITIONING Analyze conditioning of local regression data.
%
% Input:
%   X_prev : [nx x N]
%
% Output:
%   stats.cond_raw
%   stats.rank_raw
%   stats.singular_values

assert(isnumeric(X_prev) && ismatrix(X_prev), 'X_prev must be a numeric matrix.');

Phi = [X_prev; ones(1, size(X_prev,2))];
s = svd(Phi);

stats = struct();
stats.cond_raw = cond(Phi);
stats.rank_raw = rank(Phi);
stats.singular_values = s;
end
