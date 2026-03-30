function out = manual_smoke_stage09_phase4_closure_heatmaps_hi(base)
%MANUAL_SMOKE_STAGE09_PHASE4_CLOSURE_HEATMAPS_HI
% Phase4-C smoke: export h-i closure heatmap pack from cached/base data only.
%
% Usage:
%   base = manual_smoke_stage09_phase1_metric_views_cached();
%   out  = manual_smoke_stage09_phase4_closure_heatmaps_hi(base);

    if nargin < 1 || isempty(base)
        startup('force', true);
        rehash;
        base = manual_smoke_stage09_phase1_metric_views_cached();
    end

    fprintf('\n');
    fprintf('================ Phase4-C Closure HI Heatmaps Smoke ================\n');
    fprintf('Using precomputed base only. No search will be rerun.\n');
    fprintf('Export four-layer closure heatmap pack on h-i plane.\n');
    fprintf('====================================================================\n\n');

    out = struct();
    out.base = base;
    out.packClosureHI = plot_stage09_closure_heatmaps_hi(base, 'phase4_closure_hi');

    fprintf('\n');
    fprintf('================ Phase4-C Closure HI Summary ================\n');
    fprintf('Figure index CSV : %s\n', out.packClosureHI.files.figure_index_csv);
    fprintf('=============================================================\n\n');
end
