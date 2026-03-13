function out = stage10A_truth_structure_diagnostics(cfg)
%STAGE10A_TRUTH_STRUCTURE_DIAGNOSTICS
% Stage10.A:
%   Diagnose truth-side window information structure before building any
%   bcirc baseline or FFT proxy.
%
% Outputs:
%   - summary_table : compact scalar structure statistics
%   - plane_table   : per-plane truth contributions
%   - lag_table     : anchor-relative and active-anchor-mean lag profiles
%   - optional figure
%
% This stage intentionally does NOT build W_{r,0} yet.

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage10A_prepare_cfg(cfg);
    cfg.project_stage = 'stage10A_truth_structure_diagnostics';

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);
    ensure_dir(cfg.paths.figs);

    run_tag = char(cfg.stage10A.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage10A_truth_structure_diagnostics_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage10.A truth structure diagnostics started.');

    % ------------------------------------------------------------
    % Build casebank
    % ------------------------------------------------------------
    trajs_in = local_build_casebank(cfg);
    nCase = numel(trajs_in);
    if nCase < 1
        error('Stage10.A casebank is empty.');
    end

    case_index = local_pick_index(cfg.stage10A.case_index, nCase, cfg.stage10A.clip_case_index, 'case_index');
    traj_case = trajs_in(case_index);

    log_msg(log_fid, 'INFO', 'Selected case %d / %d : %s', ...
        case_index, nCase, string(traj_case.case.case_id));

    % ------------------------------------------------------------
    % Select Walker design
    % ------------------------------------------------------------
    row = local_pick_theta_row(cfg);
    log_msg(log_fid, 'INFO', 'Selected theta: h=%.1f km, i=%.1f deg, P=%d, T=%d, F=%d', ...
        row.h_km, row.i_deg, row.P, row.T, row.F);

    % ------------------------------------------------------------
    % Build common time grid and Walker propagation
    % ------------------------------------------------------------
    t_end_all = arrayfun(@(s) s.traj.t_s(end), trajs_in);
    t_max = max(t_end_all);
    dt = cfg.stage02.Ts_s;
    t_s_common = (0:dt:t_max).';

    cfg_eval = cfg;
    cfg_eval.stage03.h_km = row.h_km;
    cfg_eval.stage03.i_deg = row.i_deg;
    cfg_eval.stage03.P = row.P;
    cfg_eval.stage03.T = row.T;
    cfg_eval.stage03.F = row.F;

    walker = build_single_layer_walker_stage03(cfg_eval);
    satbank = propagate_constellation_stage03(walker, t_s_common);

    % ------------------------------------------------------------
    % Visibility and window selection
    % ------------------------------------------------------------
    vis_case = compute_visibility_matrix_stage03(traj_case, satbank, cfg_eval);
    window_grid = build_window_grid_stage04(vis_case.t_s, cfg_eval);

    nW = window_grid.num_windows;
    if nW < 1
        error('No valid windows available for selected case.');
    end

    window_index = local_pick_index(cfg.stage10A.window_index, nW, cfg.stage10A.clip_window_index, 'window_index');
    idx_start = window_grid.start_idx(window_index);
    idx_end = window_grid.end_idx(window_index);

    log_msg(log_fid, 'INFO', 'Selected window %d / %d : [idx %d, %d], [t0=%.2f s, t1=%.2f s]', ...
        window_index, nW, idx_start, idx_end, ...
        window_grid.t0_s(window_index), window_grid.t1_s(window_index));

    % ------------------------------------------------------------
    % Truth full matrix + plane pack
    % ------------------------------------------------------------
    Wr_full = build_window_info_matrix_stage04(vis_case, idx_start, idx_end, satbank, cfg_eval);
    Wr_full = 0.5 * (Wr_full + Wr_full.');

    wm_full = compute_window_metrics_stage09(Wr_full, cfg_eval);

    plane_pack = wr_build_plane_blocks_stage10(vis_case, idx_start, idx_end, satbank, walker, cfg_eval);
    lag_pack = wr_build_plane_lag_tensor_stage10A(plane_pack, cfg_eval);

    [summary_table_core, plane_table, lag_table] = ...
        summarize_stage10A_structure_stats(plane_pack, lag_pack, Wr_full, cfg_eval);

    summary_table = [ ...
        table( ...
            string(traj_case.case.case_id), ...
            string(local_safe_get(traj_case.case, 'family', "")), ...
            row.h_km, row.i_deg, row.P, row.T, row.F, row.Ns, ...
            window_index, window_grid.t0_s(window_index), window_grid.t1_s(window_index), ...
            wm_full.lambda_min_eff, wm_full.DG, wm_full.DA, ...
            'VariableNames', { ...
                'case_id','family', ...
                'h_km','i_deg','P_theta','T_theta','F_theta','Ns_theta', ...
                'window_index','t0_s','t1_s', ...
                'lambda_full_eff','DG_full','DA_full'}) ...
        summary_table_core];

    out = struct();
    out.cfg = cfg_eval;
    out.theta_row = row;
    out.case_index = case_index;
    out.window_index = window_index;
    out.case = traj_case.case;
    out.window_info = struct( ...
        'idx_start', idx_start, ...
        'idx_end', idx_end, ...
        't0_s', window_grid.t0_s(window_index), ...
        't1_s', window_grid.t1_s(window_index));
    out.Wr_full = Wr_full;
    out.wm_full = wm_full;
    out.plane_pack = plane_pack;
    out.lag_pack = lag_pack;
    out.summary_table = summary_table;
    out.plane_table = plane_table;
    out.lag_table = lag_table;
    out.files = struct();
    out.files.log_file = log_file;

    % ------------------------------------------------------------
    % Save tables
    % ------------------------------------------------------------
    if cfg.stage10A.write_csv
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10A_truthdiag_summary_%s_%s.csv', run_tag, timestamp));
        plane_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10A_truthdiag_plane_table_%s_%s.csv', run_tag, timestamp));
        lag_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10A_truthdiag_lag_table_%s_%s.csv', run_tag, timestamp));

        writetable(summary_table, summary_csv);
        writetable(plane_table, plane_csv);
        writetable(lag_table, lag_csv);

        out.files.summary_csv = summary_csv;
        out.files.plane_csv = plane_csv;
        out.files.lag_csv = lag_csv;

        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Plane CSV saved to: %s', plane_csv);
        log_msg(log_fid, 'INFO', 'Lag CSV saved to: %s', lag_csv);
    end

    % ------------------------------------------------------------
    % Plot
    % ------------------------------------------------------------
    if cfg.stage10A.make_plot
        fig_png = fullfile(cfg.paths.figs, ...
            sprintf('stage10A_truthdiag_structure_%s_%s.png', run_tag, timestamp));
        fig = plot_stage10A_plane_structure(summary_table, plane_table, lag_table, fig_png, cfg_eval);
        out.files.fig_png = fig_png;
        out.fig = fig;
        log_msg(log_fid, 'INFO', 'Figure saved to: %s', fig_png);
    end

    % ------------------------------------------------------------
    % Cache
    % ------------------------------------------------------------
    if cfg.stage10A.save_mat_cache
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage10A_truthdiag_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
        log_msg(log_fid, 'INFO', 'Cache MAT saved to: %s', cache_file);
    end

    log_msg(log_fid, 'INFO', 'Stage10.A truth structure diagnostics finished.');

    fprintf('\n');
    fprintf('========== Stage10.A Truth Structure Diagnostics ==========\n');
    disp(summary_table);
    disp(plane_table);
    disp(lag_table);
    if isfield(out.files, 'summary_csv')
        fprintf('Summary CSV : %s\n', out.files.summary_csv);
    end
    if isfield(out.files, 'plane_csv')
        fprintf('Plane CSV   : %s\n', out.files.plane_csv);
    end
    if isfield(out.files, 'lag_csv')
        fprintf('Lag CSV     : %s\n', out.files.lag_csv);
    end
    if isfield(out.files, 'fig_png')
        fprintf('Figure      : %s\n', out.files.fig_png);
    end
    if isfield(out.files, 'cache_file')
        fprintf('Cache       : %s\n', out.files.cache_file);
    end
    fprintf('Log         : %s\n', out.files.log_file);
    fprintf('===========================================================\n');
end


function trajs_in = local_build_casebank(cfg)
    switch lower(string(cfg.stage10A.case_source))
        case "inherit_stage09_casebank"
            trajs_in = build_stage09_casebank(cfg);
        otherwise
            error('Stage10.A case_source not implemented yet: %s', string(cfg.stage10A.case_source));
    end
end


function row = local_pick_theta_row(cfg)
    switch lower(string(cfg.stage10A.theta_source))
        case "first_search_row"
            Tsearch = local_build_search_domain_table(cfg);
            if height(Tsearch) < 1
                error('Stage10.A search domain is empty.');
            end
            row = Tsearch(1,:);

        case "manual"
            mt = cfg.stage10A.manual_theta;
            row = struct2table(struct( ...
                'h_km', mt.h_km, ...
                'i_deg', mt.i_deg, ...
                'P', mt.P, ...
                'T', mt.T, ...
                'F', mt.F, ...
                'Ns', mt.P * mt.T));

        otherwise
            error('Stage10.A theta_source not implemented yet: %s', string(cfg.stage10A.theta_source));
    end
end


function idx = local_pick_index(idx_req, nMax, do_clip, name_str)
    idx = idx_req;
    if idx <= nMax
        return;
    end
    if do_clip
        idx = nMax;
    else
        error('%s=%d exceeds available count n=%d.', name_str, idx_req, nMax);
    end
end


function T = local_build_search_domain_table(cfg)
    sd = cfg.stage09.search_domain;

    rows = {};
    idx = 0;
    for ih = 1:numel(sd.h_grid_km)
        for ii = 1:numel(sd.i_grid_deg)
            for ip = 1:numel(sd.P_grid)
                for it = 1:numel(sd.T_grid)
                    idx = idx + 1;
                    rows{idx,1} = struct( ... %#ok<AGROW>
                        'h_km', sd.h_grid_km(ih), ...
                        'i_deg', sd.i_grid_deg(ii), ...
                        'P', sd.P_grid(ip), ...
                        'T', sd.T_grid(it), ...
                        'F', sd.F_fixed, ...
                        'Ns', sd.P_grid(ip) * sd.T_grid(it));
                end
            end
        end
    end

    T = struct2table(vertcat(rows{:}));
    T = sortrows(T, {'Ns','h_km','i_deg','P','T'}, {'ascend','ascend','ascend','ascend','ascend'});
end


function value = local_safe_get(s, field_name, default_value)
    if isfield(s, field_name)
        value = s.(field_name);
    else
        value = default_value;
    end
end