function cfg_out = apply_mb_plot_domain_to_cfg(cfg_in, plot_domain)
%APPLY_MB_PLOT_DOMAIN_TO_CFG Apply a resolved MB plot-domain struct to cfg.

if nargin < 1 || isempty(cfg_in)
    cfg_out = milestone_common_defaults();
else
    cfg_out = milestone_common_defaults(cfg_in);
end
if nargin < 2 || isempty(plot_domain)
    return;
end

meta = cfg_out.milestones.MB_semantic_compare;
meta.plot_domain = plot_domain;
meta.plot_domain_label = string(format_mb_plot_domain_label(plot_domain, "short"));
meta.plot_domain_detail = string(format_mb_plot_domain_label(plot_domain, "detailed"));
meta.plot_domain_policy = string(local_getfield_or(plot_domain, 'plot_xlim_mode', "data_range"));
meta.plot_xlim_ns = reshape(local_getfield_or(plot_domain, 'plot_xlim_ns', meta.plot_xlim_ns), 1, []);
meta.plot_ylim_passratio = reshape(local_getfield_or(plot_domain, 'plot_ylim_passratio', meta.plot_ylim_passratio), 1, []);
if isfield(plot_domain, 'plot_ylim_dg')
    meta.plot_ylim_dg = reshape(plot_domain.plot_ylim_dg, 1, []);
end
meta.plot_domain_guardrail_mode = string(local_getfield_or(plot_domain, 'plot_domain_guardrail_mode', "standard"));
meta.show_domain_annotation = logical(local_getfield_or(plot_domain, 'show_domain_annotation', true));
cfg_out.milestones.MB_semantic_compare = meta;
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
