function startup()
    %STARTUP Initialize project paths and outputs folders for Chapter 4 fresh-start project.

    root_dir = fileparts(mfilename('fullpath'));
    path_state = project_path_manager('init', root_dir);
    local_bootstrap_outputs(root_dir);

    fprintf('[startup] Project root: %s\n', root_dir);
    fprintf('[startup] Path init: %s (%d entries, %.3f s)\n', ...
        char(string(path_state.status)), ...
        double(local_getfield_or(path_state, 'path_count', 0)), ...
        double(local_getfield_or(path_state, 'elapsed_s', NaN)));

    % ---------------------------
    % Global graphics defaults
    % Use plain text by default; enable LaTeX only where explicitly requested.
    % ---------------------------
    set(groot, 'defaultTextInterpreter', 'none');
    set(groot, 'defaultLegendInterpreter', 'none');
    set(groot, 'defaultAxesTickLabelInterpreter', 'none');
    if isappdata(0, 'mb_plot_runtime_config')
        apply_plot_runtime_config(getappdata(0, 'mb_plot_runtime_config'));
    else
        apply_plot_runtime_config(struct('plotting', struct('mode', 'headless')));
    end
end

function local_bootstrap_outputs(root_dir)
outputs_root = fullfile(root_dir, 'outputs');
ensure_dir(outputs_root);
ensure_dir(fullfile(outputs_root, 'stage'));
ensure_dir(fullfile(outputs_root, 'benchmark'));
ensure_dir(fullfile(outputs_root, 'logs'));
ensure_dir(fullfile(outputs_root, 'bundles'));
ensure_dir(fullfile(outputs_root, 'milestones'));
ensure_dir(fullfile(outputs_root, 'shared_scenarios'));
ensure_dir(fullfile(outputs_root, 'stage13'));

ensure_dir(fullfile(outputs_root, 'milestones', 'MA'));
ensure_dir(fullfile(outputs_root, 'milestones', 'MB'));
ensure_dir(fullfile(outputs_root, 'milestones', 'MC'));
ensure_dir(fullfile(outputs_root, 'milestones', 'MD'));
ensure_dir(fullfile(outputs_root, 'milestones', 'ME'));
ensure_dir(fullfile(outputs_root, 'shared_scenarios', 'SS1'));
ensure_dir(fullfile(outputs_root, 'shared_scenarios', 'SS2'));

for k = 0:11
    stage_name = sprintf('stage%02d', k);
    ensure_dir(fullfile(outputs_root, 'stage', stage_name));
    ensure_dir(fullfile(outputs_root, 'stage', stage_name, 'cache'));
    ensure_dir(fullfile(outputs_root, 'stage', stage_name, 'figs'));
    ensure_dir(fullfile(outputs_root, 'stage', stage_name, 'tables'));
    ensure_dir(fullfile(outputs_root, 'logs', stage_name));
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
