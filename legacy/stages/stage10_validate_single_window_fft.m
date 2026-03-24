function out = stage10_validate_single_window_fft(cfg)
%STAGE10_VALIDATE_SINGLE_WINDOW_FFT
% Stage10.1 validation script:
%   pick one case, one Walker design, one window;
%   build aggregate Wr and plane-block representation;
%   compare full plane-block matrix vs cyclic FFT proxy.
%
% IMPORTANT:
%   At Stage10.1, the goal is to verify the single-window structured
%   pipeline is wired correctly:
%       case -> walker -> vis -> one window -> plane blocks -> fft/full
%
%   This is intentionally a minimal debug / validation script.

    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage10_prepare_cfg(cfg);
    cfg.project_stage = 'stage10_validate_single_window_fft';
    cfg = configure_stage_output_paths(cfg);

    seed_rng(cfg.random.seed);
    ensure_dir(cfg.paths.logs);
    ensure_dir(cfg.paths.cache);
    ensure_dir(cfg.paths.tables);

    run_tag = char(cfg.stage10.run_tag);
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');

    log_file = fullfile(cfg.paths.logs, ...
        sprintf('stage10_validate_single_window_fft_%s_%s.log', run_tag, timestamp));
    log_fid = fopen(log_file, 'w');
    if log_fid < 0
        error('Failed to open log file: %s', log_file);
    end
    cleanupObj = onCleanup(@() fclose(log_fid)); %#ok<NASGU>

    log_msg(log_fid, 'INFO', 'Stage10.1 validation started.');

    % ------------------------------------------------------------
    % Build casebank
    % ------------------------------------------------------------
    trajs_in = local_build_casebank(cfg);
    nCase = numel(trajs_in);
    if nCase < 1
        error('Stage10.1 casebank is empty.');
    end

    case_index = local_pick_index(cfg.stage10.case_index, nCase, cfg.stage10.clip_case_index, 'case_index');
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

    window_index = local_pick_index(cfg.stage10.window_index, nW, cfg.stage10.clip_window_index, 'window_index');
    idx_start = window_grid.start_idx(window_index);
    idx_end = window_grid.end_idx(window_index);

    log_msg(log_fid, 'INFO', 'Selected window %d / %d : [idx %d, %d], [t0=%.2f s, t1=%.2f s]', ...
        window_index, nW, idx_start, idx_end, ...
        window_grid.t0_s(window_index), window_grid.t1_s(window_index));

    % ------------------------------------------------------------
    % Aggregate Wr from existing Stage04 truth kernel
    % ------------------------------------------------------------
    Wr_full = build_window_info_matrix_stage04(vis_case, idx_start, idx_end, satbank, cfg_eval);
    Wr_full = 0.5 * (Wr_full + Wr_full.');

    wm_full = compute_window_metrics_stage09(Wr_full, cfg_eval);

    % ------------------------------------------------------------
    % Build plane blocks and compare FFT proxy
    % ------------------------------------------------------------
    plane_pack = wr_build_plane_blocks_stage10(vis_case, idx_start, idx_end, satbank, walker, cfg_eval);
    cmp = compare_fft_vs_full_stage10(Wr_full, plane_pack, cfg_eval);

    % ------------------------------------------------------------
    % Summary tables
    % ------------------------------------------------------------
    summary_table = table( ...
        string(traj_case.case.case_id), ...
        string(local_safe_get(traj_case.case, 'family', "")), ...
        row.h_km, row.i_deg, row.P, row.T, row.F, row.Ns, ...
        window_index, window_grid.t0_s(window_index), window_grid.t1_s(window_index), ...
        wm_full.lambda_min_eff, wm_full.DG, wm_full.DA, ...
        cmp.lambda_blk_full_eff, cmp.lambda_blk_fft_eff, ...
        cmp.abs_err_lambda, cmp.rel_err_lambda, ...
        cmp.eps_sb_fro, cmp.eps_sb_2, ...
        cmp.bound_lb, cmp.bound_ub, cmp.bound_hit_flag, ...
        cmp.plane_count_nonzero, cmp.measurement_count_total, ...
        'VariableNames', { ...
            'case_id','family', ...
            'h_km','i_deg','P','T','F','Ns', ...
            'window_index','t0_s','t1_s', ...
            'lambda_full_eff','DG_full','DA_full', ...
            'lambda_blk_full_eff','lambda_blk_fft_eff', ...
            'abs_err_lambda','rel_err_lambda', ...
            'eps_sb_fro','eps_sb_2', ...
            'bound_lb','bound_ub','bound_hit_flag', ...
            'plane_count_nonzero','measurement_count_total'});

    plane_table = local_build_plane_table(plane_pack);

    % ------------------------------------------------------------
    % Save outputs
    % ------------------------------------------------------------
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
    out.compare = cmp;
    out.summary_table = summary_table;
    out.plane_table = plane_table;
    out.files = struct();
    out.files.log_file = log_file;

    if cfg.stage10.write_csv
        summary_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10_single_window_summary_%s_%s.csv', run_tag, timestamp));
        plane_csv = fullfile(cfg.paths.tables, ...
            sprintf('stage10_single_window_plane_table_%s_%s.csv', run_tag, timestamp));
        writetable(summary_table, summary_csv);
        writetable(plane_table, plane_csv);

        out.files.summary_csv = summary_csv;
        out.files.plane_csv = plane_csv;

        log_msg(log_fid, 'INFO', 'Summary CSV saved to: %s', summary_csv);
        log_msg(log_fid, 'INFO', 'Plane table CSV saved to: %s', plane_csv);
    end

    if cfg.stage10.save_mat_cache
        cache_file = fullfile(cfg.paths.cache, ...
            sprintf('stage10_single_window_%s_%s.mat', run_tag, timestamp));
        save(cache_file, 'out', '-v7.3');
        out.files.cache_file = cache_file;
        log_msg(log_fid, 'INFO', 'Cache MAT saved to: %s', cache_file);
    end

    log_msg(log_fid, 'INFO', 'Stage10.1 validation finished.');

    fprintf('\n');
    fprintf('========== Stage10.1 Single-Window FFT Validation ==========\n');
    disp(summary_table);
    disp(plane_table);
    if isfield(out.files, 'summary_csv')
        fprintf('Summary CSV : %s\n', out.files.summary_csv);
    end
    if isfield(out.files, 'plane_csv')
        fprintf('Plane CSV   : %s\n', out.files.plane_csv);
    end
    if isfield(out.files, 'cache_file')
        fprintf('Cache       : %s\n', out.files.cache_file);
    end
    fprintf('Log         : %s\n', out.files.log_file);
    fprintf('============================================================\n');
end


function trajs_in = local_build_casebank(cfg)

    switch lower(string(cfg.stage10.case_source))
        case "inherit_stage09_casebank"
            trajs_in = build_stage09_casebank(cfg);
        otherwise
            error('Stage10 case_source not implemented yet: %s', string(cfg.stage10.case_source));
    end
end


function row = local_pick_theta_row(cfg)

    switch lower(string(cfg.stage10.theta_source))
        case "first_search_row"
            Tsearch = local_build_search_domain_table(cfg);
            if height(Tsearch) < 1
                error('Stage10 search domain is empty.');
            end
            row = Tsearch(1,:);

        case "manual"
            mt = cfg.stage10.manual_theta;
            row = struct2table(struct( ...
                'h_km', mt.h_km, ...
                'i_deg', mt.i_deg, ...
                'P', mt.P, ...
                'T', mt.T, ...
                'F', mt.F, ...
                'Ns', mt.P * mt.T));

        otherwise
            error('Stage10 theta_source not implemented yet: %s', string(cfg.stage10.theta_source));
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


function Tplane = local_build_plane_table(plane_pack)

    P = plane_pack.P;
    plane_id = (1:P).';
    meas_count = plane_pack.measurement_count_by_plane(:);
    trace_val = nan(P,1);
    fro_val = nan(P,1);
    lambda_min = nan(P,1);

    for p = 1:P
        Wp = plane_pack.W_plane(:,:,p);
        trace_val(p) = trace(Wp);
        fro_val(p) = norm(Wp, 'fro');
        eigv = eig(0.5*(Wp+Wp.'));
        lambda_min(p) = min(real(eigv));
    end

    Tplane = table( ...
        plane_id, meas_count, trace_val, fro_val, lambda_min, ...
        'VariableNames', {'plane_id','measurement_count','trace_Wp','fro_Wp','lambda_min_Wp'});
end
