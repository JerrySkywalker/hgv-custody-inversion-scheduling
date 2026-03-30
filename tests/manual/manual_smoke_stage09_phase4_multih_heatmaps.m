function out = manual_smoke_stage09_phase4_multih_heatmaps(base)
%MANUAL_SMOKE_STAGE09_PHASE4_MULTIH_HEATMAPS
% Plot-only smoke for Phase4-A multi-height heatmaps.

    if nargin < 1 || isempty(base)
        error('manual_smoke_stage09_phase4_multih_heatmaps:MissingBase', ...
            ['A precomputed base struct is required.' newline ...
             'Run: base = manual_smoke_stage09_phase1_metric_views_cached();']);
    end

    fprintf('\n');
    fprintf('================ Phase4-A Multi-H Heatmaps Smoke ================\n');
    fprintf('Using precomputed base only. No search will be rerun.\n');
    fprintf('Export multi-height heatmap pack.\n');
    fprintf('=================================================================\n\n');

    out = struct();
    out.base = base;
    out.packMultih = plot_stage09_multih_heatmaps(base, 'phase4_multih');

    fprintf('\n');
    fprintf('================ Phase4-A Multi-H Summary ================\n');
    fprintf('Figure index CSV : %s\n', out.packMultih.files.figure_index_csv);
    fprintf('==========================================================\n\n');
end
