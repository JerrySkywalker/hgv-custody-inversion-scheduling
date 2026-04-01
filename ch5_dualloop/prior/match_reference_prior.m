function ref_ids = match_reference_prior(prior_lib, caseData, k, mode, cfg)
%MATCH_REFERENCE_PRIOR
% Match current window to the closest reference template.
%
% Strategy:
%   - only consider templates with visible overlap
%   - prefer higher overlap and lower deviation cost
%   - return visible-compatible ref_ids

if nargin < 5 || isempty(cfg)
    cfg = default_ch5_params();
end

ref_ids = [];

if isempty(prior_lib)
    return;
end

visible_ids = find(caseData.candidates.visible_mask(k, :) > 0);
visible_ids = visible_ids(:).';

if isempty(visible_ids)
    return;
end

if ~isfield(cfg.ch5, 'prior_match_deviation_weight')
    cfg.ch5.prior_match_deviation_weight = 0.65;
end
if ~isfield(cfg.ch5, 'prior_match_overlap_weight')
    cfg.ch5.prior_match_overlap_weight = 0.35;
end

force_two = false;
switch char(mode)
    case 'warn'
        force_two = cfg.ch5.ck_force_two_sat_in_warn;
    case 'trigger'
        force_two = cfg.ch5.ck_force_two_sat_in_trigger;
    otherwise
        force_two = false;
end

best_cost = inf;
best_ids = [];

for i = 1:numel(prior_lib)
    tpl_ids = prior_lib(i).ref_ids(:).';
    ids_vis = intersect(tpl_ids, visible_ids, 'stable');

    if isempty(ids_vis)
        continue;
    end

    if force_two && numel(ids_vis) < 2
        continue;
    end

    overlap = numel(ids_vis) / max(1, numel(tpl_ids));
    dev_cost = compute_prior_deviation_cost(ids_vis, tpl_ids, cfg);

    cost = ...
        cfg.ch5.prior_match_deviation_weight * dev_cost + ...
        cfg.ch5.prior_match_overlap_weight * (1 - overlap);

    if cost < best_cost
        best_cost = cost;
        best_ids = ids_vis;
    end
end

ref_ids = best_ids(:).';
end
