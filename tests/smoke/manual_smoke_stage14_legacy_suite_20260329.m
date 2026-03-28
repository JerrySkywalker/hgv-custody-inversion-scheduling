function out = manual_smoke_stage14_legacy_suite_20260329(action, cfg)
%MANUAL_SMOKE_STAGE14_LEGACY_SUITE_20260329
% Stage14 legacy smoke suite entry.
% This file lists the frozen pre-pivot Stage14 exploration scripts renamed in-place on 20260329.

    if nargin < 1 || isempty(action)
        action = "list";
    end
    if nargin < 2
        cfg = [];
    end

    items = { ...
        "manual_smoke_stage14_consistency_legacy_prepivot_20260329", ...
        "manual_smoke_stage14_raan_sweep_legacy_prepivot_20260329", ...
        "manual_smoke_stage14_select_candidates_legacy_prepivot_20260329", ...
        "manual_smoke_stage14_batch_raan_sweep_legacy_prepivot_20260329", ...
        "manual_smoke_stage14_plot_profiles_legacy_prepivot_20260329", ...
        "manual_smoke_stage14_weak_periodicity_A1_legacy_prepivot_20260329", ...
        "manual_smoke_stage14_state_equivalence_A1_legacy_prepivot_20260329", ...
        "manual_smoke_stage14_los_matrix_compare_A1_legacy_prepivot_20260329", ...
        "manual_smoke_stage14_F_sweep_A1_legacy_prepivot_20260329", ...
        "manual_smoke_stage14_F_RAAN_grid_A1_legacy_prepivot_20260329", ...
        "manual_smoke_stage14_F_RAAN_postprocess_A1_legacy_prepivot_20260329", ...
        "manual_smoke_stage14_A1_formal_package_legacy_prepivot_20260329" ...
    };

    out = struct();
    out.items = items;

    switch string(action)
        case "list"
            fprintf('\n=== Stage14 Legacy Smoke Suite (20260329) ===\n');
            for k = 1:numel(items)
                fprintf('%2d) %s\n', k, items{k});
            end
            fprintf('\nUsage examples:\n');
            fprintf('  manual_smoke_stage14_legacy_suite_20260329("list")\n');
            fprintf('  manual_smoke_stage14_legacy_suite_20260329("run", default_params())\n\n');
        case "run"
            if isempty(cfg)
                cfg = default_params();
            end
            fprintf('\n=== Stage14 Legacy Smoke Suite (run mode) ===\n');
            fprintf('This suite does not auto-run all items, because several archived scripts depend on intermediate variables.\n');
            fprintf('Please call the listed functions explicitly as needed.\n\n');
            for k = 1:numel(items)
                fprintf('%2d) %s\n', k, items{k});
            end
        otherwise
            error('Unknown action: %s', string(action));
    end
end
