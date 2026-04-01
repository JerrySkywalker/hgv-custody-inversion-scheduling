function diag = diagnose_outerB_selection_dualloop(caseData, outerA, cfg)
%DIAGNOSE_OUTERB_SELECTION_DUALLOOP
% Diagnose feasible-set counts and gate reasons over time.

t = caseData.time.t(:);
N = numel(t);

num_all_sets = zeros(N,1);
num_feasible_sets = zeros(N,1);
selected_was_feasible = false(N,1);
selected_set_size = zeros(N,1);
selected_score = nan(N,1);
selected_mode = strings(N,1);
selected_gate_reason = strings(N,1);

gate_warn_zero_ratio = 0;
gate_warn_longest_zero = 0;
gate_warn_longest_single = 0;
gate_trigger_zero_ratio = 0;
gate_trigger_longest_zero = 0;
gate_trigger_longest_single = 0;

prev_ids = [];

for k = 1:N
    mode = dispatch_quadrant_policy(outerA.risk_state(k));
    selected_mode(k) = string(mode);

    visible_ids = find(caseData.candidates.visible_mask(k, :) > 0);
    if isempty(visible_ids)
        selected_set_size(k) = 0;
        prev_ids = [];
        continue
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

    if isempty(all_sets) && cfg.ch5.ck_allow_single_fallback
        all_sets = num2cell(visible_ids(:), 2);
    end

    num_all_sets(k) = numel(all_sets);

    ref_ids = select_reference_template_dualloop(caseData, k, cfg);

    best_score_feas = inf;
    best_ids_feas = [];
    best_score_any = inf;
    best_ids_any = all_sets{1};
    best_reason_any = "none";
    best_feas_flag_any = false;

    feasible_count_k = 0;

    for i = 1:numel(all_sets)
        ids = all_sets{i};
        [s, detail] = build_window_objective_dualloop(mode, ids, prev_ids, ref_ids, caseData, k, cfg);

        if s < best_score_any
            best_score_any = s;
            best_ids_any = ids;
            best_reason_any = string(detail.gate_reason);
            best_feas_flag_any = logical(detail.is_feasible);
        end

        if detail.is_feasible
            feasible_count_k = feasible_count_k + 1;
            if s < best_score_feas
                best_score_feas = s;
                best_ids_feas = ids;
            end
        else
            switch char(detail.gate_reason)
                case 'warn-zero-ratio'
                    gate_warn_zero_ratio = gate_warn_zero_ratio + 1;
                case 'warn-longest-zero'
                    gate_warn_longest_zero = gate_warn_longest_zero + 1;
                case 'warn-longest-single'
                    gate_warn_longest_single = gate_warn_longest_single + 1;
                case 'trigger-zero-ratio'
                    gate_trigger_zero_ratio = gate_trigger_zero_ratio + 1;
                case 'trigger-longest-zero'
                    gate_trigger_longest_zero = gate_trigger_longest_zero + 1;
                case 'trigger-longest-single'
                    gate_trigger_longest_single = gate_trigger_longest_single + 1;
            end
        end
    end

    num_feasible_sets(k) = feasible_count_k;

    if ~isempty(best_ids_feas)
        chosen_ids = best_ids_feas;
        selected_was_feasible(k) = true;
        selected_score(k) = best_score_feas;
        selected_gate_reason(k) = "feasible";
    else
        chosen_ids = best_ids_any;
        selected_was_feasible(k) = best_feas_flag_any;
        selected_score(k) = best_score_any;
        selected_gate_reason(k) = best_reason_any;
    end

    selected_set_size(k) = numel(chosen_ids);
    prev_ids = chosen_ids;
end

diag = struct();
diag.time = t;
diag.num_all_sets = num_all_sets;
diag.num_feasible_sets = num_feasible_sets;
diag.selected_was_feasible = selected_was_feasible;
diag.selected_set_size = selected_set_size;
diag.selected_score = selected_score;
diag.selected_mode = selected_mode;
diag.selected_gate_reason = selected_gate_reason;

diag.summary = struct();
diag.summary.mean_all_sets = mean(num_all_sets);
diag.summary.mean_feasible_sets = mean(num_feasible_sets);
diag.summary.steps_with_no_feasible = sum(num_feasible_sets == 0);
diag.summary.ratio_no_feasible = mean(num_feasible_sets == 0);
diag.summary.selected_feasible_ratio = mean(selected_was_feasible);
diag.summary.selected_two_sat_ratio = mean(selected_set_size >= 2);

diag.gate_counts = struct();
diag.gate_counts.warn_zero_ratio = gate_warn_zero_ratio;
diag.gate_counts.warn_longest_zero = gate_warn_longest_zero;
diag.gate_counts.warn_longest_single = gate_warn_longest_single;
diag.gate_counts.trigger_zero_ratio = gate_trigger_zero_ratio;
diag.gate_counts.trigger_longest_zero = gate_trigger_longest_zero;
diag.gate_counts.trigger_longest_single = gate_trigger_longest_single;
end
