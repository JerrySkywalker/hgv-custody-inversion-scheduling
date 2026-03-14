function out = run_stage11(cfg, interactive, opts)
%RUN_STAGE11 Official public entry for Stage11.

    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root)
        addpath(proj_root);
        addpath(fullfile(proj_root, 'run_stages'));
    end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(interactive)
        interactive = (nargin == 0);
    end
    if nargin < 3 || isempty(opts)
        opts = struct();
    end

    [cfg, opts] = rs_cli_configure('stage11', cfg, interactive, opts);
    [cfg, ~] = rs_apply_parallel_policy('stage11', cfg, opts);
    cfg = stage11_prepare_cfg(cfg);

    fprintf('[run_stages] === Stage11 总入口 ===\n');
    fprintf('[run_stages] entry         : %s\n', cfg.stage11.entry);
    fprintf('[run_stages] source stage10 : %s\n', cfg.stage11.source_stage10_entry);
    fprintf('[run_stages] partition     : %s\n', cfg.stage11.partition_mode);

    out = stage11_entry(cfg);

    fprintf('[run_stages] === Stage11 完成 ===\n');
end
