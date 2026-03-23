function [replay_table, replay_meta] = rebuild_mb_passratio_global_replay_table(source_table, search_domain, options)
%REBUILD_MB_PASSRATIO_GLOBAL_REPLAY_TABLE Build a global full replay table on the configured Ns grid.

if nargin < 2 || isempty(search_domain)
    search_domain = struct();
end
if nargin < 3 || isempty(options)
    options = struct();
end

ns_field = char(string(local_getfield_or(options, 'ns_field', 'Ns')));
grid_options = struct( ...
    'initial_ns_min', local_getfield_or(options, 'initial_ns_min', NaN), ...
    'final_ns_max', local_getfield_or(options, 'final_ns_max', NaN), ...
    'ns_step', local_getfield_or(options, 'ns_step', NaN), ...
    'origin_mode', string(local_getfield_or(options, 'origin_mode', "initial_ns_min")));
[target_ns_grid, grid_meta] = build_mb_global_full_dense_ns_grid(search_domain, source_table, ns_field, grid_options);

rebuild_options = options;
rebuild_options.target_ns_grid = target_ns_grid;
rebuild_options.rebuild_scope = 'global_full';
rebuild_options.initial_ns_min = grid_meta.initial_ns_min;
rebuild_options.final_ns_max = grid_meta.final_ns_max;
rebuild_options.ns_step = grid_meta.ns_step;

[replay_table, replay_meta] = rebuild_mb_passratio_dense_view_table(source_table, search_domain, rebuild_options);
if ~isempty(replay_table)
    replay_table.is_replayed(:) = true;
end
replay_meta.view_name = "globalFullReplay";
replay_meta.domain_view = "global_full_replay";
replay_meta.global_grid_min_ns = double(local_getfield_or(grid_meta, 'initial_ns_min', NaN));
replay_meta.global_grid_max_ns = double(local_getfield_or(grid_meta, 'final_ns_max', NaN));
replay_meta.global_grid_step = double(local_getfield_or(grid_meta, 'ns_step', NaN));
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
