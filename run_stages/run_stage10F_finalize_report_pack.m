function out = run_stage10F_finalize_report_pack(cfg, interactive, opts)
%RUN_STAGE10F_FINALIZE_REPORT_PACK
% Standalone entry for Stage10.F.
%
% Suggested usage:
%   outF = run_stage10F_finalize_report_pack(cfg, false);

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
        fprintf('[run_stages] Stage10.F currently recommends non-interactive usage.\n');
        fprintf('[run_stages] Proceeding with provided/default cfg.\n');
    end

    cfg = stage10F_prepare_cfg(cfg);

    fprintf('[run_stages] === Stage10.F final report pack ===\n');
    fprintf('[run_stages] case_index       : %d\n', cfg.stage10F.case_index);
    fprintf('[run_stages] window_index     : %d\n', cfg.stage10F.window_index);
    fprintf('[run_stages] prototype_source : %s\n', cfg.stage10F.prototype_source);
    fprintf('[run_stages] run_tag          : %s\n', cfg.stage10F.run_tag);

    out = stage10F_finalize_report_pack(cfg);

    fprintf('[run_stages] === Stage10.F 完成 ===\n');
end