function out = run_stage10_fft_validation(cfg, interactive, opts)
%RUN_STAGE10_FFT_VALIDATION
% One-click entry for Stage10 FFT validation.
%
% Usage:
%   run_stage10_fft_validation()
%   run_stage10_fft_validation(cfg)
%   run_stage10_fft_validation(cfg, false)
%   run_stage10_fft_validation(cfg, true, opts)

    if nargin < 1
        cfg = [];
    end
    if nargin < 2
        interactive = (nargin == 0);
    end
    if nargin < 3
        opts = struct();
    end

    fprintf('[run_stages] === Stage10 FFT validation entry ===\n');

    out = struct();

    if isempty(cfg)
        cfg = default_params();
    end
    [cfg, opts] = rs_cli_configure('stage10', cfg, interactive, opts);

    cfg = stage10_prepare_cfg(cfg);

    switch lower(string(cfg.stage10.mode))
        case "single_window_debug"
            out.out10_1 = stage10_validate_single_window_fft(cfg);
        otherwise
            error('Stage10 mode not implemented yet: %s', string(cfg.stage10.mode));
    end

    fprintf('[run_stages] === Stage10 完成 ===\n');
end