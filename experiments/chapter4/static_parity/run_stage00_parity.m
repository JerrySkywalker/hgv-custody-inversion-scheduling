function out = run_stage00_parity(profile)
%RUN_STAGE00_PARITY Minimal Stage00 parity entry for the rewritten framework.
%   out = RUN_STAGE00_PARITY()
%   out = RUN_STAGE00_PARITY(profile)

if nargin < 1 || isempty(profile)
    profile = struct();
end

cfg = build_run_config(profile);
paths = build_output_paths(cfg);
manifest = build_runtime_manifest(cfg);

out = struct();
out.status = 'PASS';
out.stage_id = char(cfg.meta.stage_id);
out.profile = profile;
out.cfg = cfg;
out.paths = paths;
out.manifest = manifest;
end
