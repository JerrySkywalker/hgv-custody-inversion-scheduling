function base = manual_smoke_stage09_phase5_build_fullheight_base()
%MANUAL_SMOKE_STAGE09_PHASE5_BUILD_FULLHEIGHT_BASE
% Build a true multi-height Stage09 base for Phase5 3D stacked-over-h plots.
%
% Design rule:
%   - keep Stage05-aligned i/P/T grids
%   - keep nominal_only casebank
%   - only expand h-grid to multiple altitude layers
%   - use custom scheme so stage09_prepare_cfg will not overwrite h-grid

    startup('force', true);
    rehash;

    fprintf('\n');
    fprintf('================ Phase5 Full-Height Base Build ================\n');
    fprintf('This step runs Stage09 search on the expanded h-grid.\n');
    fprintf('The resulting base is intended for Phase5 metric-wise 3D stacked-over-h plots.\n');
    fprintf('================================================================\n\n');

    cfg = default_params();

    if ~isfield(cfg, 'stage09') || ~isstruct(cfg.stage09)
        cfg.stage09 = struct();
    end

    % ------------------------------------------------------------
    % Use custom scheme, otherwise stage05_aligned will collapse h back to
    % cfg.stage05.h_fixed_km during stage09_prepare_cfg().
    % ------------------------------------------------------------
    cfg.stage09.scheme_type = 'custom';
    cfg.stage09.run_tag = 'inverse_phase5_fullh';

    % keep current Phase1-B semantics
    cfg.stage09.casebank_mode = 'nominal_only';
    cfg.stage09.gamma_source = 'inherit_stage04';

    cfg.stage09.require_DG_min = 1;
    cfg.stage09.require_DA_min = 1;
    cfg.stage09.require_DT_min = 1;
    cfg.stage09.require_pass_ratio = 1;

    cfg.stage09.use_parallel = true;
    cfg.stage09.scan_log_every = 10;

    % ------------------------------------------------------------
    % Explicit custom search domain
    % Keep Stage05-aligned i/P/T/F, but expand h to full range
    % ------------------------------------------------------------
    if ~isfield(cfg.stage09, 'search_domain') || ~isstruct(cfg.stage09.search_domain)
        cfg.stage09.search_domain = struct();
    end

    cfg.stage09.search_domain.h_grid_km  = [500 600 700 800 900 1000];

    if isfield(cfg, 'stage05') && isstruct(cfg.stage05)
        if isfield(cfg.stage05, 'i_grid_deg')
            cfg.stage09.search_domain.i_grid_deg = cfg.stage05.i_grid_deg(:).';
        else
            cfg.stage09.search_domain.i_grid_deg = [30 40 50 60 70 80 90];
        end

        if isfield(cfg.stage05, 'P_grid')
            cfg.stage09.search_domain.P_grid = cfg.stage05.P_grid(:).';
        else
            cfg.stage09.search_domain.P_grid = [4 6 8 10 12];
        end

        if isfield(cfg.stage05, 'T_grid')
            cfg.stage09.search_domain.T_grid = cfg.stage05.T_grid(:).';
        else
            cfg.stage09.search_domain.T_grid = [4 6 8 10 12 16];
        end

        if isfield(cfg.stage05, 'F_fixed')
            cfg.stage09.search_domain.F_fixed = cfg.stage05.F_fixed;
        else
            cfg.stage09.search_domain.F_fixed = 1;
        end
    else
        cfg.stage09.search_domain.i_grid_deg = [30 40 50 60 70 80 90];
        cfg.stage09.search_domain.P_grid = [4 6 8 10 12];
        cfg.stage09.search_domain.T_grid = [4 6 8 10 12 16];
        cfg.stage09.search_domain.F_fixed = 1;
    end

    % plotting defaults for downstream plotters
    cfg.stage09.plot_h_slice_km = 1000;
    cfg.stage09.plot_P_slice = 12;

    fprintf('---------------- Phase5 Full-Height Input Config ----------------\n');
    fprintf('scheme_type      : %s\n', string(cfg.stage09.scheme_type));
    fprintf('run_tag          : %s\n', string(cfg.stage09.run_tag));
    fprintf('casebank_mode    : %s\n', string(cfg.stage09.casebank_mode));
    fprintf('gamma_source     : %s\n', string(cfg.stage09.gamma_source));
    fprintf('require_DG_min   : %g\n', cfg.stage09.require_DG_min);
    fprintf('require_DA_min   : %g\n', cfg.stage09.require_DA_min);
    fprintf('require_DT_min   : %g\n', cfg.stage09.require_DT_min);
    fprintf('require_pass_ratio : %g\n', cfg.stage09.require_pass_ratio);
    fprintf('h_grid_km        : [%s]\n', num2str(cfg.stage09.search_domain.h_grid_km));
    fprintf('i_grid_deg       : [%s]\n', num2str(cfg.stage09.search_domain.i_grid_deg));
    fprintf('P_grid           : [%s]\n', num2str(cfg.stage09.search_domain.P_grid));
    fprintf('T_grid           : [%s]\n', num2str(cfg.stage09.search_domain.T_grid));
    fprintf('F_fixed          : %g\n', cfg.stage09.search_domain.F_fixed);
    fprintf('-----------------------------------------------------------------\n\n');

    % Important:
    % do NOT call stage09_prepare_cfg(cfg) here.
    % manual_smoke_stage09_phase1_metric_views(cfg) will do that once,
    % and it must see the custom search_domain above.
    base = manual_smoke_stage09_phase1_metric_views(cfg);

    fprintf('\n');
    fprintf('================ Phase5 Full-Height Base Summary ================\n');
    if isfield(base, 'cubes') && isfield(base.cubes, 'index_tables')
        if isfield(base.cubes.index_tables, 'h')
            disp(base.cubes.index_tables.h);
        end
        if isfield(base.cubes.index_tables, 'i')
            disp(base.cubes.index_tables.i);
        end
        if isfield(base.cubes.index_tables, 'P')
            disp(base.cubes.index_tables.P);
        end
    end
    if isfield(base, 'cubes')
        if isfield(base.cubes, 'metric_over_h_i_P')
            fprintf('metric cube size  : [%s]\n', num2str(size(base.cubes.metric_over_h_i_P)));
        end
        if isfield(base.cubes, 'closure_over_h_i_P')
            fprintf('closure cube size : [%s]\n', num2str(size(base.cubes.closure_over_h_i_P)));
        end
    end
    fprintf('=================================================================\n\n');
end
