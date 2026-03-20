function plot_domain = resolve_mb_plot_domain_for_context(context, cfg, profile, search_domain)
%RESOLVE_MB_PLOT_DOMAIN_FOR_CONTEXT Resolve the runtime MB plot domain for a context.

if nargin < 1 || isempty(context)
    context = struct();
end
if nargin < 2
    cfg = [];
end
if nargin < 3 || isempty(profile)
    profile = [];
end
if nargin < 4 || isempty(search_domain)
    search_domain = [];
end

if isempty(profile)
    profile_name = local_getfield_or(context, 'user_selected_profile_name', 'mb_default');
    profile = resolve_mb_search_profile(profile_name, cfg);
end
if isempty(search_domain)
    search_domain = resolve_mb_search_domain_for_context(context, cfg, profile);
end

strict_lock = logical(local_getfield_or(local_getfield_or(profile, 'stage05_replica', struct()), 'strict', false));
plot_domain = struct();
plot_domain.profile_name = string(local_getfield_or(profile, 'name', "mb_default"));
plot_domain.profile_mode = string(local_getfield_or(profile, 'profile_mode', "debug"));
plot_domain.semantic_mode = string(local_getfield_or(profile, 'semantic_mode', ""));
plot_domain.figure_family = string(local_getfield_or(context, 'figure_family', ""));
plot_domain.plot_xlim_mode = string(local_getfield_or(context, 'plot_domain_policy', ""));
plot_domain.plot_xlim_ns = reshape(local_getfield_or(profile, 'Ns_xlim_plot', local_getfield_or(profile, 'plot_xlim_ns', [])), 1, []);
plot_domain.plot_ylim_passratio = reshape(local_getfield_or(profile, 'plot_ylim_passratio', [0, 1.05]), 1, []);
plot_domain.plot_ylim_dg = reshape(local_getfield_or(profile, 'plot_ylim_dg', []), 1, []);
plot_domain.plot_domain_guardrail_mode = string(local_getfield_or(profile, 'plot_domain_guardrail_mode', "standard"));
plot_domain.show_domain_annotation = logical(local_getfield_or(profile, 'show_domain_annotation', true));
plot_domain.strict_stage05_reference = strict_lock;

profile_plot_domain = local_getfield_or(profile, 'plot_domain', struct());
if isstruct(profile_plot_domain) && ~isempty(fieldnames(profile_plot_domain))
    plot_domain = milestone_common_merge_structs(plot_domain, profile_plot_domain);
end

context_override = local_getfield_or(context, 'plot_domain_override', struct());
if isstruct(context_override) && ~isempty(fieldnames(context_override))
    plot_domain = milestone_common_merge_structs(plot_domain, context_override);
end

plot_domain = local_normalize_plot_domain(plot_domain, search_domain, strict_lock);
plot_domain.summary_short = format_mb_plot_domain_label(plot_domain, "short");
plot_domain.summary_detailed = format_mb_plot_domain_label(plot_domain, "detailed");
plot_domain.metadata = struct( ...
    'resolver', "resolve_mb_plot_domain_for_context", ...
    'profile_name', string(plot_domain.profile_name), ...
    'profile_mode', string(plot_domain.profile_mode), ...
    'strict_stage05_reference', logical(plot_domain.strict_stage05_reference), ...
    'context', context);
end

function plot_domain = local_normalize_plot_domain(plot_domain, search_domain, strict_lock)
plot_domain.plot_xlim_ns = reshape(local_getfield_or(plot_domain, 'plot_xlim_ns', []), 1, []);
plot_domain.plot_ylim_passratio = reshape(local_getfield_or(plot_domain, 'plot_ylim_passratio', [0, 1.05]), 1, []);
plot_domain.plot_ylim_dg = reshape(local_getfield_or(plot_domain, 'plot_ylim_dg', []), 1, []);
plot_domain.plot_domain_guardrail_mode = string(local_getfield_or(plot_domain, 'plot_domain_guardrail_mode', "standard"));
plot_domain.show_domain_annotation = logical(local_getfield_or(plot_domain, 'show_domain_annotation', true));

mode_token = strtrim(char(string(local_getfield_or(plot_domain, 'plot_xlim_mode', ""))));
if isempty(mode_token) || (strcmpi(mode_token, 'data_range') && strict_lock)
    if strict_lock
        mode_token = 'strict_stage05_reference';
    else
        mode_token = 'data_range';
    end
end
if strcmpi(mode_token, 'data_range') && ~isempty(plot_domain.plot_xlim_ns)
    if strict_lock
        mode_token = 'strict_stage05_reference';
    else
        mode_token = 'search_profile';
    end
end
plot_domain.plot_xlim_mode = string(mode_token);

if isempty(plot_domain.plot_xlim_ns)
    switch lower(mode_token)
        case {'search_profile', 'strict_stage05_reference'}
            plot_domain.plot_xlim_ns = [search_domain.ns_search_min, search_domain.ns_search_max];
        otherwise
            plot_domain.plot_xlim_ns = [];
    end
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
