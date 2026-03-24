function out = compute_eps_sb_stage10(Wr_full, Wr_proxy, cfg)
%COMPUTE_EPS_SB_STAGE10 Compute symmetry-breaking magnitude.

    if nargin < 3
        cfg = default_params();
    end
    cfg = stage10_prepare_cfg(cfg);

    D = Wr_full - Wr_proxy;
    if cfg.stage10.force_symmetric
        D = 0.5 * (D + D.');
    end

    switch cfg.stage10.eps_sb_norm
        case 2
            eps_sb = norm(D, 2);
        case 'fro'
            eps_sb = norm(D, 'fro');
        otherwise
            eps_sb = norm(D, cfg.stage10.eps_sb_norm);
    end

    out = struct();
    out.delta_W = D;
    out.eps_sb = eps_sb;
    out.delta_trace = trace(D);
    out.delta_fro = norm(D, 'fro');
    out.delta_max_abs = max(abs(D(:)));
end