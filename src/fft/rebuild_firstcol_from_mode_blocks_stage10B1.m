function first_col_blocks = rebuild_firstcol_from_mode_blocks_stage10B1(mode_blocks, cfg)
%REBUILD_FIRSTCOL_FROM_MODE_BLOCKS_STAGE10B1
% Inverse DFT from mode blocks back to bcirc first-column blocks.
%
% mode_blocks(:,:,k), k=1..P correspond to Fourier modes 0..P-1.

    if nargin < 2
        cfg = default_params();
    end
    cfg = stage10B1_prepare_cfg(cfg);

    [n1, n2, P] = size(mode_blocks);
    first_col_blocks = zeros(n1, n2, P);

    for ell = 1:P
        Bell = zeros(n1, n2);
        for k = 1:P
            omega = exp(1i * 2*pi*(k-1)*(ell-1)/P);
            Bell = Bell + mode_blocks(:,:,k) * omega;
        end
        Bell = Bell / P;
        Bell = real(Bell);
        if cfg.stage10B1.force_block_symmetry
            Bell = 0.5 * (Bell + Bell.');
        end
        first_col_blocks(:,:,ell) = Bell;
    end
end