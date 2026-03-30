function base = manual_smoke_stage09_phase5_build_fullheight_base()
%MANUAL_SMOKE_STAGE09_PHASE5_BUILD_FULLHEIGHT_BASE
% Build a full-height Stage09 base for Phase5 3D stacked plots.
%
% This smoke intentionally enables the full h-grid search first,
% then reuses the resulting base for later 3D stack plotting.

    startup('force', true);
    rehash;

    fprintf('\n');
    fprintf('================ Phase5 Full-Height Base Build ================\n');
    fprintf('This step runs Stage09 search on the full height grid.\n');
    fprintf('The resulting base is intended for Phase5 3D stacked plots.\n');
    fprintf('===============================================================\n\n');

    cfg = default_params();
    cfg = stage09_prepare_cfg(cfg);

    % -------- full-height search scope --------
    % Keep your standard i/P/T grids, but do NOT collapse h to a single smoke slice.
    % Adjust only if your project baseline differs.
    cfg.h_grid_km = [500 600 700 800 900 1000];

    % Optional plotting slice defaults for later use
    cfg.stage09.plot_h_slice_km = 1000;
    cfg.stage09.plot_P_slice = 12;

    % Reuse existing Phase1-B metric-view pipeline, but with full h-grid.
    base = manual_smoke_stage09_phase1_metric_views(cfg);

    fprintf('\n');
    fprintf('================ Phase5 Full-Height Base Summary ================\n');
    if isfield(base, 'cubes') && isfield(base.cubes, 'index_tables') ...
            && isfield(base.cubes.index_tables, 'h')
        disp(base.cubes.index_tables.h);
    end
    fprintf('=================================================================\n\n');
end
