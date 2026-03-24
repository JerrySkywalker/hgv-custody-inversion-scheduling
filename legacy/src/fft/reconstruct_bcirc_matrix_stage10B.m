function Wbcirc = reconstruct_bcirc_matrix_stage10B(first_col_blocks, cfg)
%RECONSTRUCT_BCIRC_MATRIX_STAGE10B
% Reconstruct the full block-circulant matrix from first-column blocks.
%
% If first_col_blocks(:,:,1:P) = [B0, B1, ..., B_{P-1}],
% then the (i,j)-th block of the bcirc matrix is:
%   B_{mod(i-j, P)}
%
% Output:
%   Wbcirc : (3P) x (3P)

    if nargin < 2
        cfg = default_params();
    end
    cfg = stage10B_prepare_cfg(cfg);

    [n1, n2, P] = size(first_col_blocks);
    if n1 ~= 3 || n2 ~= 3
        error('Stage10.B expects 3x3 first-column blocks.');
    end

    Wbcirc = zeros(3*P, 3*P);

    for i = 1:P
        for j = 1:P
            lag = mod(i - j, P) + 1;  % 1-based index
            block_ij = first_col_blocks(:,:,lag);

            row_idx = (3*(i-1)+1):(3*i);
            col_idx = (3*(j-1)+1):(3*j);
            Wbcirc(row_idx, col_idx) = block_ij;
        end
    end

    if cfg.stage10B.force_symmetric
        Wbcirc = 0.5 * (Wbcirc + Wbcirc.');
    end
end