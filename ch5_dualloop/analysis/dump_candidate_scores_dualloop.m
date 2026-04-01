function rows = dump_candidate_scores_dualloop(caseData, k, prev_ids, mode, cfg)
%DUMP_CANDIDATE_SCORES_DUALLOOP
% Enumerate candidate sets and dump support/score details at one step.

visible_ids = find(caseData.candidates.visible_mask(k, :) > 0);

if isempty(visible_ids)
    rows = struct('ids', {}, 'score', {}, 'is_feasible', {}, ...
                  'longest_single', {}, 'single_ratio', {}, 'zero_ratio', {});
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
    if cfg.ch5.max_track_sats >= 2 && numel(visible_ids) >= 2
        for i = 1:numel(visible_ids)-1
            for j = i+1:numel(visible_ids)
                all_sets{end+1,1} = [visible_ids(i), visible_ids(j)]; %#ok<AGROW>
            end
        end
    end
end

ref_ids = select_reference_template_dualloop(caseData, k, cfg);

rows = struct('ids', {}, 'score', {}, 'is_feasible', {}, ...
              'longest_single', {}, 'single_ratio', {}, 'zero_ratio', {});

for i = 1:numel(all_sets)
    ids = all_sets{i};
    [s, detail] = build_window_objective_dualloop(mode, ids, prev_ids, ref_ids, caseData, k, cfg);

    row.ids = ids;
    row.score = s;
    row.is_feasible = logical(detail.is_feasible);
    row.longest_single = detail.longest_single_support_steps;
    row.single_ratio = detail.single_support_ratio;
    row.zero_ratio = detail.zero_support_ratio;

    rows(end+1) = row; %#ok<AGROW>
end
end
