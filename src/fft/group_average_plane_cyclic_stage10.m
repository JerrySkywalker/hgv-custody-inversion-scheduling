function out = group_average_plane_cyclic_stage10(plane_bank, cfg)
%GROUP_AVERAGE_PLANE_CYCLIC_STAGE10 Build a plane-homogenized cyclic proxy.
%
% Stage10.1 approximation:
%   1) extract each active plane block W_p
%   2) split each W_p into scale * normalized shape
%   3) replace all active planes by a common mean scale and mean shape
%   4) build a zero-lag block-circulant first-column representation
%
% This is intentionally the minimal structured-spectrum proxy for Stage10.1.
% Non-zero relative-lag blocks are deferred to later Stage10.x refinements.

    if nargin < 2
        error('group_average_plane_cyclic_stage10 requires plane_bank and cfg.');
    end

    cfg = stage10_prepare_cfg(cfg);

    W = plane_bank.plane_blocks_3x3xP;
    P = plane_bank.P;
    active = plane_bank.active_plane_mask(:);

    if ~any(active)
        Wbar = zeros(3,3);
        scale_bar = 0;
        shape_bar = zeros(3,3);
        shape_stack = zeros(3,3,0);
        scale_vec = zeros(0,1);
    else
        W_active = W(:,:,active);
        nActive = size(W_active, 3);
        shape_stack = zeros(3,3,nActive);
        scale_vec = zeros(nActive,1);

        for k = 1:nActive
            Wk = W_active(:,:,k);
            switch lower(string(cfg.stage10.shape_norm_mode))
                case "trace"
                    scale_k = trace(Wk);
                case "fro"
                    scale_k = norm(Wk, 'fro');
                otherwise
                    error('Unknown shape_norm_mode: %s', string(cfg.stage10.shape_norm_mode));
            end

            if scale_k <= 0 || ~isfinite(scale_k)
                scale_k = 0;
                shape_k = zeros(3,3);
            else
                shape_k = Wk / scale_k;
            end

            if cfg.stage10.force_symmetric
                shape_k = 0.5 * (shape_k + shape_k.');
            end

            shape_stack(:,:,k) = shape_k;
            scale_vec(k) = scale_k;
        end

        scale_bar = mean(scale_vec);
        shape_bar = mean(shape_stack, 3);
        if cfg.stage10.force_symmetric
            shape_bar = 0.5 * (shape_bar + shape_bar.');
        end
        Wbar = scale_bar * shape_bar;
    end

    % Stage10.1:
    % replicate the mean block to all planes as a homogenized proxy
    plane_blocks_cyclic = repmat(Wbar, 1, 1, P);
    Wr_fft_proxy = sum(plane_blocks_cyclic, 3);
    if cfg.stage10.force_symmetric
        Wr_fft_proxy = 0.5 * (Wr_fft_proxy + Wr_fft_proxy.');
    end

    % block-circulant first column (only lag-0 nonzero for Stage10.1)
    first_col_blocks = zeros(3,3,P);
    first_col_blocks(:,:,1) = Wbar;

    out = struct();
    out.proxy_mode = string(cfg.stage10.fft_proxy_mode);
    out.shape_norm_mode = string(cfg.stage10.shape_norm_mode);
    out.Wbar = Wbar;
    out.scale_bar = scale_bar;
    out.shape_bar = shape_bar;
    out.scale_vec_active = scale_vec;
    out.shape_stack_active = shape_stack;
    out.plane_blocks_cyclic_3x3xP = plane_blocks_cyclic;
    out.first_col_blocks_3x3xP = first_col_blocks;
    out.Wr_fft_proxy = Wr_fft_proxy;
end