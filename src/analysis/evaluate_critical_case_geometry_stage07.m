function result = evaluate_critical_case_geometry_stage07(case_item, reference_walker, gamma_req, cfg)
    %EVALUATE_CRITICAL_CASE_GEOMETRY_STAGE07
    % Evaluate one target case under a fixed reference Walker using
    % existing Stage03 + Stage04 pipeline.

    if nargin < 4 || isempty(cfg)
        cfg = default_params();
    end

    assert(isstruct(case_item) && isfield(case_item, 'traj'), ...
        'case_item must contain traj.');
    assert(isstruct(reference_walker), ...
        'reference_walker must be a struct.');

    assert(isfield(case_item.traj, 't_s') && ~isempty(case_item.traj.t_s), ...
        'case_item.traj.t_s is missing.');
    t_s_common = case_item.traj.t_s(:);

    cfg_eval = cfg;
    cfg_eval.stage03.h_km = reference_walker.h_km;
    cfg_eval.stage03.i_deg = reference_walker.i_deg;
    cfg_eval.stage03.P = reference_walker.P;
    cfg_eval.stage03.T = reference_walker.T;
    cfg_eval.stage03.F = reference_walker.F;
    cfg_eval.stage04.gamma_req = gamma_req;

    [walker, satbank] = local_get_constellation_cache(reference_walker, t_s_common, cfg_eval);

    vis_case = compute_visibility_matrix_stage03(case_item, satbank, cfg_eval);
    s_vis = local_summarize_visibility_fast(vis_case, satbank);

    window_case = scan_worst_window_stage04(vis_case, satbank, cfg_eval);
    s_win = summarize_window_case_stage04(window_case);

    coverage_ratio_2sat = local_try_get_struct_numeric(s_vis, 'dual_coverage_ratio', NaN);
    mean_los_intersection_angle_deg = local_try_get_struct_numeric(s_vis, 'mean_los_crossing_angle_deg', NaN);
    min_los_intersection_angle_deg = local_try_get_struct_numeric(s_vis, 'min_los_crossing_angle_deg', NaN);

    lambda_worst = local_try_get_struct_numeric(s_win, 'lambda_min_worst', NaN);
    t0_worst = local_try_get_struct_numeric(s_win, 't0_worst_s', NaN);
    n_visible_windows = local_try_get_struct_numeric(s_win, 'num_windows', NaN);

    D_G_min = NaN;
    if isfinite(lambda_worst) && isfinite(gamma_req) && gamma_req > 0
        D_G_min = lambda_worst / gamma_req;
    end

    case_s = case_item.case;

    diag_row = struct();
    diag_row.case_id = string(local_try_get_struct_string(case_s, 'case_id', ""));
    diag_row.source_case_id = string(local_try_get_struct_string(case_s, 'source_case_id', ""));
    diag_row.critical_mode = string(local_try_get_struct_string(case_s, 'critical_mode', ""));
    diag_row.critical_branch = string(local_try_get_struct_string(case_s, 'critical_branch', ""));

    diag_row.entry_id = local_try_get_struct_numeric(case_s, 'entry_id', NaN);
    diag_row.entry_lat_deg = local_try_get_struct_numeric(case_s, 'entry_lat_deg', NaN);
    diag_row.entry_lon_deg = local_try_get_struct_numeric(case_s, 'entry_lon_deg', NaN);

    diag_row.nominal_heading_deg = local_try_get_struct_numeric(case_s, 'nominal_heading_deg', NaN);
    diag_row.critical_heading_deg = local_try_get_struct_numeric(case_s, 'heading_deg', NaN);
    diag_row.heading_offset_deg = local_try_get_struct_numeric(case_s, 'heading_offset_deg', NaN);
    diag_row.heading_deg = local_try_get_struct_numeric(case_s, 'heading_deg', NaN);

    diag_row.h_km = reference_walker.h_km;
    diag_row.i_deg = reference_walker.i_deg;
    diag_row.P = reference_walker.P;
    diag_row.T = reference_walker.T;
    diag_row.F = reference_walker.F;
    diag_row.Ns = reference_walker.Ns;

    diag_row.coverage_ratio_2sat = coverage_ratio_2sat;
    diag_row.mean_los_intersection_angle_deg = mean_los_intersection_angle_deg;
    diag_row.min_los_intersection_angle_deg = min_los_intersection_angle_deg;

    diag_row.lambda_worst = lambda_worst;
    diag_row.D_G_min = D_G_min;
    diag_row.t0_worst = t0_worst;
    diag_row.n_visible_windows = n_visible_windows;

    result = struct();
    result.walker = walker;
    result.satbank = satbank;
    result.visibility_summary = s_vis;
    result.window_summary = s_win;
    result.diag_row = diag_row;
end

function x = local_try_get_struct_numeric(S, field_name, fallback)
    x = fallback;
    if isstruct(S) && isfield(S, field_name)
        val = S.(field_name);
        if isnumeric(val) && ~isempty(val) && isfinite(val(1))
            x = double(val(1));
        end
    end
end

function s = local_try_get_struct_string(S, field_name, fallback)
    s = fallback;
    if isstruct(S) && isfield(S, field_name)
        val = S.(field_name);
        if ischar(val) || isstring(val)
            s = char(string(val));
        end
    end
end

function s_vis = local_summarize_visibility_fast(vis_case, satbank)
    s_vis = struct();
    s_vis.dual_coverage_ratio = mean(vis_case.dual_coverage_mask, 'omitnan');

    [min_cross_deg, mean_cross_deg] = local_compute_crossing_angle_summary(vis_case, satbank);
    s_vis.min_los_crossing_angle_deg = min_cross_deg;
    s_vis.mean_los_crossing_angle_deg = mean_cross_deg;
end

function [min_cross_deg, mean_cross_deg] = local_compute_crossing_angle_summary(vis_case, satbank)
    visible_mask = vis_case.visible_mask;
    Nt = numel(vis_case.t_s);
    r_tgt = vis_case.r_tgt_eci_km;
    r_sat = permute(satbank.r_eci_km(1:Nt, :, :), [1, 3, 2]);

    min_series = nan(Nt, 1);
    mean_series = nan(Nt, 1);

    for k = 1:Nt
        idx = find(visible_mask(k, :));
        if numel(idx) < 2
            continue;
        end

        tgt_k = reshape(r_tgt(k, :), [1, 1, 3]);
        los = squeeze(tgt_k - r_sat(k, idx, :));
        if size(los, 1) < 2
            continue;
        end

        los_norm = sqrt(sum(los.^2, 2));
        los_unit = los ./ max(los_norm, eps);
        gram = los_unit * los_unit.';
        gram = min(max(gram, -1), 1);
        iu = triu(true(size(gram)), 1);
        if ~any(iu(:))
            continue;
        end

        angles = acosd(gram(iu));
        min_series(k) = min(angles);
        mean_series(k) = mean(angles);
    end

    valid_idx = ~isnan(min_series);
    if any(valid_idx)
        min_cross_deg = min(min_series(valid_idx));
        mean_cross_deg = mean(mean_series(valid_idx), 'omitnan');
    else
        min_cross_deg = NaN;
        mean_cross_deg = NaN;
    end
end

function [walker, satbank] = local_get_constellation_cache(reference_walker, t_s_common, cfg_eval)
    persistent cache_bank

    cache_key = local_build_constellation_cache_key(reference_walker, t_s_common);
    if isempty(cache_bank)
        cache_bank = struct('key', {}, 'walker', {}, 'satbank', {});
    end

    hit_idx = [];
    for i = 1:numel(cache_bank)
        if strcmp(cache_bank(i).key, cache_key)
            hit_idx = i;
            break;
        end
    end

    if isempty(hit_idx)
        walker = build_single_layer_walker_stage03(cfg_eval);
        satbank = propagate_constellation_stage03(walker, t_s_common);

        entry = struct();
        entry.key = cache_key;
        entry.walker = walker;
        entry.satbank = satbank;
        cache_bank = [entry, cache_bank]; %#ok<AGROW>
        if numel(cache_bank) > 8
            cache_bank = cache_bank(1:8);
        end
    else
        walker = cache_bank(hit_idx).walker;
        satbank = cache_bank(hit_idx).satbank;
        if hit_idx > 1
            cache_bank = [cache_bank(hit_idx), cache_bank(1:hit_idx-1), cache_bank(hit_idx+1:end)];
        end
    end
end

function cache_key = local_build_constellation_cache_key(reference_walker, t_s_common)
    if isempty(t_s_common)
        time_key = 'empty';
    else
        time_key = sprintf('n%d_t0%.6f_tn%.6f_dt%.6f', ...
            numel(t_s_common), t_s_common(1), t_s_common(end), local_estimate_time_step(t_s_common));
    end

    cache_key = sprintf('h%.6f_i%.6f_P%d_T%d_F%d_%s', ...
        reference_walker.h_km, ...
        reference_walker.i_deg, ...
        reference_walker.P, ...
        reference_walker.T, ...
        reference_walker.F, ...
        time_key);
end

function dt = local_estimate_time_step(t_s_common)
    if numel(t_s_common) < 2
        dt = 0;
    else
        dt = median(diff(t_s_common));
    end
end
