function out = run_stage10B_build_bcirc_reference(cfg, interactive, opts)
%RUN_STAGE10B_BUILD_BCIRC_REFERENCE
% Standalone entry for Stage10.B.
%
% Suggested usage:
%   outB = run_stage10B_build_bcirc_reference(cfg, false);

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
        fprintf('[run_stages] Stage10.B currently recommends non-interactive usage.\n');
        fprintf('[run_stages] Proceeding with provided/default cfg.\n');
    end

    cfg = stage10B_prepare_cfg(cfg);

    fprintf('[run_stages] === Stage10.B bcirc reference construction ===\n');
    fprintf('[run_stages] case_index          : %d\n', cfg.stage10B.case_index);
    fprintf('[run_stages] window_index        : %d\n', cfg.stage10B.window_index);
    fprintf('[run_stages] theta_source        : %s\n', cfg.stage10B.theta_source);
    fprintf('[run_stages] firstcol_source     : %s\n', cfg.stage10B.bcirc_firstcol_source);
    fprintf('[run_stages] truth_reduced_source: %s\n', cfg.stage10B.truth_reduced_source);
    fprintf('[run_stages] run_tag             : %s\n', cfg.stage10B.run_tag);

    out = stage10B_build_bcirc_reference(cfg);

    fprintf('[run_stages] === Stage10.B 完成 ===\n');
end