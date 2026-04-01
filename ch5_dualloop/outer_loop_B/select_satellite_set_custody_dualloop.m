function selected_ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, mode, cfg)
%SELECT_SATELLITE_SET_CUSTODY_DUALLOOP
% Enumerate feasible subsets with custody structure constraints.
% Prefer feasible sets; if none feasible, choose least-bad fallback.

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

best_score_feas = inf;
best_ids_feas = [];
best_score_any = inf;
best_ids_any = all_sets{1};

for i = 1:numel(all_sets)
    ids = all_sets{i};
    [s, detail] = build_window_objective_dualloop(mode, ids, prev_ids, ref_ids, caseData, k, cfg);

    if s < best_score_any
        best_score_any = s;
        best_ids_any = ids;
    end

    if isfield(detail, 'is_feasible') && detail.is_feasible
        if s < best_score_feas
            best_score_feas = s;
            best_ids_feas = ids;
        end
    end
end

if ~isempty(best_ids_feas)
    selected_ids = best_ids_feas(:).';
else
    selected_ids = best_ids_any(:).';
end
end
