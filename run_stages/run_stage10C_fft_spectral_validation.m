function out = run_stage10C_fft_spectral_validation(cfg, interactive, opts)
%RUN_STAGE10C_FFT_SPECTRAL_VALIDATION
% Standalone entry for Stage10.C.
%
% Suggested usage:
%   outC = run_stage10C_fft_spectral_validation(cfg, false);

    if nargin < 1
        cfg = [];
    end
    if nargin < 2
        interactive = false;
    end
    if nargin < 3
        opts = struct();
    end

    startup();

    if isempty(cfg)
        cfg = default_params();
    end

    if interactive
        fprintf('[run_stages] Stage10.C currently recommends non-interactive usage.\n');
        fprintf('[run_stages] Proceeding with provided/default cfg.\n');
    end

    cfg = stage10C_prepare_cfg(cfg);

    fprintf('[run_stages] === Stage10.C FFT spectral validation ===\n');
    fprintf('[run_stages] case_index       : %d\n', cfg.stage10C.case_index);
    fprintf('[run_stages] window_index     : %d\n', cfg.stage10C.window_index);
    fprintf('[run_stages] theta_source     : %s\n', cfg.stage10C.theta_source);
    fprintf('[run_stages] prototype_source : %s\n', cfg.stage10C.prototype_source);
    fprintf('[run_stages] mode_order       : %s\n', cfg.stage10C.mode_order);
    fprintf('[run_stages] run_tag          : %s\n', cfg.stage10C.run_tag);

    out = stage10C_fft_spectral_validation(cfg);

    fprintf('[run_stages] === Stage10.C 完成 ===\n');
end