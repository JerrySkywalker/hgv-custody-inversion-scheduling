function out = group_average_plane_cyclic_stage10(plane_bank, cfg)
%GROUP_AVERAGE_PLANE_CYCLIC_STAGE10 Build an active-plane-preserving proxy.
%
% Stage10.1b improvement over Stage10.1:
%   1) preserve active-plane support set
%   2) preserve total scale (strength conservation)
%   3) use weighted mean shape over active planes
%
% Let each active plane block be:
%   W_p = alpha_p * S_p
% where alpha_p is a scalar scale (trace or fro norm), and S_p is the
% normalized shape block.
%
% We then define:
%   S_bar = sum(alpha_p * S_p) / sum(alpha_p)
% and place identical proxy blocks only on active planes:
%   W_proxy_plane(:,:,p) = alpha_bar * S_bar,  p in active set
% with alpha_bar = sum(alpha_p)/n_active
%
% Hence:
%   sum_p W_proxy_plane(:,:,p) = sum(alpha_p) * S_bar
% which preserves the total scale of active-plane contributions.
%
% For Stage10.1b we still keep zero-lag only in first_col_blocks.
% Non-zero lag blocks are reserved for later Stage10.x.

    if nargin < 2
        error('group_average_plane_cyclic_stage10 requires plane_bank and cfg.');
    end

    cfg = stage10_prepare_cfg(cfg);

    % ------------------------------------------------------------
    % Read inputs
    % ------------------------------------------------------------
    if isfield(plane_bank, 'W_plane')
        W = plane_bank.W_plane;
    elseif isfield(plane_bank, 'plane_blocks_3x3xP')
        W = plane_bank.plane_blocks_3x3xP;
    else
        error('plane_bank must contain W_plane or plane_blocks_3x3xP.');
    end

    P = plane_bank.P;
    active = plane_bank.active_plane_mask(:);
    active_idx = find(active);
    nActive = numel(active_idx);

    % ------------------------------------------------------------
    % Degenerate case: no active plane
    % ------------------------------------------------------------
    if nActive == 0
        Wbar = zeros(3,3);
        alpha_bar = 0;
        alpha_vec = zeros(0,1);
        shape_stack = zeros(3,3,0);
        shape_bar = zeros(3,3);
        plane_blocks_proxy = zeros(3,3,P);
        Wr_fft_proxy = zeros(3,3);
        first_col_blocks = zeros(3,3,P);

        out = struct();
        out.proxy_mode = "active_support_strength_preserving";
        out.shape_norm_mode = string(cfg.stage10.shape_norm_mode);
        out.active_idx = active_idx;
        out.nActive = nActive;
        out.alpha_vec_active = alpha_vec;
        out.alpha_sum = 0;
        out.alpha_bar = alpha_bar;
        out.shape_stack_active = shape_stack;
        out.shape_bar = shape_bar;
        out.Wbar = Wbar;
        out.plane_blocks_cyclic_3x3xP = plane_blocks_proxy;
        out.first_col_blocks_3x3xP = first_col_blocks;
        out.Wr_fft_proxy = Wr_fft_proxy;
        return;
    end

    % ------------------------------------------------------------
    % Decompose each active plane block into scale * shape
    % ------------------------------------------------------------
    alpha_vec = zeros(nActive,1);
    shape_stack = zeros(3,3,nActive);

    for kk = 1:nActive
        p = active_idx(kk);
        Wp = W(:,:,p);

        switch lower(string(cfg.stage10.shape_norm_mode))
            case "trace"
                alpha_p = trace(Wp);
            case "fro"
                alpha_p = norm(Wp, 'fro');
            otherwise
                error('Unknown cfg.stage10.shape_norm_mode: %s', string(cfg.stage10.shape_norm_mode));
        end

        if ~isfinite(alpha_p) || alpha_p <= 0
            alpha_p = 0;
            Sp = zeros(3,3);
        else
            Sp = Wp / alpha_p;
        end

        if cfg.stage10.force_symmetric
            Sp = 0.5 * (Sp + Sp.');
        end

        alpha_vec(kk) = alpha_p;
        shape_stack(:,:,kk) = Sp;
    end

    alpha_sum = sum(alpha_vec);

    if alpha_sum <= 0
        shape_bar = zeros(3,3);
    else
        shape_bar = zeros(3,3);
        for kk = 1:nActive
            shape_bar = shape_bar + alpha_vec(kk) * shape_stack(:,:,kk);
        end
        shape_bar = shape_bar / alpha_sum;
    end

    if cfg.stage10.force_symmetric
        shape_bar = 0.5 * (shape_bar + shape_bar.');
    end

    % Each active plane gets the same proxy block, but only on active support.
    alpha_bar = alpha_sum / nActive;
    Wbar = alpha_bar * shape_bar;

    % ------------------------------------------------------------
    % Support-preserving proxy plane blocks
    % ------------------------------------------------------------
    plane_blocks_proxy = zeros(3,3,P);
    for kk = 1:nActive
        p = active_idx(kk);
        plane_blocks_proxy(:,:,p) = Wbar;
    end

    Wr_fft_proxy = sum(plane_blocks_proxy, 3);
    if cfg.stage10.force_symmetric
        Wr_fft_proxy = 0.5 * (Wr_fft_proxy + Wr_fft_proxy.');
    end

    % ------------------------------------------------------------
    % Stage10.1b first-column block-circulant representation
    %
    % We still keep only lag-0 for now, but we use active-support-preserving
    % total block instead of blindly repeating over all P planes.
    % ------------------------------------------------------------
    first_col_blocks = zeros(3,3,P);
    first_col_blocks(:,:,1) = Wbar;

    % ------------------------------------------------------------
    % Export
    % ------------------------------------------------------------
    out = struct();
    out.proxy_mode = "active_support_strength_preserving";
    out.shape_norm_mode = string(cfg.stage10.shape_norm_mode);

    out.active_idx = active_idx;
    out.nActive = nActive;

    out.alpha_vec_active = alpha_vec;
    out.alpha_sum = alpha_sum;
    out.alpha_bar = alpha_bar;

    out.shape_stack_active = shape_stack;
    out.shape_bar = shape_bar;

    out.Wbar = Wbar;
    out.plane_blocks_cyclic_3x3xP = plane_blocks_proxy;
    out.first_col_blocks_3x3xP = first_col_blocks;
    out.Wr_fft_proxy = Wr_fft_proxy;
end