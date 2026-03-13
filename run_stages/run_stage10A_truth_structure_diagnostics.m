function out = run_stage10A_truth_structure_diagnostics(cfg, interactive, opts)
%RUN_STAGE10A_TRUTH_STRUCTURE_DIAGNOSTICS
% Standalone entry for Stage10.A.
%
% Suggested usage:
%   outA = run_stage10A_truth_structure_diagnostics(cfg, false);

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

    % Stage10.A is intentionally kept standalone for now.
    % We do not bind it to rs_cli_configure yet.
    if interactive
        fprintf('[run_stages] Stage10.A currently recommends non-interactive usage.\n');
        fprintf('[run_stages] Proceeding with provided/default cfg.\n');
    end

    cfg = stage10A_prepare_cfg(cfg);

    fprintf('[run_stages] === Stage10.A truth structure diagnostics ===\n');
    fprintf('[run_stages] case_index   : %d\n', cfg.stage10A.case_index);
    fprintf('[run_stages] window_index : %d\n', cfg.stage10A.window_index);
    fprintf('[run_stages] theta_source : %s\n', cfg.stage10A.theta_source);
    fprintf('[run_stages] run_tag      : %s\n', cfg.stage10A.run_tag);

    out = stage10A_truth_structure_diagnostics(cfg);

    fprintf('[run_stages] === Stage10.A 完成 ===\n');
end