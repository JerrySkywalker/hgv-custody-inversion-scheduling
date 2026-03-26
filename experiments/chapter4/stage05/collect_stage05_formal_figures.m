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
% Legacy reproduction: regenerate from outputs
% -------------------------------------------------------------------------
legacy_best_dst = fullfile(fig_dir, 'legacy_best_pass_by_Ns.png');
legacy_hm_dst   = fullfile(fig_dir, 'legacy_geometry_heatmap_i60.png');

env_tbl = out.legacy_reproduction.outputs.best_pass_by_Ns;
fig = plot_envelope_curve(env_tbl.Ns, env_tbl.pass_ratio, struct( ...
    'title', 'Legacy reproduction: best pass by Ns', ...
    'x_label', 'Ns', ...
    'y_label', 'best pass ratio', ...
    'visible', 'off'));
save_figure_artifact(fig, struct( ...
    'output_dir', fig_dir, ...
    'file_name', 'legacy_best_pass_by_Ns.png'));

hm = out.legacy_reproduction.outputs.geometry_heatmap_i60;
fig = plot_heatmap_matrix(hm.row_values, hm.col_values, hm.value_matrix, struct( ...
    'title', 'Legacy reproduction: geometry heatmap i=60', ...
    'x_label', 'T', ...
    'y_label', 'P', ...
    'visible', 'off'));
save_figure_artifact(fig, struct( ...
    'output_dir', fig_dir, ...
    'file_name', 'legacy_geometry_heatmap_i60.png'));

exports.files.legacy_best_pass_by_Ns_png = string(legacy_best_dst);
exports.files.legacy_geometry_heatmap_i60_png = string(legacy_hm_dst);

% -------------------------------------------------------------------------
% OpenD manual-RAAN: regenerate from outputs
% -------------------------------------------------------------------------
opend_env_dg_dst   = fullfile(fig_dir, 'opend_env_min_DG.png');
opend_env_pr_dst   = fullfile(fig_dir, 'opend_env_min_pass_ratio.png');

tbl = out.opend_manual_raan.outputs.env_min_DG;
y = local_pick_metric_column(tbl, {'DG_rob','min_DG_rob','value'});
fig = plot_envelope_curve(tbl.Ns, tbl.(y), struct( ...
    'title', 'OpenD manual-RAAN: min DG envelope', ...
    'x_label', 'Ns', ...
    'y_label', y, ...
    'visible', 'off'));
save_figure_artifact(fig, struct( ...
    'output_dir', fig_dir, ...
    'file_name', 'opend_env_min_DG.png'));

tbl = out.opend_manual_raan.outputs.env_min_pass_ratio;
y = local_pick_metric_column(tbl, {'pass_ratio','min_pass_ratio','value'});
fig = plot_envelope_curve(tbl.Ns, tbl.(y), struct( ...
    'title', 'OpenD manual-RAAN: min pass ratio envelope', ...
    'x_label', 'Ns', ...
    'y_label', y, ...
    'visible', 'off'));
save_figure_artifact(fig, struct( ...
    'output_dir', fig_dir, ...
    'file_name', 'opend_env_min_pass_ratio.png'));

exports.files.opend_env_min_DG_png = string(opend_env_dg_dst);
exports.files.opend_env_min_pass_ratio_png = string(opend_env_pr_dst);

% -------------------------------------------------------------------------
% ClosedD manual-RAAN: regenerate from outputs
% -------------------------------------------------------------------------
closedd_env_jm_dst = fullfile(fig_dir, 'closedd_env_min_joint_margin.png');
closedd_env_pr_dst = fullfile(fig_dir, 'closedd_env_min_pass_ratio.png');

tbl = out.closedd_manual_raan.outputs.env_min_joint_margin;
y = local_pick_metric_column(tbl, {'joint_margin','min_joint_margin','value'});
fig = plot_envelope_curve(tbl.Ns, tbl.(y), struct( ...
    'title', 'ClosedD manual-RAAN: min joint margin envelope', ...
    'x_label', 'Ns', ...
    'y_label', y, ...
    'visible', 'off'));
save_figure_artifact(fig, struct( ...
    'output_dir', fig_dir, ...
    'file_name', 'closedd_env_min_joint_margin.png'));

tbl = out.closedd_manual_raan.outputs.env_min_pass_ratio;
y = local_pick_metric_column(tbl, {'pass_ratio','min_pass_ratio','value'});
fig = plot_envelope_curve(tbl.Ns, tbl.(y), struct( ...
    'title', 'ClosedD manual-RAAN: min pass ratio envelope', ...
    'x_label', 'Ns', ...
    'y_label', y, ...
    'visible', 'off'));
save_figure_artifact(fig, struct( ...
    'output_dir', fig_dir, ...
    'file_name', 'closedd_env_min_pass_ratio.png'));

exports.files.closedd_env_min_joint_margin_png = string(closedd_env_jm_dst);
exports.files.closedd_env_min_pass_ratio_png = string(closedd_env_pr_dst);

if fid ~= -1
    fns = fieldnames(exports.files);
    for i = 1:numel(fns)
        fprintf(fid, '%s\n', exports.files.(fns{i}));
    end
    fclose(fid);
end

exports.manifest_txt = string(manifest_txt);
end

function col = local_pick_metric_column(tbl, preferred_cols)
vars = string(tbl.Properties.VariableNames);
for i = 1:numel(preferred_cols)
    if any(vars == string(preferred_cols{i}))
        col = char(string(preferred_cols{i}));
        return;
    end
end

for i = 1:numel(vars)
    v = vars(i);
    if v ~= "Ns" && isnumeric(tbl.(v))
        col = char(v);
        return;
    end
end

error('collect_stage05_formal_figures:NoMetricColumn', ...
    'Could not determine metric column for figure regeneration.');
end
