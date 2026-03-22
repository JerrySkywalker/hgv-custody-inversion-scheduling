function runtime = get_plot_runtime_config(cfg_or_runtime)
%GET_PLOT_RUNTIME_CONFIG Resolve normalized plotting runtime settings.

defaults = struct( ...
    'mode', "headless", ...
    'default_visible', false, ...
    'close_after_save', true, ...
    'reuse_figures', false, ...
    'export_dpi', 200, ...
    'renderer', "auto");

runtime = defaults;

if nargin >= 1 && ~isempty(cfg_or_runtime)
    runtime = local_merge_runtime(runtime, cfg_or_runtime);
elseif isappdata(0, 'mb_plot_runtime_config')
    runtime = local_merge_runtime(runtime, getappdata(0, 'mb_plot_runtime_config'));
end

runtime.mode = string(lower(char(string(local_getfield_or(runtime, 'mode', "headless")))));
if ~ismember(runtime.mode, ["visible", "headless", "offscreen-safe"])
    runtime.mode = "headless";
end
runtime.default_visible = logical(local_getfield_or(runtime, 'default_visible', runtime.mode == "visible"));
runtime.close_after_save = logical(local_getfield_or(runtime, 'close_after_save', runtime.mode ~= "visible"));
runtime.reuse_figures = logical(local_getfield_or(runtime, 'reuse_figures', false));
runtime.export_dpi = max(72, double(local_getfield_or(runtime, 'export_dpi', 200)));
runtime.renderer = string(local_getfield_or(runtime, 'renderer', "auto"));
end

function runtime = local_merge_runtime(runtime, candidate)
if ~isstruct(candidate)
    return;
end
if isfield(candidate, 'runtime') && isstruct(candidate.runtime)
    if isfield(candidate.runtime, 'figure_visibility_mode')
        candidate.runtime.plotting = milestone_common_merge_structs( ...
            local_getfield_or(candidate.runtime, 'plotting', struct()), ...
            struct('mode', candidate.runtime.figure_visibility_mode));
    end
    candidate = candidate.runtime;
end
if isfield(candidate, 'figure_visibility_mode')
    candidate.plotting = milestone_common_merge_structs( ...
        local_getfield_or(candidate, 'plotting', struct()), ...
        struct('mode', candidate.figure_visibility_mode));
end
if isfield(candidate, 'plot_manager') && isstruct(candidate.plot_manager)
    plot_candidate = struct();
    plot_candidate.mode = local_bool_to_mode(local_getfield_or(candidate.plot_manager, 'visible', []));
    plot_candidate.close_after_save = local_getfield_or(candidate.plot_manager, 'close_after_export', []);
    plot_candidate.export_dpi = local_getfield_or(candidate.plot_manager, 'export_dpi', []);
    plot_candidate.renderer = local_getfield_or(candidate.plot_manager, 'default_renderer', []);
    candidate.plotting = milestone_common_merge_structs(local_getfield_or(candidate, 'plotting', struct()), plot_candidate);
end
if isfield(candidate, 'plotting') && isstruct(candidate.plotting)
    candidate = candidate.plotting;
end
runtime = milestone_common_merge_structs(runtime, candidate);
end

function value = local_getfield_or(s, field_name, default_value)
if isstruct(s) && isfield(s, field_name) && ~isempty(s.(field_name))
    value = s.(field_name);
else
    value = default_value;
end
end

function mode = local_bool_to_mode(value)
if isempty(value)
    mode = [];
elseif logical(value)
    mode = "visible";
else
    mode = "headless";
end
end
