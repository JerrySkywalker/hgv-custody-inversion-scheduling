function selected_ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, mode, cfg)
%SELECT_SATELLITE_SET_CUSTODY_DUALLOOP
% Enumerate feasible subsets with custody structure constraints.
% Prefer feasible sets; in warn/trigger, apply lexicographic ranking:
%   1) shortest longest_single_support_steps
%   2) smallest single_support_ratio
%   3) lowest total score

visible_ids = find(caseData.candidates.visible_mask(k, :) > 0);
max_sats = cfg.ch5.max_track_sats;

if isempty(visible_ids)
    selected_ids = [];
    return;
end

force_two = false;
switch mode
    case 'safe'
        force_two = cfg.ch5.ck_force_two_sat_in_safe;
    case 'warn'
        force_two = cfg.ch5.ck_force_two_sat_in_warn;
    otherwise
        force_two = cfg.ch5.ck_force_two_sat_in_trigger;
end

all_sets = {};

if force_two && numel(visible_ids) >= 2
    for i = 1:numel(visible_ids)-1
        for j = i+1:numel(visible_ids)
            all_sets{end+1,1} = [visible_ids(i), visible_ids(j)]; %#ok<AGROW>
        end
    end
else
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
end

if isempty(all_sets) && cfg.ch5.ck_allow_single_fallback
    all_sets = num2cell(visible_ids(:), 2);
end

ref_ids = select_reference_template_dualloop(caseData, k, cfg);

records = struct('ids', {}, 'score', {}, 'is_feasible', {}, ...
                 'longest_single', {}, 'single_ratio', {});

for i = 1:numel(all_sets)
    ids = all_sets{i};
    [s, detail] = build_window_objective_dualloop(mode, ids, prev_ids, ref_ids, caseData, k, cfg);

    rec.ids = ids;
    rec.score = s;
    rec.is_feasible = logical(detail.is_feasible);
    rec.longest_single = detail.longest_single_support_steps;
    rec.single_ratio = detail.single_support_ratio;
    records(end+1) = rec; %#ok<AGROW>
end

feasible_mask = [records.is_feasible];
if any(feasible_mask)
    cand = records(feasible_mask);
else
    cand = records;
end

use_lexi = false;
switch mode
    case 'warn'
        use_lexi = cfg.ch5.ck_use_lexicographic_in_warn;
    case 'trigger'
        use_lexi = cfg.ch5.ck_use_lexicographic_in_trigger;
end

if use_lexi
    best_idx = 1;
    for i = 2:numel(cand)
        if local_better(cand(i), cand(best_idx))
            best_idx = i;
        end
    end
    selected_ids = cand(best_idx).ids(:).';
else
    scores = [cand.score];
    [~, idx] = min(scores);
    selected_ids = cand(idx).ids(:).';
end
end

function tf = local_better(a, b)
if a.longest_single < b.longest_single
    tf = true;
    return
elseif a.longest_single > b.longest_single
    tf = false;
    return
end

if a.single_ratio < b.single_ratio
    tf = true;
    return
elseif a.single_ratio > b.single_ratio
    tf = false;
    return
end

tf = (a.score < b.score);
end
