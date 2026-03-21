function fig = create_managed_figure(cfg_or_runtime, varargin)
%CREATE_MANAGED_FIGURE Create a figure honoring the global plotting runtime.

runtime = get_plot_runtime_config(cfg_or_runtime);
args = varargin;

if ~local_has_key(args, 'Visible')
    if runtime.mode == "visible" && logical(runtime.default_visible)
        args = [args, {'Visible', 'on'}]; %#ok<AGROW>
    else
        args = [args, {'Visible', 'off'}]; %#ok<AGROW>
    end
end
if ~local_has_key(args, 'Color')
    args = [args, {'Color', 'w'}]; %#ok<AGROW>
end
if runtime.renderer ~= "auto" && ~local_has_key(args, 'Renderer')
    args = [args, {'Renderer', char(runtime.renderer)}]; %#ok<AGROW>
end

fig = figure(args{:});
end

function tf = local_has_key(args, key)
tf = false;
for idx = 1:2:numel(args)
    if idx <= numel(args) && (ischar(args{idx}) || isstring(args{idx}))
        if strcmpi(char(string(args{idx})), key)
            tf = true;
            return;
        end
    end
end
end
