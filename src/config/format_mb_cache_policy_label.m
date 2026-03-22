function label = format_mb_cache_policy_label(cache_policy_in, cache_profile_in, detail_level)
%FORMAT_MB_CACHE_POLICY_LABEL Human-readable MB cache policy summary.

if nargin < 1 || isempty(cache_policy_in)
    cache_policy_in = "all_reuse";
end
if nargin < 2 || isempty(cache_profile_in)
    cache_profile_in = struct();
end
if nargin < 3 || strlength(string(detail_level)) == 0
    detail_level = "short";
end

cache_policy = lower(string(cache_policy_in));
strict_label = local_onoff(local_getfield_or(cache_profile_in, 'strict_compatibility', true));
truth_label = local_onoff(local_getfield_or(cache_profile_in, 'reuse_truth', true));
semantic_label = local_onoff(local_getfield_or(cache_profile_in, 'reuse_semantic_eval', true));
plotting_label = local_onoff(local_getfield_or(cache_profile_in, 'reuse_plotting', true));
tune_label = local_onoff(local_getfield_or(cache_profile_in, 'reuse_tune_cache', true));

switch cache_policy
    case "all_reuse"
        policy_text = "all_reuse";
        policy_detail = "reuse truth + semantic + plotting caches whenever manifests stay compatible";
    case "truth_only"
        policy_text = "truth_only";
        policy_detail = "reuse truth cache only; semantic cache miss forces fresh semantic evaluation";
    case "no_reuse"
        policy_text = "no_reuse";
        policy_detail = "disable MB cache reuse for this run";
    case "force_fresh"
        policy_text = "force_fresh";
        policy_detail = "force fresh semantic recompute and full export regeneration while allowing only static truth reuse";
    otherwise
        policy_text = cache_policy;
        policy_detail = "custom cache policy";
end

if strcmpi(char(string(detail_level)), 'detailed')
    parts = [
        policy_text + " (" + policy_detail + ")"
        "strict_compat=" + strict_label
        "truth=" + truth_label
        "semantic=" + semantic_label
        "plot=" + plotting_label
        "tune=" + tune_label];
else
    parts = [
        policy_text
        "strict_compat=" + strict_label];
end

label = strjoin(cellstr(parts), ', ');
end

function txt = local_onoff(flag)
if logical(flag)
    txt = "on";
else
    txt = "off";
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
