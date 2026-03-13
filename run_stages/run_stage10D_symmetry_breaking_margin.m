function out = run_stage10D_symmetry_breaking_margin(cfg, interactive, opts)
%RUN_STAGE10D_SYMMETRY_BREAKING_MARGIN
% Standalone entry for Stage10.D.
%
% Suggested usage:
%   outD = run_stage10D_symmetry_breaking_margin(cfg, false);

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
        fprintf('[run_stages] Stage10.D currently recommends non-interactive usage.\n');
        fprintf('[run_stages] Proceeding with provided/default cfg.\n');
    end

    cfg = stage10D_prepare_cfg(cfg);

    fprintf('[run_stages] === Stage10.D symmetry-breaking margin ===\n');
    fprintf('[run_stages] case_index       : %d\n', cfg.stage10D.case_index);
    fprintf('[run_stages] window_index     : %d\n', cfg.stage10D.window_index);
    fprintf('[run_stages] theta_source     : %s\n', cfg.stage10D.theta_source);
    fprintf('[run_stages] prototype_source : %s\n', cfg.stage10D.prototype_source);
    fprintf('[run_stages] eps_norm_mode    : %s\n', string(cfg.stage10D.eps_norm_mode));
    fprintf('[run_stages] run_tag          : %s\n', cfg.stage10D.run_tag);

    out = stage10D_symmetry_breaking_margin(cfg);

    fprintf('[run_stages] === Stage10.D 完成 ===\n');
end