function out = manual_smoke_stage09_phase4_closure_heatmaps(base)
%MANUAL_SMOKE_STAGE09_PHASE4_CLOSURE_HEATMAPS
% Phase4-B smoke: export closure heatmap pack from cached/base data only.
%
% Usage:
%   base = manual_smoke_stage09_phase1_metric_views_cached();
%   out  = manual_smoke_stage09_phase4_closure_heatmaps(base);

    if nargin < 1 || isempty(base)
        startup('force', true);
        rehash;
        base = manual_smoke_stage09_phase1_metric_views_cached();
    end

    fprintf('\n');
    fprintf('================ Phase4-B Closure Heatmaps Smoke ================\n');
    fprintf('Using precomputed base only. No search will be rerun.\n');
    fprintf('Export four-layer closure heatmap pack.\n');
    fprintf('=================================================================\n\n');

    out = struct();
    out.base = base;
    out.packClosure = plot_stage09_closure_heatmaps(base, 'phase4_closure');

    fprintf('\n');
    fprintf('================ Phase4-B Closure Summary ================\n');
    fprintf('Figure index CSV : %s\n', out.packClosure.files.figure_index_csv);
    fprintf('==========================================================\n\n');
end
