function selected_ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, mode, cfg)
%SELECT_SATELLITE_SET_CUSTODY_DUALLOOP
% Safe fallback to C; warn/trigger use feasible-set filtering then direct total-score selection.
% Phase 8:
%   - if prior is enabled, match a reference template from prior library
%   - otherwise fall back to dynamic local template selection

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

ref_ids = [];
if isfield(cfg.ch5, 'prior_enable') && cfg.ch5.prior_enable && ...
   isfield(cfg.ch5, 'prior_library') && ~isempty(cfg.ch5.prior_library)
    ref_ids = match_reference_prior(cfg.ch5.prior_library, caseData, k, mode, cfg);
end
if isempty(ref_ids)
    ref_ids = select_reference_template_dualloop(caseData, k, cfg);
end

records = struct('ids', {}, 'score', {}, 'is_feasible', {});

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

    records(end+1) = rec; %#ok<AGROW>
end

feasible_mask = [records.is_feasible];
if any(feasible_mask)
    cand = records(feasible_mask);
else
    cand = records;
end

scores = [cand.score];
[~, idx] = min(scores);
selected_ids = cand(idx).ids(:).';
end
