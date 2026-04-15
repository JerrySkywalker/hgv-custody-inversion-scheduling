function registry = build_ch5r_case_registry()
%BUILD_CH5R_CASE_REGISTRY
% Deterministic Chapter 5 case registry based on current Stage01/Stage02 naming convention.
%
% Families:
% - nominal : N01 ... N12
% - heading : H01_+00, H01_-30, H01_+30, H01_-60, H01_+60, ...
% - critical: C1_track_plane_aligned, C2_small_crossing_angle

suite = default_ch5r_suite_params();

rows = {};
row_id = 0;

% --------------------------------
% Nominal cases
% --------------------------------
for k = 1:12
    row_id = row_id + 1;
    case_id = sprintf('N%02d', k);
    rows(row_id,:) = {row_id, case_id, 'nominal', sprintf('N%02d', k), NaN}; %#ok<AGROW>
end

% --------------------------------
% Heading cases
% --------------------------------
offset_labels = {'+00', '-30', '+30', '-60', '+60'};
offset_values = [0, -30, 30, -60, 60];

for base = 1:12
    for j = 1:numel(offset_labels)
        row_id = row_id + 1;
        case_id = sprintf('H%02d_%s', base, offset_labels{j});
        rows(row_id,:) = {row_id, case_id, 'heading', sprintf('N%02d', base), offset_values(j)}; %#ok<AGROW>
    end
end

% --------------------------------
% Critical cases
% --------------------------------
critical_cases = { ...
    {'C1_track_plane_aligned', 'critical', 'N07', NaN}, ...
    {'C2_small_crossing_angle', 'critical', 'N10', NaN}};

for i = 1:numel(critical_cases)
    row_id = row_id + 1;
    cc = critical_cases{i};
    rows(row_id,:) = {row_id, cc{1}, cc{2}, cc{3}, cc{4}}; %#ok<AGROW>
end

registry = cell2table(rows, 'VariableNames', ...
    {'row_id','case_id','family','base_nominal_case','heading_offset_deg'});

registry.include_in_smoke = ismember(registry.case_id, suite.case_sets.smoke(:));
registry.include_in_paper = ismember(registry.case_id, suite.case_sets.paper(:));

registry = movevars(registry, {'include_in_smoke','include_in_paper'}, 'After', 'family');
end
