function exports = collect_stage05_formal_figures(out)
%COLLECT_STAGE05_FORMAL_FIGURES Collect key formal-suite figures into one directory.

artifact_root = out.suite_spec.artifact_root;
fig_dir = fullfile(artifact_root, 'formal_figures');
if exist(fig_dir, 'dir') ~= 7
    mkdir(fig_dir);
end

items = {};

% legacy reproduction
items(end+1, :) = { ...
    char(out.legacy_reproduction.plot_outputs.best_pass_by_Ns_plot.file_path), ...
    'legacy_best_pass_by_Ns.png'};
items(end+1, :) = { ...
    char(out.legacy_reproduction.plot_outputs.geometry_heatmap_i60_plot.file_path), ...
    'legacy_geometry_heatmap_i60.png'};

% OpenD manual-RAAN
items(end+1, :) = { ...
    char(out.opend_manual_raan.plot_outputs.env_min_DG_plot.file_path), ...
    'opend_env_min_DG.png'};
items(end+1, :) = { ...
    char(out.opend_manual_raan.plot_outputs.env_min_pass_ratio_plot.file_path), ...
    'opend_env_min_pass_ratio.png'};

% ClosedD manual-RAAN
items(end+1, :) = { ...
    char(out.closedd_manual_raan.plot_outputs.env_min_joint_margin_plot.file_path), ...
    'closedd_env_min_joint_margin.png'};
items(end+1, :) = { ...
    char(out.closedd_manual_raan.plot_outputs.env_min_pass_ratio_plot.file_path), ...
    'closedd_env_min_pass_ratio.png'};

exports = struct();
exports.figure_dir = string(fig_dir);
exports.files = struct();

manifest_txt = fullfile(fig_dir, 'formal_figures_manifest.txt');
fid = fopen(manifest_txt, 'w');

if fid ~= -1
    fprintf(fid, 'Stage05 formal figures manifest\n');
    fprintf(fid, 'generated_at: %s\n\n', string(datetime('now')));
end

for i = 1:size(items, 1)
    src = items{i, 1};
    dst_name = items{i, 2};
    dst = fullfile(fig_dir, dst_name);

    if isfile(src)
        copyfile(src, dst);
        exports.files.(matlab.lang.makeValidName(dst_name)) = string(dst);
        if fid ~= -1
            fprintf(fid, '%s\n', dst);
        end
    else
        exports.files.(matlab.lang.makeValidName(dst_name)) = "";
        if fid ~= -1
            fprintf(fid, '[missing] %s (source: %s)\n', dst_name, src);
        end
    end
end

if fid ~= -1
    fclose(fid);
end

exports.manifest_txt = string(manifest_txt);
end
