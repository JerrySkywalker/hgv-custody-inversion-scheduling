function summary_path = mb_vgeom_write_summary(scene_agg_table, output_paths, cfg_vgeom)
%MB_VGEOM_WRITE_SUMMARY Write a concise markdown summary for the vgeom run.

if nargin < 3 || isempty(cfg_vgeom)
    cfg_vgeom = struct();
end

summary_path = fullfile(output_paths.tables, 'MB_vgeom_summary.md');
fid = fopen(summary_path, 'w');
if fid < 0
    error('Failed to open summary markdown for writing: %s', summary_path);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, '# MB vgeom h=1000 summary\n\n');
fprintf(fid, '- sensor group: `%s`\n', char(string(local_getfield_or(cfg_vgeom, 'sensor_group', 'baseline'))));
fprintf(fid, '- semantics: `%s`\n', strjoin(cellstr(string(local_getfield_or(cfg_vgeom, 'semantics', {}))), '`, `'));
fprintf(fid, '- inclinations: `%s`\n', strjoin(arrayfun(@(v) sprintf('%g', v), local_getfield_or(cfg_vgeom, 'inclination_deg_list', []), 'UniformOutput', false), ', '));
fprintf(fid, '- scene grid: `%d x %d`\n\n', local_getfield_or(cfg_vgeom, 'raan_bins', 6), local_getfield_or(cfg_vgeom, 'phase_bins', 6));

semantic_values = unique(string(scene_agg_table.semantic), 'stable');
for idx_sem = 1:numel(semantic_values)
    semantic_name = semantic_values(idx_sem);
    fprintf(fid, '## %s\n\n', char(semantic_name));
    inclinations = unique(scene_agg_table.inclination_deg(string(scene_agg_table.semantic) == semantic_name));
    for idx_i = 1:numel(inclinations)
        mask = string(scene_agg_table.semantic) == semantic_name & abs(double(scene_agg_table.inclination_deg) - inclinations(idx_i)) < 1e-9;
        sub = sortrows(scene_agg_table(mask, :), 'Ns');
        q25_changes = local_direction_changes(sub.scene_best_q25);
        median_changes = local_direction_changes(sub.scene_best_median);
        fprintf(fid, '- i = %.0f deg: Ns = [%s], q25 direction changes = %d, median direction changes = %d, q25 envelope final = %.3f.\n', ...
            inclinations(idx_i), strjoin(arrayfun(@(v) sprintf('%g', v), sub.Ns, 'UniformOutput', false), ', '), ...
            q25_changes, median_changes, local_last_finite(sub.scene_best_q25_envelope));
    end
    fprintf(fid, '\n');
end
end

function count = local_direction_changes(values)
values = values(isfinite(values));
if numel(values) < 3
    count = 0;
    return;
end
d = diff(values);
d = d(abs(d) > 1e-12);
if numel(d) < 2
    count = 0;
    return;
end
count = sum(sign(d(1:end-1)) .* sign(d(2:end)) < 0);
end

function value = local_last_finite(values)
idx = find(isfinite(values), 1, 'last');
if isempty(idx)
    value = NaN;
else
    value = values(idx);
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
