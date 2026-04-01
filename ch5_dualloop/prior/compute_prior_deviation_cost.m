function cost = compute_prior_deviation_cost(selected_ids, ref_ids, cfg)
%COMPUTE_PRIOR_DEVIATION_COST
% Normalized symmetric-difference cost against reference template.

if nargin < 3 || isempty(cfg)
    cfg = default_ch5_params();
end

if isempty(ref_ids)
    cost = 0;
    return;
end

den = max(1, cfg.ch5.max_track_sats);
cost = numel(setxor(selected_ids(:).', ref_ids(:).')) / den;
end
