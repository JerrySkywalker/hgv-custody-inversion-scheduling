function selected_ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, mode, cfg)
%SELECT_SATELLITE_SET_CUSTODY_DUALLOOP
% Safe fallback to C; warn/trigger use support-first plus geometric tie-break.

% safe mode: directly reuse C
if strcmp(mode, 'safe') && cfg.ch5.ck_safe_fallback_to_C
    selected_ids = select_satellite_set_custody(caseData, k, prev_ids, cfg);
    return;
end

visible_ids = find(caseData.candidates.visible_mask(k, :) > 0);
max_sats = cfg.ch5.max_track_sats;

if isempty(visible_ids)
    selected_ids = [];
    return;
end

force_two = false;
switch mode
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
                 'longest_single', {}, 'single_ratio', {}, ...
                 'lambda_min_geom', {}, 'min_crossing_angle_deg', {});

for i = 1:numel(all_sets)
    ids = all_sets{i};
    [s, detail] = build_window_objective_dualloop(mode, ids, prev_ids, ref_ids, caseData, k, cfg);

    rec.ids = ids;
    rec.score = s;

    if isfield(detail, 'is_feasible')
        rec.is_feasible = logical(detail.is_feasible);
    else
        rec.is_feasible = true;
    end

    if isfield(detail, 'longest_single_support_steps')
        rec.longest_single = detail.longest_single_support_steps;
    else
        rec.longest_single = inf;
    end

    if isfield(detail, 'single_support_ratio')
        rec.single_ratio = detail.single_support_ratio;
    else
        rec.single_ratio = 1;
    end

    if isfield(detail, 'lambda_min_geom')
        rec.lambda_min_geom = detail.lambda_min_geom;
    else
        rec.lambda_min_geom = 0;
    end

    if isfield(detail, 'min_crossing_angle_deg')
        rec.min_crossing_angle_deg = detail.min_crossing_angle_deg;
    else
        rec.min_crossing_angle_deg = 0;
    end

    records(end+1) = rec; %#ok<AGROW>
end

feasible_mask = [records.is_feasible];
if any(feasible_mask)
    cand = records(feasible_mask);
else
    cand = records;
end

best_idx = 1;
for i = 2:numel(cand)
    if local_better_geom(cand(i), cand(best_idx))
        best_idx = i;
    end
end

selected_ids = cand(best_idx).ids(:).';
end

function tf = local_better_geom(a, b)
% 1) shorter longest single-support
if a.longest_single < b.longest_single
    tf = true; return
elseif a.longest_single > b.longest_single
    tf = false; return
end

% 2) smaller single-support ratio
if a.single_ratio < b.single_ratio
    tf = true; return
elseif a.single_ratio > b.single_ratio
    tf = false; return
end

% 3) larger geometry lambda-min
if a.lambda_min_geom > b.lambda_min_geom
    tf = true; return
elseif a.lambda_min_geom < b.lambda_min_geom
    tf = false; return
end

% 4) larger LOS crossing angle
if a.min_crossing_angle_deg > b.min_crossing_angle_deg
    tf = true; return
elseif a.min_crossing_angle_deg < b.min_crossing_angle_deg
    tf = false; return
end

% 5) lower total score
tf = (a.score < b.score);
end
