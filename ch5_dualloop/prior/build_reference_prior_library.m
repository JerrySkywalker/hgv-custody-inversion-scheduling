function lib = build_reference_prior_library(feature_records)
%BUILD_REFERENCE_PRIOR_LIBRARY
% WS-3-R1
% Build a minimal prototype-based template library from local-frame features.
%
% Input:
%   feature_records: struct array with fields
%       num_sats
%       baseline_km
%       Bxy_cand
%       Ruse
%       xy_radius_km
%
% Output:
%   lib.templates
%   lib.meta

assert(isstruct(feature_records) && ~isempty(feature_records), ...
    'feature_records must be a non-empty struct array.');

n = numel(feature_records);
rows = zeros(n, 5);
families = strings(n,1);

for i = 1:n
    rows(i,:) = local_feature_vector(feature_records(i));
    families(i) = local_assign_family(feature_records(i));
end

family_list = unique(families, 'stable');
template_cells = cell(1, numel(family_list));

for j = 1:numel(family_list)
    fam = family_list(j);
    idx = find(families == fam);

    proto = mean(rows(idx,:), 1);

    tpl = struct();
    tpl.template_id = sprintf('TPL_%02d', j);
    tpl.template_family = char(fam);
    tpl.prototype_feature = proto;
    tpl.member_indices = idx(:).';
    tpl.member_count = numel(idx);

    template_cells{j} = tpl;
end

templates = [template_cells{:}];

lib = struct();
lib.templates = templates;
lib.meta = struct();
lib.meta.feature_dim = 5;
lib.meta.feature_name = {'num_sats','baseline_km_n','Bxy_cand_km_n','Ruse_km_n','mean_xy_radius_km_n'};
lib.meta.num_input_records = n;
lib.meta.num_templates = numel(templates);
end

function z = local_feature_vector(rec)
xy = rec.xy_radius_km(:);
mean_xy = mean(xy);

z = [
    double(rec.num_sats), ...
    double(rec.baseline_km) / 1000.0, ...
    double(rec.Bxy_cand) / 1000.0, ...
    double(rec.Ruse) / 1000.0, ...
    double(mean_xy) / 1000.0];
end

function fam = local_assign_family(rec)
if rec.num_sats <= 2
    if rec.Bxy_cand < 2200
        fam = "pair_compact";
    elseif rec.Bxy_cand < 3000
        fam = "pair_medium";
    else
        fam = "pair_wide";
    end
else
    if rec.Bxy_cand < 2600
        fam = "multi_compact";
    else
        fam = "multi_wide";
    end
end
end
