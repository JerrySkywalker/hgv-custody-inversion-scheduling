function out = run_stage14_openD(cfg, interactive, opts)
%RUN_STAGE14_OPEND
% One-click entry for Stage14.1 mainline:
%   raw DG-only RAAN-expanded scan over (i,P,T,RAAN) with fixed F_ref.

    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root), addpath(proj_root); end
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

    % For now, keep minimal and non-interactive in practice
    if interactive
        fprintf('[run_stages] Stage14.1 mainline currently runs with provided/default config directly.\n');
    end

    fprintf('[run_stages] === Stage14.1 mainline: openD raw RAAN scan ===\n');
    out.out1 = stage14_scan_openD_raan_grid(cfg, opts);
    fprintf('[run_stages] Stage14.1 mainline completed.\n');
end
