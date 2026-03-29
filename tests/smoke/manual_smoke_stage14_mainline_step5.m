function out = manual_smoke_stage14_mainline_step5(cfg, opts)
%MANUAL_SMOKE_STAGE14_MAINLINE_STEP5
% Minimal smoke test for Stage14.3 second step:
%   aggregate Stage14 Ns-envelope stats across multiple Ns values.
%
% Default filter:
%   h=1000, i=40, F=1
%
% Default Ns_list:
%   inferred from latest Stage14.1 raw grid under stage14 stage-scoped cache

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    % IMPORTANT:
    % switch to stage14-scoped output paths before probing cache
    cfg.project_stage = 'stage14_analyze_multi_ns_envelopes';
    cfg = configure_stage_output_paths(cfg);

    local = struct();
    local.h_km = 1000;
    local.i_deg = 40;
    local.F = cfg.stage05.F_fixed;
    local.Ns_list = [];
    local.save_table = true;
    local.quiet = false;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    if isempty(local.Ns_list)
        listing = dir(fullfile(cfg.paths.cache, 'stage14_scan_openD_raan_grid_*.mat'));
        assert(~isempty(listing), 'No Stage14.1 cache found in stage14 cache path: %s', cfg.paths.cache);

        [~, idx] = max([listing.datenum]);
        S = load(fullfile(listing(idx).folder, listing(idx).name));
        grid = S.out.grid;

        mask = (grid.h_km == local.h_km) & ...
               (grid.i_deg == local.i_deg) & ...
               (grid.F == local.F);
        local.Ns_list = unique(grid.Ns(mask)).';
    end

    out = stage14_analyze_multi_ns_envelopes(cfg, local);

    fprintf('\n=== Stage14.3 step2 smoke summary ===\n');
    disp(out.summary_table_all);
end
