function out = compare_fft_vs_full_stage10(Wr_full, plane_bank, cfg)
%COMPARE_FFT_VS_FULL_STAGE10 Compare full window matrix vs FFT cyclic proxy.
%
% Inputs:
%   Wr_full    : 3x3 full window information matrix
%   plane_bank : output of wr_build_plane_blocks_stage10
%   cfg        : default cfg / Stage10-prepared cfg
%
% Output fields include both:
%   - canonical names for later Stage10.x
%   - compatibility aliases used by Stage10.1 main script

    if nargin < 3
        error('compare_fft_vs_full_stage10 requires Wr_full, plane_bank, cfg.');
    end

    cfg = stage10_prepare_cfg(cfg);

    if isfield(cfg.stage10, 'force_symmetric') && cfg.stage10.force_symmetric
        Wr_full = 0.5 * (Wr_full + Wr_full.');
    end

    % ------------------------------------------------------------
    % FFT proxy path
    % ------------------------------------------------------------
    t_fft_start = tic;
    cyclic = group_average_plane_cyclic_stage10(plane_bank, cfg);
    fft_spec = bcirc_fft_minEig_stage10(cyclic.first_col_blocks_3x3xP, cfg);
    t_fft = toc(t_fft_start);

    % ------------------------------------------------------------
    % Full truth metric
    % ------------------------------------------------------------
    t_full_start = tic;
    full_metric = compute_window_metrics_stage09(Wr_full, cfg);
    t_full = toc(t_full_start);

    % ------------------------------------------------------------
    % Proxy metric in the same Stage09 metric space
    % ------------------------------------------------------------
    proxy_metric = compute_window_metrics_stage09(cyclic.Wr_fft_proxy, cfg);

    % ------------------------------------------------------------
    % Symmetry-breaking measures
    % ------------------------------------------------------------
    eps_fro_struct = compute_eps_sb_stage10(Wr_full, cyclic.Wr_fft_proxy, cfg);

    % also compute spectral norm variant for reporting
    cfg_2 = cfg;
    cfg_2.stage10.eps_sb_norm = 2;
    eps_2_struct = compute_eps_sb_stage10(Wr_full, cyclic.Wr_fft_proxy, cfg_2);

    % ------------------------------------------------------------
    % Simple bounds
    % ------------------------------------------------------------
    compute_bounds = true;
    if isfield(cfg.stage10, 'compute_bounds')
        compute_bounds = logical(cfg.stage10.compute_bounds);
    end

    if compute_bounds
        % for Stage10.1 we use spectral-norm perturbation as main bound
        lambda_lb = max(proxy_metric.lambda_min_eff - eps_2_struct.eps_sb, 0);
        lambda_ub = proxy_metric.lambda_min_eff + eps_2_struct.eps_sb;
        bound_hit_flag = ...
            (full_metric.lambda_min_eff >= lambda_lb - 1e-12) && ...
            (full_metric.lambda_min_eff <= lambda_ub + 1e-12);
    else
        lambda_lb = nan;
        lambda_ub = nan;
        bound_hit_flag = false;
    end

    % ------------------------------------------------------------
    % Summary
    % ------------------------------------------------------------
    out = struct();

    % raw structs
    out.full_metric = full_metric;
    out.proxy_metric = proxy_metric;
    out.cyclic = cyclic;
    out.fft_spec = fft_spec;
    out.eps_fro_struct = eps_fro_struct;
    out.eps_2_struct = eps_2_struct;

    % canonical names
    out.lambda_full_raw = full_metric.lambda_min_raw;
    out.lambda_full_eff = full_metric.lambda_min_eff;
    out.lambda_fft_raw = proxy_metric.lambda_min_raw;
    out.lambda_fft_eff = proxy_metric.lambda_min_eff;

    out.lambda_fft_zero_mode = fft_spec.lambda_zero_mode;
    out.lambda_fft_mode_min = fft_spec.lambda_mode_min;

    out.abs_err_lambda = abs(out.lambda_full_eff - out.lambda_fft_eff);
    denom = max(abs(out.lambda_full_eff), eps);
    out.rel_err_lambda = out.abs_err_lambda / denom;

    out.DG_full = full_metric.DG;
    out.DG_fft = proxy_metric.DG;
    out.DA_full = full_metric.DA;
    out.DA_fft = proxy_metric.DA;

    out.lambda_lb = lambda_lb;
    out.lambda_ub = lambda_ub;
    out.bound_contains_full = bound_hit_flag;

    out.time_full_s = t_full;
    out.time_fft_s = t_fft;
    out.speedup_full_over_fft = t_full / max(t_fft, eps);

    % compatibility aliases for current stage10 main script
    out.lambda_blk_full_eff = out.lambda_full_eff;
    out.lambda_blk_fft_eff = out.lambda_fft_eff;

    out.eps_sb_fro = eps_fro_struct.eps_sb;
    out.eps_sb_2 = eps_2_struct.eps_sb;

    out.bound_lb = lambda_lb;
    out.bound_ub = lambda_ub;
    out.bound_hit_flag = bound_hit_flag;

    if isfield(plane_bank, 'active_plane_mask')
        out.plane_count_nonzero = nnz(plane_bank.active_plane_mask);
    else
        out.plane_count_nonzero = nan;
    end

    if isfield(plane_bank, 'measurement_count_total')
        out.measurement_count_total = plane_bank.measurement_count_total;
    else
        out.measurement_count_total = nan;
    end

    if isfield(cfg.stage10, 'fft_proxy_mode') && isfield(cfg.stage10, 'shape_norm_mode')
        out.note = string(sprintf(['Stage10.1 proxy=%s, shape_norm=%s; ', ...
            'zero-lag cyclic homogenization only.'], ...
            char(cfg.stage10.fft_proxy_mode), char(cfg.stage10.shape_norm_mode)));
    else
        out.note = "Stage10.1 zero-lag cyclic homogenization only.";
    end
end