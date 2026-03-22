function out = project_figure_manager(action, varargin)
%PROJECT_FIGURE_MANAGER Audit and control project-wide figure visibility.

if nargin < 1 || isempty(action)
    action = 'get_visibility';
end

action = char(lower(string(action)));
switch action
    case 'audit'
        out = local_run_audit(local_resolve_root(varargin{:}));
    case 'create'
        if nargin < 2
            cfg = struct();
            fig_args = {};
        else
            cfg = varargin{1};
            fig_args = varargin(2:end);
        end
        out = create_managed_figure(cfg, fig_args{:});
    case 'set_mode'
        mode = "headless";
        if nargin >= 2 && ~isempty(varargin{1})
            mode = string(varargin{1});
        end
        runtime = get_plot_runtime_config(struct('plotting', struct('mode', mode)));
        out = apply_plot_runtime_config(runtime);
    case 'get_visibility'
        runtime = get_plot_runtime_config([]);
        out = string(runtime.mode);
    case 'apply_defaults'
        if nargin < 2
            error('project_figure_manager:MissingFigure', 'apply_defaults requires a figure handle.');
        end
        fig = varargin{1};
        runtime = get_plot_runtime_config([]);
        set(fig, 'Color', 'w');
        if runtime.renderer ~= "auto"
            set(fig, 'Renderer', char(runtime.renderer));
        end
        out = fig;
    otherwise
        error('project_figure_manager:UnknownAction', 'Unknown action "%s".', action);
end
end

function out = local_run_audit(root_dir)
tables_dir = fullfile(root_dir, 'outputs', 'milestones', 'startup_audit', 'tables');
ensure_dir(tables_dir);

files = dir(fullfile(root_dir, '**', '*.m'));
rows = cell(0, 6);
pattern = '(?<call>\bfigure\s*\(|\bsubplot\b|\btiledlayout\b|saveas\s*\(|exportgraphics\s*\(|print\s*\()';
for idx_file = 1:numel(files)
    file_path = fullfile(files(idx_file).folder, files(idx_file).name);
    if contains(lower(file_path), [filesep '.git' filesep])
        continue;
    end
    contents = splitlines(string(fileread(file_path)));
    for idx_line = 1:numel(contents)
        line_text = contents(idx_line);
        if isempty(regexp(char(line_text), pattern, 'once'))
            continue;
        end
        call_type = local_detect_call(line_text);
        visibility = local_detect_visibility(line_text);
        rows(end + 1, :) = { ... %#ok<AGROW>
            string(strrep(file_path, [root_dir filesep], '')), ...
            idx_line, ...
            string(call_type), ...
            string(visibility), ...
            contains(lower(line_text), 'create_managed_figure'), ...
            string(local_risk_label(call_type, visibility, line_text))};
    end
end
audit_table = cell2table(rows, 'VariableNames', ...
    {'file', 'line_number', 'call_type', 'visibility_mode', 'uses_managed_wrapper', 'suspected_risk'});
if isempty(audit_table)
    audit_table = table('Size', [0, 6], ...
        'VariableTypes', {'string', 'double', 'string', 'string', 'logical', 'string'}, ...
        'VariableNames', {'file', 'line_number', 'call_type', 'visibility_mode', 'uses_managed_wrapper', 'suspected_risk'});
else
    audit_table.file = string(audit_table.file);
    audit_table.line_number = double(audit_table.line_number);
    audit_table.call_type = string(audit_table.call_type);
    audit_table.visibility_mode = string(audit_table.visibility_mode);
    audit_table.uses_managed_wrapper = logical(audit_table.uses_managed_wrapper);
    audit_table.suspected_risk = string(audit_table.suspected_risk);
end

csv_path = fullfile(tables_dir, 'figure_creation_audit_summary.csv');
writetable(audit_table, csv_path);
out = struct('audit_csv', string(csv_path), 'audit_table', audit_table);
end

function call_type = local_detect_call(line_text)
line_lc = lower(char(line_text));
if contains(line_lc, 'create_managed_figure')
    call_type = "create_managed_figure";
elseif contains(line_lc, 'figure(')
    call_type = "figure";
elseif contains(line_lc, 'subplot')
    call_type = "subplot";
elseif contains(line_lc, 'tiledlayout')
    call_type = "tiledlayout";
elseif contains(line_lc, 'exportgraphics')
    call_type = "exportgraphics";
elseif contains(line_lc, 'saveas')
    call_type = "saveas";
else
    call_type = "print";
end
end

function visibility = local_detect_visibility(line_text)
line_lc = lower(char(line_text));
if contains(line_lc, '''visible''') || contains(line_lc, '"visible"')
    if contains(line_lc, '''off''') || contains(line_lc, '"off"')
        visibility = "headless_literal";
    elseif contains(line_lc, '''on''') || contains(line_lc, '"on"')
        visibility = "visible_literal";
    else
        visibility = "runtime_expression";
    end
elseif contains(line_lc, 'create_managed_figure')
    visibility = "managed_runtime";
else
    visibility = "implicit_default";
end
end

function risk = local_risk_label(call_type, visibility, line_text)
line_lc = lower(char(line_text));
if call_type == "create_managed_figure"
    risk = "managed_ok";
elseif call_type == "figure" && visibility == "implicit_default"
    risk = "raw_figure_visibility_implicit";
elseif call_type == "figure" && visibility == "visible_literal"
    risk = "raw_visible_window";
elseif any(call_type == ["saveas", "exportgraphics", "print"])
    risk = "export_call_ok";
elseif contains(line_lc, 'gcf')
    risk = "gcf_dependency_manual_review";
else
    risk = "manual_review";
end
end

function root_dir = local_resolve_root(varargin)
root_dir = fileparts(mfilename('fullpath'));
if nargin >= 1 && ~isempty(varargin{1})
    candidate = char(string(varargin{1}));
    if isfolder(candidate)
        root_dir = candidate;
    end
end
end
