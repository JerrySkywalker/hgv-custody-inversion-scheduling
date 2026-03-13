function out = run_stage10B1_legalize_bcirc_reference(cfg, interactive, opts)
%RUN_STAGE10B1_LEGALIZE_BCIRC_REFERENCE
% Standalone entry for Stage10.B.1.
%
% Suggested usage:
%   outB1 = run_stage10B1_legalize_bcirc_reference(cfg, false);

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
        fprintf('[run_stages] Stage10.B.1 currently recommends non-interactive usage.\n');
        fprintf('[run_stages] Proceeding with provided/default cfg.\n');
    end

    cfg = stage10B1_prepare_cfg(cfg);

    fprintf('[run_stages] === Stage10.B.1 bcirc legalization ===\n');
    fprintf('[run_stages] case_index       : %d\n', cfg.stage10B1.case_index);
    fprintf('[run_stages] window_index     : %d\n', cfg.stage10B1.window_index);
    fprintf('[run_stages] theta_source     : %s\n', cfg.stage10B1.theta_source);
    fprintf('[run_stages] prototype_source : %s\n', cfg.stage10B1.prototype_source);
    fprintf('[run_stages] mirror_sym       : %d\n', cfg.stage10B1.do_mirror_symmetrization);
    fprintf('[run_stages] psd_projection   : %d\n', cfg.stage10B1.do_psd_projection);
    fprintf('[run_stages] psd_floor        : %.6g\n', cfg.stage10B1.psd_floor);
    fprintf('[run_stages] run_tag          : %s\n', cfg.stage10B1.run_tag);

    out = stage10B1_legalize_bcirc_reference(cfg);

    fprintf('[run_stages] === Stage10.B.1 完成 ===\n');
end