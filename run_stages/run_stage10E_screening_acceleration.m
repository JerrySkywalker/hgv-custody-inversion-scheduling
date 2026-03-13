function out = run_stage10E_screening_acceleration(cfg, interactive, opts)
%RUN_STAGE10E_SCREENING_ACCELERATION
% Standalone entry for Stage10.E.
%
% Suggested usage:
%   outE = run_stage10E_screening_acceleration(cfg, false);

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
        fprintf('[run_stages] Stage10.E currently recommends non-interactive usage.\n');
        fprintf('[run_stages] Proceeding with provided/default cfg.\n');
    end

    cfg = stage10E_prepare_cfg(cfg);

    fprintf('[run_stages] === Stage10.E screening benchmark ===\n');
    fprintf('[run_stages] case_index       : %d\n', cfg.stage10E.case_index);
    fprintf('[run_stages] window_index     : %d\n', cfg.stage10E.window_index);
    fprintf('[run_stages] theta_source     : %s\n', cfg.stage10E.theta_source);
    fprintf('[run_stages] prototype_source : %s\n', cfg.stage10E.prototype_source);
    fprintf('[run_stages] two_stage_rule   : %s\n', cfg.stage10E.two_stage_rule);
    fprintf('[run_stages] run_tag          : %s\n', cfg.stage10E.run_tag);

    out = stage10E_screening_acceleration(cfg);

    fprintf('[run_stages] === Stage10.E 完成 ===\n');
end