function label = format_mb_incremental_policy_label(meta_or_domain, detail_level)
%FORMAT_MB_INCREMENTAL_POLICY_LABEL Human-readable MB incremental-expansion summary.

if nargin < 1 || isempty(meta_or_domain)
    meta_or_domain = struct();
end
if nargin < 2 || strlength(string(detail_level)) == 0
    detail_level = "short";
end

policy_name = string(local_getfield_or(meta_or_domain, 'search_domain_policy', ...
    local_getfield_or(meta_or_domain, 'policy_name', "profile_default")));
enabled = logical(local_getfield_or(meta_or_domain, 'incremental_expansion_enabled', ...
    local_getfield_or(meta_or_domain, 'allow_auto_expand_upper', false)));
strict_lock = logical(local_getfield_or(meta_or_domain, 'strict_stage05_reference', false));
max_iter = local_getfield_or(meta_or_domain, 'max_expand_iterations', ...
    local_getfield_or(local_getfield_or(meta_or_domain, 'auto_tune', struct()), 'max_iterations', NaN));
step_P = local_getfield_or(meta_or_domain, 'expand_step_P', ...
    local_getfield_or(local_getfield_or(meta_or_domain, 'auto_tune', struct()), 'expand_step_P', NaN));
step_T = local_getfield_or(meta_or_domain, 'expand_step_T', ...
    local_getfield_or(local_getfield_or(meta_or_domain, 'auto_tune', struct()), 'expand_step_T', NaN));

if strict_lock
    label = "strict_stage05_reference (incremental expansion locked off)";
    return;
end

if strcmpi(char(string(detail_level)), 'detailed')
    if enabled
        label = sprintf('%s (enabled, dP=%g, dT=%g, max_iter=%g)', ...
            char(policy_name), step_P, step_T, max_iter);
    else
        label = sprintf('%s (incremental expansion off)', char(policy_name));
    end
else
    if enabled
        label = policy_name + " (enabled)";
    else
        label = policy_name + " (off)";
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
