function ref_ids = select_reference_template_dualloop(caseData, k, cfg)
%SELECT_REFERENCE_TEMPLATE_DUALLOOP
% Reference template chosen by future dual-support preference.

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
    d = compute_support_window_proxy_dualloop(caseData, ids, k, cfg);

    long_single = d.longest_single_support_steps / max(1, cfg.ch5.window_steps);
    long_zero = d.longest_zero_support_steps / max(1, cfg.ch5.window_steps);

    cost = ...
        - cfg.ch5.ck_ref_dual_weight * d.dual_support_ratio ...
        + cfg.ch5.ck_ref_single_weight * d.single_support_ratio ...
        + cfg.ch5.ck_ref_zero_weight * d.zero_support_ratio ...
        + cfg.ch5.ck_ref_longest_single_weight * long_single ...
        + cfg.ch5.ck_ref_longest_zero_weight * long_zero;

    if cost < best_cost
        best_cost = cost;
        best_ids = ids;
    end
end

ref_ids = best_ids(:).';
end
