function guard = guard_mb_paper_ready_export(figure_family, diagnostics, options)
%GUARD_MB_PAPER_READY_EXPORT Decide whether a paper-ready MB export is allowed.

if nargin < 2 || isempty(diagnostics)
    diagnostics = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

family_name = lower(strtrim(char(string(figure_family))));
max_boundary_hit_ratio = local_getfield_or(options, 'max_boundary_hit_ratio', 0.25);
require_right_unity = logical(local_getfield_or(options, 'require_right_unity', true));
require_internal_frontier = logical(local_getfield_or(options, 'require_internal_frontier', true));

boundary_table = local_getfield_or(diagnostics, 'boundary_hit_table', table());
passratio_table = local_getfield_or(diagnostics, 'passratio_saturation_table', table());
frontier_table = local_getfield_or(diagnostics, 'frontier_truncation_table', table());

guard = struct( ...
    'figure_family', string(figure_family), ...
    'allowed', true, ...
    'status', "allowed", ...
    'reason', "guard_passed", ...
    'note', "", ...
    'boundary_dominated', false, ...
    'right_unity_reached', true, ...
    'frontier_truncated', false, ...
    'frontier_weakly_defined', false);

if istable(boundary_table) && ~isempty(boundary_table)
    boundary_dominated = any(logical(local_table_column(boundary_table, 'is_boundary_dominated')));
    upper_hit = local_table_column(boundary_table, 'ratio_upper_bound_hit');
    upper_hit = upper_hit(isfinite(upper_hit));
    if isempty(upper_hit)
        upper_hit_ratio = 0;
    else
        upper_hit_ratio = max(upper_hit);
    end
    guard.boundary_dominated = boundary_dominated || upper_hit_ratio > max_boundary_hit_ratio;
end

if istable(passratio_table) && ~isempty(passratio_table)
    unity_flags = logical(local_table_column(passratio_table, 'right_unity_reached'));
    if isempty(unity_flags)
        guard.right_unity_reached = false;
    else
        guard.right_unity_reached = all(unity_flags);
    end
else
    guard.right_unity_reached = false;
end

if istable(frontier_table) && ~isempty(frontier_table)
    guard.frontier_truncated = any(logical(local_table_column(frontier_table, 'frontier_truncated_by_upper_bound')));
    guard.frontier_weakly_defined = any(logical(local_table_column(frontier_table, 'frontier_weakly_defined')));
end

if contains(family_name, 'heatmap')
    if guard.boundary_dominated
        guard = local_block(guard, "blocked_boundary_dominated", "Paper-ready heatmap export refused because the current minimum-N_s map is still boundary dominated.");
        return;
    end
end

if contains(family_name, 'passratio') || contains(family_name, 'overlay') || contains(family_name, 'dg_envelope')
    if require_right_unity && ~guard.right_unity_reached
        guard = local_block(guard, "blocked_unity_plateau_not_reached", "Paper-ready pass-ratio style export refused because the unity plateau is not reached within the current search domain.");
        return;
    end
    if guard.boundary_dominated
        guard = local_block(guard, "blocked_boundary_dominated", "Paper-ready pass-ratio style export refused because the result is still boundary dominated.");
        return;
    end
end

if contains(family_name, 'frontier')
    if require_internal_frontier && guard.frontier_truncated
        guard = local_block(guard, "blocked_frontier_truncated", "Paper-ready frontier export refused because the frontier is still truncated by the current search upper bound.");
        return;
    end
    if require_internal_frontier && guard.frontier_weakly_defined
        guard = local_block(guard, "blocked_frontier_weakly_defined", "Paper-ready frontier export refused because the frontier is only weakly defined.");
        return;
    end
end

if contains(family_name, 'comparison')
    if guard.boundary_dominated
        guard = local_block(guard, "blocked_boundary_dominated", "Paper-ready comparison export refused because at least one contributing result is still boundary dominated.");
        return;
    end
    if require_right_unity && ~guard.right_unity_reached
        guard = local_block(guard, "blocked_unity_plateau_not_reached", "Paper-ready comparison export refused because at least one semantic branch has not reached its unity plateau.");
        return;
    end
end

guard.note = "paper-ready export allowed";
end

function guard = local_block(guard, status_name, note_text)
guard.allowed = false;
guard.status = string(status_name);
guard.reason = string(status_name);
guard.note = string(note_text);
end

function values = local_table_column(T, field_name)
if istable(T) && ismember(field_name, T.Properties.VariableNames)
    values = T.(field_name);
else
    values = [];
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
