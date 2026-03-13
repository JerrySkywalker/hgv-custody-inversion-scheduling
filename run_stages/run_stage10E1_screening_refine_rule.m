function out = run_stage10E1_screening_refine_rule(cfg, interactive, opts)
%RUN_STAGE10E1_SCREENING_REFINE_RULE
% Standalone entry for Stage10.E.1.
%
% Suggested usage:
%   outE1 = run_stage10E1_screening_refine_rule(cfg, false);

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
        fprintf('[run_stages] Stage10.E.1 currently recommends non-interactive usage.\n');
        fprintf('[run_stages] Proceeding with provided/default cfg.\n');
    end

    cfg = stage10E1_prepare_cfg(cfg);

    fprintf('[run_stages] === Stage10.E.1 refined screening rule ===\n');
    fprintf('[run_stages] case_index       : %d\n', cfg.stage10E1.case_index);
    fprintf('[run_stages] window_index     : %d\n', cfg.stage10E1.window_index);
    fprintf('[run_stages] prototype_source : %s\n', cfg.stage10E1.prototype_source);
    fprintf('[run_stages] run_tag          : %s\n', cfg.stage10E1.run_tag);

    out = stage10E1_screening_refine_rule(cfg);

    fprintf('[run_stages] === Stage10.E.1 完成 ===\n');
end