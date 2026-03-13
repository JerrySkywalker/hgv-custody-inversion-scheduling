function out = bcirc_fft_minEig_stage10(first_col_blocks, cfg)
%BCIRC_FFT_MINEIG_STAGE10 FFT-based eigen analysis for block-circulant proxy.
%
% Input:
%   first_col_blocks : n x n x P block first column
%
% Output:
%   lambda_mode_min  : minimum eigenvalue across all Fourier modes
%   lambda_zero_mode : minimum eigenvalue of the zero Fourier mode
%
% For Stage10.1 the first-column usually contains only the zero-lag block,
% but the implementation already supports generic lag stacks.

    if nargin < 2
        cfg = default_params();
    end
    cfg = stage10_prepare_cfg(cfg);

    validateattributes(first_col_blocks, {'numeric'}, {'3d','real','finite'});
    [n1, n2, P] = size(first_col_blocks);
    if n1 ~= n2
        error('first_col_blocks must be square in the first two dimensions.');
    end

    mode_blocks = zeros(n1, n2, P);
    lambda_mode_each = nan(P,1);
    eigvals_mode = cell(P,1);

    for k = 1:P
        Ak = zeros(n1,n2);
        for ell = 1:P
            omega = exp(-1i * 2*pi*(k-1)*(ell-1)/P);
            Ak = Ak + first_col_blocks(:,:,ell) * omega;
        end
        Ak = real(Ak);
        if cfg.stage10.force_symmetric
            Ak = 0.5 * (Ak + Ak.');
        end
        ev = sort(real(eig(Ak)), 'ascend');
        mode_blocks(:,:,k) = Ak;
        eigvals_mode{k} = ev;
        lambda_mode_each(k) = ev(1);
    end

    A0 = sum(first_col_blocks, 3);
    if cfg.stage10.force_symmetric
        A0 = 0.5 * (A0 + A0.');
    end
    eig_zero = sort(real(eig(A0)), 'ascend');

    out = struct();
    out.mode_blocks = mode_blocks;
    out.eigvals_mode = eigvals_mode;
    out.lambda_mode_each = lambda_mode_each;
    out.lambda_mode_min = min(lambda_mode_each);
    out.zero_mode_block = A0;
    out.eig_zero_mode = eig_zero;
    out.lambda_zero_mode = eig_zero(1);
end