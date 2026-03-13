function out = group_average_plane_cyclic_stage10(plane_bank, cfg)
%GROUP_AVERAGE_PLANE_CYCLIC_STAGE10 Build a non-circular template proxy.
%
% Stage10.1c:
%   Use current window only for low-order support information:
%       - active-plane support set
%       - measurement counts by plane
%   But do NOT use current true plane blocks W_p to build proxy shape/scale.
%
% Proxy model:
%   W_proxy_plane(:,:,p) = n_p * alpha_obs_template * S_template,  p in active set
% where
%   n_p   : observation count on plane p in current window
%   alpha_obs_template : fixed/offline template per-observation strength
%   S_template         : fixed/offline normalized shape template
%
% This avoids circular reconstruction while keeping support-awareness.

    if nargin < 2
        error('group_average_plane_cyclic_stage10 requires plane_bank and cfg.');
    end

    cfg = stage10_prepare_cfg(cfg);

    P = plane_bank.P;
    active = plane_bank.active_plane_mask(:);
    active_idx = find(active);
    nActive = numel(active_idx);

    if isfield(plane_bank, 'measurement_count_by_plane')
        meas_count = plane_bank.measurement_count_by_plane(:);
    elseif isfield(plane_bank, 'plane_visible_obs')
        meas_count = plane_bank.plane_visible_obs(:);
    else
        error('plane_bank must contain measurement_count_by_plane or plane_visible_obs.');
    end

    % ------------------------------------------------------------
    % Build template shape
    % ------------------------------------------------------------
    switch lower(string(cfg.stage10.template_mode))
        case "fixed_isotropic_like"
            S_template = cfg.stage10.template_shape_matrix;
        case "custom_matrix"
            S_template = cfg.stage10.template_shape_matrix;
        otherwise
            error('Unknown cfg.stage10.template_mode: %s', string(cfg.stage10.template_mode));
    end

    if cfg.stage10.force_symmetric
        S_template = 0.5 * (S_template + S_template.');
    end

    % normalize template shape according to selected convention
    switch lower(string(cfg.stage10.shape_norm_mode))
        case "trace"
            denom = trace(S_template);
        case "fro"
            denom = norm(S_template, 'fro');
        otherwise
            error('Unknown cfg.stage10.shape_norm_mode: %s', string(cfg.stage10.shape_norm_mode));
    end

    if denom <= 0 || ~isfinite(denom)
        error('Template shape normalization denominator must be positive.');
    end
    S_template = S_template / denom;

    alpha_obs = cfg.stage10.template_alpha_per_obs;

    % ------------------------------------------------------------
    % Build support-aware proxy from counts only
    % ------------------------------------------------------------
    plane_blocks_proxy = zeros(3,3,P);
    alpha_vec_active = zeros(nActive,1);

    for kk = 1:nActive
        p = active_idx(kk);
        np = meas_count(p);

        switch lower(string(cfg.stage10.proxy_scale_mode))
            case "count_times_alpha"
                alpha_p = np * alpha_obs;
            otherwise
                error('Unknown cfg.stage10.proxy_scale_mode: %s', string(cfg.stage10.proxy_scale_mode));
        end

        plane_blocks_proxy(:,:,p) = alpha_p * S_template;
        alpha_vec_active(kk) = alpha_p;
    end

    Wr_fft_proxy = sum(plane_blocks_proxy, 3);
    if cfg.stage10.force_symmetric
        Wr_fft_proxy = 0.5 * (Wr_fft_proxy + Wr_fft_proxy.');
    end

    % ------------------------------------------------------------
    % Stage10.1c first-column block-circulant representation
    %
    % Still zero-lag only for now, but now the lag-0 representative block
    % is a template block rather than a truth-derived block.
    % ------------------------------------------------------------
    first_col_blocks = zeros(3,3,P);
    if nActive > 0
        alpha_bar = mean(alpha_vec_active);
        Wbar = alpha_bar * S_template;
        first_col_blocks(:,:,1) = Wbar;
    else
        alpha_bar = 0;
        Wbar = zeros(3,3);
    end

    % ------------------------------------------------------------
    % Export
    % ------------------------------------------------------------
    out = struct();
    out.proxy_mode = "template_active_support";
    out.shape_norm_mode = string(cfg.stage10.shape_norm_mode);
    out.template_mode = string(cfg.stage10.template_mode);
    out.proxy_scale_mode = string(cfg.stage10.proxy_scale_mode);

    out.active_idx = active_idx;
    out.nActive = nActive;
    out.measurement_count_by_plane = meas_count;

    out.alpha_obs_template = alpha_obs;
    out.alpha_vec_active = alpha_vec_active;
    out.alpha_sum = sum(alpha_vec_active);
    out.alpha_bar = alpha_bar;

    out.shape_bar = S_template;                % keep field name for compatibility
    out.shape_stack_active = [];              % no truth-derived shape stack now
    out.Wbar = Wbar;

    out.plane_blocks_cyclic_3x3xP = plane_blocks_proxy;
    out.first_col_blocks_3x3xP = first_col_blocks;
    out.Wr_fft_proxy = Wr_fft_proxy;
end