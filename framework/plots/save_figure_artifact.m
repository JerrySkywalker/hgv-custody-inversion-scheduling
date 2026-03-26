function out_path = save_figure_artifact(fig, save_spec)
%SAVE_FIGURE_ARTIFACT Save figure to file.

if nargin < 2
    save_spec = struct();
end

output_dir = local_get(save_spec, 'output_dir', fullfile('outputs','framework','plots'));
file_name = local_get(save_spec, 'file_name', ['figure_' datestr(now,'yyyymmdd_HHMMSS') '.png']);

if exist(output_dir, 'dir') ~= 7
    mkdir(output_dir);
end

out_path = fullfile(output_dir, file_name);
saveas(fig, out_path);
end

function v = local_get(s, f, d)
if isfield(s, f) && ~isempty(s.(f))
    v = s.(f);
else
    v = d;
end
end
