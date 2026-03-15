function input_dataset = stage11_build_input_dataset(cfg)
%STAGE11_BUILD_INPUT_DATASET Build Stage11 window/case tables for fresh small benchmarks.

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    stage10_meta = local_init_stage10_meta(cfg);
    gamma_eff_scalar = 1.0;
    theta_grid = local_build_theta_grid(cfg, stage10_meta);
    trajs_in = local_build_casebank(cfg);
    eval_ctx = build_stage09_eval_context(trajs_in, cfg, gamma_eff_scalar);

    window_rows = cell(0,1);
    case_rows = cell(0,1);
    detail_list = cell(0,1);
    window_row_counter = 0;
    detail_counter = 0;
    total_window_cap_hit = false;
    t_global = tic;

    n_theta = height(theta_grid);
    for itheta = 1:n_theta
        row = theta_grid(itheta,:);
        cfg_eval = cfg;
        cfg_eval.stage03.h_km = row.h_km;
        cfg_eval.stage03.i_deg = row.i_deg;
        cfg_eval.stage03.P = row.P;
        cfg_eval.stage03.T = row.T;
        cfg_eval.stage03.F = row.F;
        walker = build_single_layer_walker_stage03(cfg_eval);
        satbank = propagate_constellation_stage03(walker, eval_ctx.t_s_common);

        local_progress(cfg, '[stage11][input] theta %d/%d started: h=%.0f i=%.0f P=%d T=%d elapsed=%.1fs', ...
            itheta, n_theta, row.h_km, row.i_deg, row.P, row.T, toc(t_global));

        for icase = 1:numel(trajs_in)
            if window_row_counter >= cfg.stage11.max_total_windows
                total_window_cap_hit = true;
                break;
            end

            traj_case = trajs_in(icase);
            vis_case = compute_visibility_matrix_stage03(traj_case, satbank, cfg_eval);
            window_grid = build_window_grid_stage04(vis_case.t_s, cfg_eval);
            n_window_full = window_grid.num_windows;
            if n_window_full < 1
                error('Stage11 found no valid windows for case %s.', string(traj_case.case.case_id));
            end

            selected_window_ids = local_select_window_ids(window_grid, cfg);
            remaining_slots = cfg.stage11.max_total_windows - window_row_counter;
            if numel(selected_window_ids) > remaining_slots
                selected_window_ids = selected_window_ids(1:remaining_slots);
                total_window_cap_hit = true;
            end

            detail_counter = detail_counter + 1;
            detail_list{detail_counter, 1} = struct( ... %#ok<AGROW>
                'theta_id', itheta, ...
                'case_id', string(traj_case.case.case_id), ...
                'traj_case', traj_case, ...
                'vis_case', vis_case, ...
                'walker', walker, ...
                'satbank', satbank, ...
                'window_grid', window_grid, ...
                'selected_window_ids', selected_window_ids);

            n_window = numel(selected_window_ids);
            case_window_rows = zeros(n_window, 1);
            truth_lambda = nan(n_window, 1);
            zero_mode = nan(n_window, 1);
            bcirc_lambda = nan(n_window, 1);

            for ilocal = 1:n_window
                iw = selected_window_ids(ilocal);
                idx_start = window_grid.start_idx(iw);
                idx_end = window_grid.end_idx(iw);

                Wr = build_window_info_matrix_stage04(vis_case, idx_start, idx_end, satbank, cfg_eval);
                if cfg.stage11.force_symmetric
                    Wr = 0.5 * (Wr + Wr.');
                end
                wm = compute_window_metrics_stage09(Wr, cfg_eval);
                old_pack = local_compute_old_pack(vis_case, idx_start, idx_end, satbank, walker, Wr, cfg_eval);

                window_row_counter = window_row_counter + 1;
                case_window_rows(ilocal) = window_row_counter;
                truth_lambda(ilocal) = wm.lambda_min_eff;
                zero_mode(ilocal) = old_pack.lambda_zero_mode;
                bcirc_lambda(ilocal) = old_pack.lambda_min_bcirc;

                local_progress(cfg, ['[stage11][input] theta %d/%d case %s (%d/%d) window %d/%d ' ...
                    '(global %d/%d) elapsed=%.1fs'], ...
                    itheta, n_theta, char(string(traj_case.case.case_id)), icase, numel(trajs_in), ...
                    iw, n_window_full, window_row_counter, cfg.stage11.max_total_windows, toc(t_global));

                window_rows{window_row_counter, 1} = struct( ... %#ok<AGROW>
                    'row_id', window_row_counter, ...
                    'theta_id', itheta, ...
                    'case_id', string(traj_case.case.case_id), ...
                    'case_index', icase, ...
                    'detail_id', detail_counter, ...
                    'window_id', iw, ...
                    'window_rank_local', ilocal, ...
                    'window_count_full', n_window_full, ...
                    'window_count_selected', n_window, ...
                    'idx_start', idx_start, ...
                    'idx_end', idx_end, ...
                    't0_s', window_grid.t0_s(iw), ...
                    't1_s', window_grid.t1_s(iw), ...
                    'theta_struct', local_theta_struct(row), ...
                    'Wr', {Wr}, ...
                    'truth_lambda_min', wm.lambda_min_eff, ...
                    'truth_DG', wm.DG, ...
                    'truth_pass', wm.lambda_min_eff >= cfg.stage11.threshold_truth, ...
                    'old_bound', old_pack.bcirc_lb, ...
                    'old_DG', old_pack.bcirc_lb / gamma_eff_scalar, ...
                    'old_zero_mode', old_pack.lambda_zero_mode, ...
                    'old_zero_lb', old_pack.zero_lb, ...
                    'old_lambda_min_bcirc', old_pack.lambda_min_bcirc, ...
                    'old_bcirc_lb', old_pack.bcirc_lb, ...
                    'old_eps_sb_2', old_pack.eps_sb_2, ...
                    'old_zero_pass', old_pack.zero_pass, ...
                    'old_bcirc_pass', old_pack.bcirc_pass, ...
                    'old_stage_label', string(old_pack.stage_label), ...
                    'case_family', string(local_safe_get(traj_case.case, 'family', "")), ...
                    'case_subfamily', string(local_safe_get(traj_case.case, 'subfamily', "")), ...
                    'entry_id', local_safe_get(traj_case.case, 'entry_id', nan), ...
                    'heading_offset_deg', local_safe_get(traj_case.case, 'heading_offset_deg', nan), ...
                    'visible_count_mean', mean(vis_case.num_visible(idx_start:idx_end)), ...
                    'stage10_cache_file', string(stage10_meta.cache_file));
            end

            truth_case_pass = min(truth_lambda) >= cfg.stage11.threshold_truth;
            zero_case_pass = min(zero_mode) >= cfg.stage11.threshold_zero;
            bcirc_case_pass = min(bcirc_lambda) >= cfg.stage11.threshold_bcirc;

            case_rows{end+1, 1} = struct( ... %#ok<AGROW>
                'theta_id', itheta, ...
                'case_id', string(traj_case.case.case_id), ...
                'case_index', icase, ...
                'detail_id', detail_counter, ...
                'theta_struct', local_theta_struct(row), ...
                'truth_case_label', string(local_truth_label(truth_case_pass)), ...
                'old_case_label', string(local_old_label(zero_case_pass, bcirc_case_pass)), ...
                'truth_case_pass', truth_case_pass, ...
                'old_zero_case_pass', zero_case_pass, ...
                'old_bcirc_case_pass', bcirc_case_pass, ...
                'truth_lambda_worst', min(truth_lambda), ...
                'old_zero_worst', min(zero_mode), ...
                'old_bcirc_worst', min(bcirc_lambda), ...
                'window_index_list', {case_window_rows}, ...
                'window_count', n_window, ...
                'window_count_full', n_window_full, ...
                'case_family', string(local_safe_get(traj_case.case, 'family', "")), ...
                'case_subfamily', string(local_safe_get(traj_case.case, 'subfamily', "")), ...
                'heading_offset_deg', local_safe_get(traj_case.case, 'heading_offset_deg', nan));
        end

        if total_window_cap_hit
            local_progress(cfg, '[stage11][input] stopped at theta %d because max_total_windows=%d was reached.', ...
                itheta, cfg.stage11.max_total_windows);
            break;
        end
    end

    if isempty(window_rows)
        error('Stage11 input dataset is empty after applying case/window filters.');
    end

    input_dataset = struct();
    input_dataset.stage10_meta = stage10_meta;
    input_dataset.theta_grid = theta_grid;
    input_dataset.detail_list = detail_list;
    input_dataset.window_table = struct2table(vertcat(window_rows{:}), 'AsArray', true);
    input_dataset.case_table = struct2table(vertcat(case_rows{:}), 'AsArray', true);
    input_dataset.cache_reuse_mode = stage10_meta.cache_reuse_mode;
    input_dataset.n_windows_reused = 0;
    input_dataset.n_windows_recomputed = height(input_dataset.window_table);
    input_dataset.cache_files = stage10_meta.cache_files;
    input_dataset.total_window_cap_hit = total_window_cap_hit;
end


function stage10_meta = local_init_stage10_meta(cfg)
    use_stage10 = strcmpi(char(string(cfg.stage11.cache_mode)), 'reuse_or_build') ...
        || strcmpi(char(string(cfg.stage11.theta_source)), 'stage10e1_grid');
    if use_stage10
        stage10_meta = stage11_load_stage10_cache(cfg);
        return;
    end

    stage10_meta = struct();
    stage10_meta.cache_file = "";
    stage10_meta.cache_files = struct('stage10E1', "", 'stage10E', "");
    stage10_meta.cache_reuse_mode = "build_fresh_small";
    stage10_meta.grid = struct( ...
        'h_km', cfg.stage11.grid_h_km, ...
        'i_deg', cfg.stage11.grid_i_deg, ...
        'P', cfg.stage11.grid_P, ...
        'T', cfg.stage11.grid_T, ...
        'F', cfg.stage11.grid_F);
end


function theta_grid = local_build_theta_grid(cfg, stage10_meta)
    grid = struct( ...
        'h_km', cfg.stage11.grid_h_km, ...
        'i_deg', cfg.stage11.grid_i_deg, ...
        'P', cfg.stage11.grid_P, ...
        'T', cfg.stage11.grid_T, ...
        'F', cfg.stage11.grid_F);
    if nargin >= 2 && isfield(stage10_meta, 'grid') && strcmpi(char(string(cfg.stage11.theta_source)), 'stage10e1_grid')
        grid = stage10_meta.grid;
    end

    rows = cell(0,1);
    idx = 0;
    for ih = 1:numel(grid.h_km)
        for ii = 1:numel(grid.i_deg)
            for ip = 1:numel(grid.P)
                for it = 1:numel(grid.T)
                    idx = idx + 1;
                    rows{idx,1} = struct( ... %#ok<AGROW>
                        'theta_id', idx, ...
                        'h_km', grid.h_km(ih), ...
                        'i_deg', grid.i_deg(ii), ...
                        'P', grid.P(ip), ...
                        'T', grid.T(it), ...
                        'F', grid.F, ...
                        'Ns', grid.P(ip) * grid.T(it));
                end
            end
        end
    end
    theta_grid = struct2table(vertcat(rows{:}));
end


function trajs_in = local_build_casebank(cfg)
    switch lower(char(string(cfg.stage11.case_mode)))
        case 'tiny_manual'
            stage01_out = stage01_scenario_disk(cfg);
            selected_cases = local_select_cases_by_id(stage01_out.casebank, cfg.stage11.case_ids);
            n_case = numel(selected_cases);
            trajs_in = repmat(struct('case', [], 'traj', [], 'validation', [], 'summary', []), n_case, 1);
            for i = 1:n_case
                case_i = selected_cases(i);
                traj_i = propagate_hgv_case_stage02(case_i, cfg);
                val_i = validate_hgv_trajectory_stage02(traj_i, cfg);
                sum_i = summarize_hgv_case_stage02(case_i, traj_i, val_i);
                trajs_in(i).case = case_i;
                trajs_in(i).traj = traj_i;
                trajs_in(i).validation = val_i;
                trajs_in(i).summary = sum_i;
            end

        case 'stage09_casebank'
            cfg_case = cfg;
            cfg_case.stage09.casebank_mode = cfg.stage11.casebank_mode;
            trajs_in = build_stage09_casebank(cfg_case);

        otherwise
            error('Unsupported cfg.stage11.case_mode: %s', string(cfg.stage11.case_mode));
    end
end


function selected_cases = local_select_cases_by_id(casebank, case_ids)
    case_ids = string(case_ids(:));
    all_cases = vertcat(casebank.nominal(:), casebank.heading(:), casebank.critical(:));
    selected_cases = repmat(all_cases(1), 0, 1);
    for i = 1:numel(case_ids)
        match_idx = find(strcmp(string({all_cases.case_id}), case_ids(i)), 1, 'first');
        if isempty(match_idx)
            error('Stage11 tiny_manual case_id not found: %s', case_ids(i));
        end
        selected_cases(end+1,1) = all_cases(match_idx); %#ok<AGROW>
    end
end


function selected_window_ids = local_select_window_ids(window_grid, cfg)
    n_window = window_grid.num_windows;
    full_ids = (1:n_window).';
    switch lower(char(string(cfg.stage11.window_mode)))
        case 'full'
            selected_window_ids = full_ids;

        case 'sparse'
            n_keep = min(n_window, cfg.stage11.max_windows_per_case);
            if n_keep >= n_window
                selected_window_ids = full_ids;
                return;
            end

            sample_ids = unique(round(linspace(1, n_window, n_keep)).');
            anchor_ids = unique([1; round((n_window + 1) / 2); n_window]);
            selected_window_ids = unique([anchor_ids; sample_ids], 'stable');
            if numel(selected_window_ids) > n_keep
                selected_window_ids = selected_window_ids(1:n_keep);
            end

        otherwise
            error('Unsupported cfg.stage11.window_mode: %s', string(cfg.stage11.window_mode));
    end
end


function old_pack = local_compute_old_pack(vis_case, idx_start, idx_end, satbank, walker, Wr, cfg)
    plane_pack = wr_build_plane_blocks_stage10(vis_case, idx_start, idx_end, satbank, walker, cfg);
    lag_pack = wr_build_plane_lag_tensor_stage10A(plane_pack, cfg);
    bcirc_pack = group_average_to_bcirc_stage10B(lag_pack, cfg);

    sym_out = symmetrize_firstcol_bcirc_stage10B1(bcirc_pack.first_col_blocks_3x3xP, cfg);
    psd_out = project_bcirc_psd_stage10B1(sym_out.first_col_blocks_sym, cfg);
    spec = bcirc_fft_minEig_stage10C(psd_out.first_col_blocks_psd, cfg);
    A0 = psd_out.mode_blocks_after(:,:,1);
    eps_pack = compute_eps_sb_stage10D(Wr, A0, cfg);

    old_pack = struct();
    old_pack.lambda_zero_mode = min(real(eig(0.5 * (A0 + A0.'))));
    old_pack.lambda_min_bcirc = spec.lambda_min_fft;
    old_pack.eps_sb_2 = eps_pack.eps_sb_2;
    old_pack.zero_lb = old_pack.lambda_zero_mode - old_pack.eps_sb_2;
    old_pack.bcirc_lb = old_pack.lambda_min_bcirc - old_pack.eps_sb_2;
    old_pack.zero_pass = old_pack.lambda_zero_mode >= cfg.stage11.threshold_zero;
    old_pack.bcirc_pass = old_pack.lambda_min_bcirc >= cfg.stage11.threshold_bcirc;
    old_pack.stage_label = local_old_label(old_pack.zero_pass, old_pack.bcirc_pass);
end


function theta = local_theta_struct(row)
    theta = struct( ...
        'h_km', row.h_km, ...
        'i_deg', row.i_deg, ...
        'P', row.P, ...
        'T', row.T, ...
        'F', row.F, ...
        'Ns', row.Ns);
end


function label = local_old_label(zero_pass, bcirc_pass)
    if ~zero_pass
        label = "reject";
    elseif bcirc_pass
        label = "safe_pass";
    else
        label = "warn_pass";
    end
end


function label = local_truth_label(truth_pass)
    if truth_pass
        label = "truth_pass";
    else
        label = "truth_fail";
    end
end


function value = local_safe_get(s, field_name, default_value)
    if isfield(s, field_name)
        value = s.(field_name);
    else
        value = default_value;
    end
end


function local_progress(cfg, fmt, varargin)
    if cfg.stage11.log_every_window
        fprintf('%s\n', sprintf(fmt, varargin{:}));
    end
end
