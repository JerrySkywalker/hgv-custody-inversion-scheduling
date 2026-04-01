function selected_ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, mode, cfg)
%SELECT_SATELLITE_SET_CUSTODY_DUALLOOP
% Enumerate visible subsets and pick best by worst-window-oriented CK score.

visible_ids = find(caseData.candidates.visible_mask(k, :) > 0);
max_sats = cfg.ch5.max_track_sats;

if isempty(visible_ids)
    selected_ids = [];
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

ref_ids = select_reference_template_dualloop(caseData, k, cfg);

best_score = inf;
best_ids = all_sets{1};

for i = 1:numel(all_sets)
    ids = all_sets{i};
    s = build_window_objective_dualloop(mode, ids, prev_ids, ref_ids, caseData, k, cfg);
    if s < best_score
        best_score = s;
        best_ids = ids;
    end
end

selected_ids = best_ids(:).';
end
