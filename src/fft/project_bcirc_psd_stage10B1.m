function out = project_bcirc_psd_stage10B1(first_col_blocks, cfg)
%PROJECT_BCIRC_PSD_STAGE10B1
% Project a symmetric bcirc prototype to a PSD-legal bcirc matrix by
% projecting each Fourier mode block onto the PSD cone.
%
% Steps:
%   1) build mode blocks by DFT of first-column blocks
%   2) eig-decompose each mode block
%   3) clamp eigenvalues below psd_floor
%   4) inverse DFT back to first-column blocks
%
% Output:
%   mode_blocks_before / after
%   first_col_blocks_psd
%   lambda_mode_min_before / after

    if nargin < 2
        cfg = default_params();
    end
    cfg = stage10B1_prepare_cfg(cfg);

    [n1, n2, P] = size(first_col_blocks);
    if n1 ~= 3 || n2 ~= 3
        error('Expected 3x3 first-column blocks.');
    end

    mode_blocks_before = zeros(n1, n2, P);
    mode_blocks_after = zeros(n1, n2, P);
    lambda_mode_min_before = nan(P,1);
    lambda_mode_min_after = nan(P,1);

    for k = 1:P
        Ak = zeros(n1, n2);
        for ell = 1:P
            omega = exp(-1i * 2*pi*(k-1)*(ell-1)/P);
            Ak = Ak + first_col_blocks(:,:,ell) * omega;
        end
        Ak = real(Ak);
        Ak = 0.5 * (Ak + Ak.');

        ev_before = sort(real(eig(Ak)), 'ascend');
        lambda_mode_min_before(k) = ev_before(1);
        mode_blocks_before(:,:,k) = Ak;

        if cfg.stage10B1.do_psd_projection
            [V, D] = eig(Ak);
            d = real(diag(D));
            d = max(d, cfg.stage10B1.psd_floor);
            Ak_psd = V * diag(d) * V';
            Ak_psd = real(Ak_psd);
            Ak_psd = 0.5 * (Ak_psd + Ak_psd.');
        else
            Ak_psd = Ak;
        end

        ev_after = sort(real(eig(Ak_psd)), 'ascend');
        lambda_mode_min_after(k) = ev_after(1);
        mode_blocks_after(:,:,k) = Ak_psd;
    end

    first_col_blocks_psd = rebuild_firstcol_from_mode_blocks_stage10B1(mode_blocks_after, cfg);

    out = struct();
    out.mode_blocks_before = mode_blocks_before;
    out.mode_blocks_after = mode_blocks_after;
    out.lambda_mode_min_before = lambda_mode_min_before;
    out.lambda_mode_min_after = lambda_mode_min_after;
    out.first_col_blocks_psd = first_col_blocks_psd;
end