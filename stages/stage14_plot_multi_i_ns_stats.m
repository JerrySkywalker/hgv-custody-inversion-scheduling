function out = stage14_plot_multi_i_ns_stats(cfg, opts)
%STAGE14_PLOT_MULTI_I_NS_STATS
% Mainline A: compare multi-Ns aggregate statistics across multiple i values.

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(opts)
        opts = struct();
    end

    cfg.project_stage = 'stage14_plot_multi_i_ns_stats';
    cfg = configure_stage_output_paths(cfg);

    local = struct();
    local.h_km = 1000;
    local.i_list = [40 60];
    local.F = cfg.stage05.F_fixed;
    local.Ns_list = [];
    local.visible = "on";
    local.save_fig = true;
    local.quiet = false;

    fn = fieldnames(opts);
    for k = 1:numel(fn)
        local.(fn{k}) = opts.(fn{k});
    end

    i_list = unique(local.i_list(:).');
    all_rows = table();

    % Load latest Stage14.1 raw grid once, for automatic Ns_list inference
    listing = dir(fullfile(cfg.paths.cache, 'stage14_scan_openD_raan_grid_*.mat'));
    assert(~isempty(listing), 'No Stage14.1 cache found in stage14 cache path: %s', cfg.paths.cache);

    [~, idx_latest] = max([listing.datenum]);
    S = load(fullfile(listing(idx_latest).folder, listing(idx_latest).name));
    assert(isfield(S, 'out') && isfield(S.out, 'grid'), 'Invalid Stage14.1 cache: missing out.grid.');
    grid = S.out.grid;

    for ii = 1:numel(i_list)
        i_deg = i_list(ii);

        ns_list_i = local.Ns_list;
        if isempty(ns_list_i)
            mask = true(height(grid),1);

            if ~isnan(local.h_km)
                mask = mask & (grid.h_km == local.h_km);
            end
            if ~isnan(i_deg)
                mask = mask & (grid.i_deg == i_deg);
            end
            if ~isnan(local.F)
                mask = mask & (grid.F == local.F);
            end

            ns_list_i = unique(grid.Ns(mask)).';
            assert(~isempty(ns_list_i), ...
                'Failed to infer Ns_list from latest Stage14.1 grid for (h=%g, i=%g, F=%g).', ...
                local.h_km, i_deg, local.F);
        end

        res_i = stage14_analyze_multi_ns_envelopes(cfg, struct( ...
            'h_km', local.h_km, ...
            'i_deg', i_deg, ...
            'F', local.F, ...
            'Ns_list', ns_list_i, ...
            'save_table', false, ...
            'quiet', true));

        Ti = res_i.summary_table_all;
        all_rows = [all_rows; Ti]; %#ok<AGROW>
    end

    tag = sprintf('h%d_F%d', round(local.h_km), local.F);

    files = plot_stage14_multi_i_ns_stats(all_rows, cfg, ...
        'visible', local.visible, ...
        'save_fig', local.save_fig, ...
        'tag', tag);

    out = struct();
    out.summary_table_all = sortrows(all_rows, {'i_deg','Ns'});
    out.files = files;

    if ~local.quiet
        fprintf('\n=== Stage14 mainline A: multi-i comparison plots ===\n');
        fprintf('filter          : h=%g, F=%d\n', local.h_km, local.F);
        fprintf('i list          : ');
        disp(i_list);
        fprintf('DG mean plot    : %s\n', files.DG_mean_png);
        fprintf('DG min plot     : %s\n', files.DG_min_png);
        fprintf('DG span plot    : %s\n', files.DG_span_png);
        fprintf('pass mean plot  : %s\n', files.pass_mean_png);
        fprintf('pass min plot   : %s\n', files.pass_min_png);
        fprintf('pass span plot  : %s\n\n', files.pass_span_png);
    end
end
