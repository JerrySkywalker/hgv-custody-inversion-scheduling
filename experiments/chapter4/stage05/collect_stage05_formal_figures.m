function exports = collect_stage05_formal_figures(out)
%COLLECT_STAGE05_FORMAL_FIGURES Collect key formal-suite figures into one directory.

artifact_root = out.suite_spec.artifact_root;
fig_dir = fullfile(artifact_root, 'formal_figures');
if exist(fig_dir, 'dir') ~= 7
    mkdir(fig_dir);
end

exports = struct();
exports.figure_dir = string(fig_dir);
exports.files = struct();

manifest_txt = fullfile(fig_dir, 'formal_figures_manifest.txt');
fid = fopen(manifest_txt, 'w');

if fid ~= -1
    fprintf(fid, 'Stage05 formal figures manifest\n');
    fprintf(fid, 'generated_at: %s\n\n', string(datetime('now')));
end

% -------------------------------------------------------------------------
% Legacy reproduction: use existing plot_outputs if present, otherwise
% regenerate directly from outputs.
% -------------------------------------------------------------------------
legacy_best_dst = fullfile(fig_dir, 'legacy_best_pass_by_Ns.png');
legacy_hm_dst = fullfile(fig_dir, 'legacy_geometry_heatmap_i60.png');

legacy_best_src = "";
legacy_hm_src = "";

if isfield(out.legacy_reproduction, 'plot_outputs') ...
        && isstruct(out.legacy_reproduction.plot_outputs) ...
        && isfield(out.legacy_reproduction.plot_outputs, 'best_pass_by_Ns_plot')
    legacy_best_src = string(out.legacy_reproduction.plot_outputs.best_pass_by_Ns_plot.file_path);
end

if isfield(out.legacy_reproduction, 'plot_outputs') ...
        && isstruct(out.legacy_reproduction.plot_outputs) ...
        && isfield(out.legacy_reproduction.plot_outputs, 'geometry_heatmap_i60_plot')
    legacy_hm_src = string(out.legacy_reproduction.plot_outputs.geometry_heatmap_i60_plot.file_path);
end

if strlength(legacy_best_src) > 0 && isfile(char(legacy_best_src))
    copyfile(char(legacy_best_src), legacy_best_dst);
else
    env_tbl = out.legacy_reproduction.outputs.best_pass_by_Ns;
    fig = plot_envelope_curve(env_tbl.Ns, env_tbl.pass_ratio, struct( ...
        'title', 'Legacy reproduction: best pass by Ns', ...
        'x_label', 'Ns', ...
        'y_label', 'best pass ratio', ...
        'visible', 'off'));
    save_figure_artifact(fig, struct( ...
        'output_dir', fig_dir, ...
        'file_name', 'legacy_best_pass_by_Ns.png'));
end

if strlength(legacy_hm_src) > 0 && isfile(char(legacy_hm_src))
    copyfile(char(legacy_hm_src), legacy_hm_dst);
else
    hm = out.legacy_reproduction.outputs.geometry_heatmap_i60;
    fig = plot_heatmap_matrix(hm.row_values, hm.col_values, hm.value_matrix, struct( ...
        'title', 'Legacy reproduction: geometry heatmap i=60', ...
        'x_label', 'T', ...
        'y_label', 'P', ...
        'visible', 'off'));
    save_figure_artifact(fig, struct( ...
        'output_dir', fig_dir, ...
        'file_name', 'legacy_geometry_heatmap_i60.png'));
end

exports.files.legacy_best_pass_by_Ns_png = string(legacy_best_dst);
exports.files.legacy_geometry_heatmap_i60_png = string(legacy_hm_dst);

if fid ~= -1
    fprintf(fid, '%s\n', legacy_best_dst);
    fprintf(fid, '%s\n', legacy_hm_dst);
end

% -------------------------------------------------------------------------
% OpenD manual-RAAN
% -------------------------------------------------------------------------
local_copy_required_figure( ...
    out.opend_manual_raan.plot_outputs.env_min_DG_plot.file_path, ...
    fullfile(fig_dir, 'opend_env_min_DG.png'), ...
    'opend_env_min_DG_png');

local_copy_required_figure( ...
    out.opend_manual_raan.plot_outputs.env_min_pass_ratio_plot.file_path, ...
    fullfile(fig_dir, 'opend_env_min_pass_ratio.png'), ...
    'opend_env_min_pass_ratio_png');

% -------------------------------------------------------------------------
% ClosedD manual-RAAN
% -------------------------------------------------------------------------
local_copy_required_figure( ...
    out.closedd_manual_raan.plot_outputs.env_min_joint_margin_plot.file_path, ...
    fullfile(fig_dir, 'closedd_env_min_joint_margin.png'), ...
    'closedd_env_min_joint_margin_png');

local_copy_required_figure( ...
    out.closedd_manual_raan.plot_outputs.env_min_pass_ratio_plot.file_path, ...
    fullfile(fig_dir, 'closedd_env_min_pass_ratio.png'), ...
    'closedd_env_min_pass_ratio_png');

if fid ~= -1
    fprintf(fid, '%s\n', exports.files.opend_env_min_DG_png);
    fprintf(fid, '%s\n', exports.files.opend_env_min_pass_ratio_png);
    fprintf(fid, '%s\n', exports.files.closedd_env_min_joint_margin_png);
    fprintf(fid, '%s\n', exports.files.closedd_env_min_pass_ratio_png);
    fclose(fid);
end

exports.manifest_txt = string(manifest_txt);

    function local_copy_required_figure(src, dst, field_name)
        src = char(string(src));
        if ~isfile(src)
            error('collect_stage05_formal_figures:MissingFigure', ...
                'Required figure is missing: %s', src);
        end
        copyfile(src, dst);
        exports.files.(field_name) = string(dst);
    end
end
