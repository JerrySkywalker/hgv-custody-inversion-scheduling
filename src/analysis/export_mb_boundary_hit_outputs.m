function artifacts = export_mb_boundary_hit_outputs(diagnostics, paths, context_tag)
%EXPORT_MB_BOUNDARY_HIT_OUTPUTS Export boundary/saturation diagnostic tables for a given MB context.

artifacts = struct('boundary_hit_csv', "", 'passratio_csv', "", 'frontier_csv', "");

if nargin < 3 || strlength(string(context_tag)) == 0
    context_tag = "context";
end

context_tag = char(string(context_tag));

if isfield(diagnostics, 'boundary_hit_table') && istable(diagnostics.boundary_hit_table) && ~isempty(diagnostics.boundary_hit_table)
    file_path = fullfile(paths.tables, sprintf('MB_boundary_hit_summary_%s.csv', context_tag));
    milestone_common_save_table(diagnostics.boundary_hit_table, file_path);
    artifacts.boundary_hit_csv = string(file_path);
end

if isfield(diagnostics, 'passratio_saturation_table') && istable(diagnostics.passratio_saturation_table) && ~isempty(diagnostics.passratio_saturation_table)
    file_path = fullfile(paths.tables, sprintf('MB_passratio_saturation_summary_%s.csv', context_tag));
    milestone_common_save_table(diagnostics.passratio_saturation_table, file_path);
    artifacts.passratio_csv = string(file_path);
end

if isfield(diagnostics, 'frontier_truncation_table') && istable(diagnostics.frontier_truncation_table) && ~isempty(diagnostics.frontier_truncation_table)
    file_path = fullfile(paths.tables, sprintf('MB_frontier_truncation_summary_%s.csv', context_tag));
    milestone_common_save_table(diagnostics.frontier_truncation_table, file_path);
    artifacts.frontier_csv = string(file_path);
end
end
