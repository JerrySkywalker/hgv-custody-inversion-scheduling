function mode_pack = bcirc_fft_modes_stage10C(first_col_blocks, cfg)
%BCIRC_FFT_MODES_STAGE10C
% Build Fourier mode blocks from legal bcirc first-column blocks.
%
% Input:
%   first_col_blocks(:,:,ell), ell=1..P, corresponding to lag 0..P-1
%
% Output:
%   mode_blocks(:,:,k), k=1..P corresponding to mode 0..P-1

    if nargin < 2
        cfg = default_params();
    end
    cfg = stage10C_prepare_cfg(cfg);

    [n1, n2, P] = size(first_col_blocks);
    if n1 ~= 3 || n2 ~= 3
        error('Expected 3x3 first-column blocks.');
    end

    mode_blocks = zeros(n1, n2, P);

    for k = 1:P
        Ak = zeros(n1, n2);
        for ell = 1:P
            omega = exp(-1i * 2*pi*(k-1)*(ell-1)/P);
            Ak = Ak + first_col_blocks(:,:,ell) * omega;
        end
        Ak = real(Ak);
        Ak = 0.5 * (Ak + Ak.');
        mode_blocks(:,:,k) = Ak;
    end

    mode_pack = struct();
    mode_pack.P = P;
    mode_pack.mode_blocks = mode_blocks;
end