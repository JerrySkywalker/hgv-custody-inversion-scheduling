function ref_ids = select_reference_template_dualloop(caseData, k, cfg)
%SELECT_REFERENCE_TEMPLATE_DUALLOOP
% Lightweight static-like reference template for current window.
%
% Choose the set that best protects future phi floor without considering
% switching penalty.

visible_ids = find(caseData.candidates.visible_mask(k, :) > 0);
max_sats = cfg.ch5.max_track_sats;

if isempty(visible_ids)
    ref_ids = [];
    return;
end

all_sets = {};

for i = 1:numel(visible_ids)
    all_sets{end+1,1} = visible_ids(i); %#ok<AGROW>
end

if max_sats >= 2 && numel(visible_ids) >= 2
    for i = 1:numel(visible_ids)-1
        for j = i+1:numel(visible_ids)
            all_sets{end+1,1} = [visible_ids(i), visible_ids(j)]; %#ok<AGROW>
        end
    end
end

best_cost = inf;
best_ids = all_sets{1};

for i = 1:numel(all_sets)
    ids = all_sets{i};
    d = compute_phi_window_proxy_dualloop(caseData, ids, k, cfg);

    cost = ...
        - cfg.ch5.ck_ref_phi_min_weight  * d.phi_min ...
        - cfg.ch5.ck_ref_phi_avg_weight  * d.phi_avg ...
        + cfg.ch5.ck_ref_outage_weight   * d.outage_ratio ...
        + cfg.ch5.ck_ref_longest_weight  * (d.longest_outage_steps / max(1, cfg.ch5.window_steps));

    if cost < best_cost
        best_cost = cost;
        best_ids = ids;
    end
end

ref_ids = best_ids(:).';
end
