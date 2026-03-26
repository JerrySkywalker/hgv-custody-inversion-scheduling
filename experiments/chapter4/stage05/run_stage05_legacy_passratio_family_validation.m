function out = run_stage05_legacy_passratio_family_validation(varargin)
%RUN_STAGE05_LEGACY_PASSRATIO_FAMILY_VALIDATION
% Build strict all-i pass-ratio family validation assets based on Stage05
% full-grid best-envelope comparison.

p = inputParser;
addParameter(p, 'artifact_root', fullfile('outputs','experiments','chapter4','stage05_passratio_family_validation'), @(x) ischar(x) || isstring(x));
parse(p, varargin{:});
args = p.Results;

artifact_root = char(string(args.artifact_root));
fig_dir = fullfile(artifact_root, 'figures');
table_dir = fullfile(artifact_root, 'tables');
manifest_dir = fullfile(artifact_root, 'manifest');

if exist(fig_dir, 'dir') ~= 7, mkdir(fig_dir); end
if exist(table_dir, 'dir') ~= 7, mkdir(table_dir); end
if exist(manifest_dir, 'dir') ~= 7, mkdir(manifest_dir); end

cmp = manual_compare_stage05_best_envelope_fullgrid_all_i();

compare_tbl = cmp.compare_table;
summary_tbl = cmp.summary_table;

compare_csv = fullfile(table_dir, 'passratio_family_compare_table.csv');
summary_csv = fullfile(table_dir, 'passratio_family_summary_table.csv');
writetable(compare_tbl, compare_csv);
writetable(summary_tbl, summary_csv);

i_list = unique(compare_tbl.i_deg(:))';
fig_legacy = figure('Visible', 'off');
hold on;
for i = i_list
    mask = compare_tbl.i_deg == i;
    tbl = sortrows(compare_tbl(mask, {'Ns','legacy_best_pass'}), 'Ns');
    plot(tbl.Ns, tbl.legacy_best_pass, '-o', 'DisplayName', sprintf('legacy i=%d', i));
end
grid on;
xlabel('Ns');
ylabel('best pass ratio');
title('Stage05 legacy pass ratio family');
legend('Location', 'eastoutside');
saveas(fig_legacy, fullfile(fig_dir, 'stage05_legacy_passratio_family.png'));

fig_engine = figure('Visible', 'off');
hold on;
for i = i_list
    mask = compare_tbl.i_deg == i;
    tbl = sortrows(compare_tbl(mask, {'Ns','engine_best_pass'}), 'Ns');
    plot(tbl.Ns, tbl.engine_best_pass, '-o', 'DisplayName', sprintf('engine i=%d', i));
end
grid on;
xlabel('Ns');
ylabel('best pass ratio');
title('Stage05 engine pass ratio family');
legend('Location', 'eastoutside');
saveas(fig_engine, fullfile(fig_dir, 'stage05_engine_passratio_family.png'));

fig_overlay = figure('Visible', 'off');
hold on;
for i = i_list
    mask = compare_tbl.i_deg == i;
    tbl = sortrows(compare_tbl(mask, {'Ns','legacy_best_pass','engine_best_pass'}), 'Ns');
    plot(tbl.Ns, tbl.legacy_best_pass, '--', 'DisplayName', sprintf('legacy i=%d', i));
    plot(tbl.Ns, tbl.engine_best_pass, '-o', 'DisplayName', sprintf('engine i=%d', i));
end
grid on;
xlabel('Ns');
ylabel('best pass ratio');
title('Stage05 pass ratio family overlay');
legend('Location', 'eastoutside');
saveas(fig_overlay, fullfile(fig_dir, 'stage05_passratio_family_overlay.png'));

manifest_txt = fullfile(manifest_dir, 'passratio_family_manifest.txt');
fid = fopen(manifest_txt, 'w');
if fid ~= -1
    fprintf(fid, 'Stage05 passratio family validation manifest\n');
    fprintf(fid, 'generated_at: %s\n\n', string(datetime('now')));
    fprintf(fid, '%s\n', compare_csv);
    fprintf(fid, '%s\n', summary_csv);
    fprintf(fid, '%s\n', fullfile(fig_dir, 'stage05_legacy_passratio_family.png'));
    fprintf(fid, '%s\n', fullfile(fig_dir, 'stage05_engine_passratio_family.png'));
    fprintf(fid, '%s\n', fullfile(fig_dir, 'stage05_passratio_family_overlay.png'));
    fclose(fid);
end

out = struct();
out.compare_table = compare_tbl;
out.summary_table = summary_tbl;
out.compare_csv = string(compare_csv);
out.summary_csv = string(summary_csv);
out.figure_legacy = string(fullfile(fig_dir, 'stage05_legacy_passratio_family.png'));
out.figure_engine = string(fullfile(fig_dir, 'stage05_engine_passratio_family.png'));
out.figure_overlay = string(fullfile(fig_dir, 'stage05_passratio_family_overlay.png'));
out.manifest_txt = string(manifest_txt);
end
