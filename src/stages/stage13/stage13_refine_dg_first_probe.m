function refine_out = stage13_refine_dg_first_probe(cfg, stage13_out)
%STAGE13_REFINE_DG_FIRST_PROBE Optional Stage13.6 refined-search entry.

cfg = stage13_default_config(cfg);

refine_out = struct();
refine_out.enabled = logical(cfg.stage13.dg_refine.enable);
refine_out.seed_case = string(cfg.stage13.dg_refine.seed_case);
refine_out.status = "disabled";
refine_out.plan = table();
refine_out.summary = table();
refine_out.recommended_case = "";
refine_out.figures = struct();

if ~refine_out.enabled
    return;
end

refine_out.status = "pending";
if nargin >= 2 && isstruct(stage13_out)
    refine_out.source_summary = stage13_out.summary;
end
end
