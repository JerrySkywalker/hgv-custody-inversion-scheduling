function spec = bcirc_fft_minEig_stage10C(first_col_blocks, cfg)
%BCIRC_FFT_MINEIG_STAGE10C
% Compute mode-wise spectral quantities for a legal bcirc baseline.
%
% Output fields:
%   mode_table
%   lambda_mode_min
%   lambda_min_fft
%   mode_argmin
%   lambda_zero_mode
%   mode_blocks

    if nargin < 2
        cfg = default_params();
    end
    cfg = stage10C_prepare_cfg(cfg);

    mode_pack = bcirc_fft_modes_stage10C(first_col_blocks, cfg);
    mode_blocks = mode_pack.mode_blocks;
    P = mode_pack.P;

    lambda_mode_min = zeros(P,1);
    lambda_mode_mid = zeros(P,1);
    lambda_mode_max = zeros(P,1);
    trace_mode = zeros(P,1);
    fro_mode = zeros(P,1);

    for k = 1:P
        Ak = mode_blocks(:,:,k);
        ev = sort(real(eig(Ak)), 'ascend');
        lambda_mode_min(k) = ev(1);
        lambda_mode_mid(k) = ev(2);
        lambda_mode_max(k) = ev(3);
        trace_mode(k) = trace(Ak);
        fro_mode(k) = norm(Ak, 'fro');
    end

    [lambda_min_fft, idx_argmin] = min(lambda_mode_min);

    mode_table = table( ...
        (0:P-1).', lambda_mode_min, lambda_mode_mid, lambda_mode_max, trace_mode, fro_mode, ...
        'VariableNames', {'mode_index','lambda_min','lambda_mid','lambda_max','trace_mode','fro_mode'});

    if strcmpi(cfg.stage10C.mode_order, 'sorted_by_lambda_min')
        mode_table = sortrows(mode_table, 'lambda_min', 'ascend');
    end

    spec = struct();
    spec.P = P;
    spec.mode_blocks = mode_blocks;
    spec.mode_table = mode_table;
    spec.lambda_mode_min = lambda_mode_min;
    spec.lambda_mode_mid = lambda_mode_mid;
    spec.lambda_mode_max = lambda_mode_max;
    spec.trace_mode = trace_mode;
    spec.fro_mode = fro_mode;
    spec.lambda_min_fft = lambda_min_fft;
    spec.mode_argmin = idx_argmin - 1;   % report in 0-based mode index
    spec.lambda_zero_mode = lambda_mode_min(1);
end