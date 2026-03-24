function out = symmetrize_firstcol_bcirc_stage10B1(first_col_blocks, cfg)
%SYMMETRIZE_FIRSTCOL_BCIRC_STAGE10B1
% Enforce compatibility conditions for a real symmetric block-circulant matrix.
%
% For a real symmetric bcirc matrix with symmetric 3x3 blocks:
%   B_ell = B_{P-ell}   (in 0-based lag indexing)
%
% Input:
%   first_col_blocks(:,:,1:P) with 1-based indexing corresponding to lag 0..P-1
%
% Output:
%   sym_first_col_blocks
%   mirror_gap_before / after

    if nargin < 2
        cfg = default_params();
    end
    cfg = stage10B1_prepare_cfg(cfg);

    [n1, n2, P] = size(first_col_blocks);
    if n1 ~= 3 || n2 ~= 3
        error('Expected 3x3 first-column blocks.');
    end

    B = first_col_blocks;

    % block-wise symmetry first
    if cfg.stage10B1.force_block_symmetry
        for ell = 1:P
            B(:,:,ell) = 0.5 * (B(:,:,ell) + B(:,:,ell).');
        end
    end

    gap_before_sq = 0;
    for ell = 2:P
        ell_m = P - (ell - 1) + 1;
        if ell <= ell_m
            D = B(:,:,ell) - B(:,:,ell_m);
            gap_before_sq = gap_before_sq + norm(D, 'fro')^2;
        end
    end
    mirror_gap_before = sqrt(gap_before_sq);

    Bsym = B;
    if cfg.stage10B1.do_mirror_symmetrization
        for ell = 2:P
            ell_m = P - (ell - 1) + 1;
            if ell < ell_m
                Bavg = 0.5 * (B(:,:,ell) + B(:,:,ell_m));
                Bsym(:,:,ell) = Bavg;
                Bsym(:,:,ell_m) = Bavg;
            end
        end
        % ell = 1 (lag 0) remains itself
        % if P even, lag P/2 block also remains after averaging with itself automatically
    end

    gap_after_sq = 0;
    for ell = 2:P
        ell_m = P - (ell - 1) + 1;
        if ell <= ell_m
            D = Bsym(:,:,ell) - Bsym(:,:,ell_m);
            gap_after_sq = gap_after_sq + norm(D, 'fro')^2;
        end
    end
    mirror_gap_after = sqrt(gap_after_sq);

    out = struct();
    out.first_col_blocks_in = first_col_blocks;
    out.first_col_blocks_sym = Bsym;
    out.mirror_gap_before = mirror_gap_before;
    out.mirror_gap_after = mirror_gap_after;
end