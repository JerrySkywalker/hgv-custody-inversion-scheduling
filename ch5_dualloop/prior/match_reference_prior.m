function match = match_reference_prior(lib, candidate_feature, exclude_template_ids)
%MATCH_REFERENCE_PRIOR
% WS-4-R2
% Match one candidate/local-frame feature against a prototype library
% and return reference ids.
%
% Optional:
%   exclude_template_ids : cellstr / string array / char list of template ids
%                          to exclude from matching

if nargin < 3 || isempty(exclude_template_ids)
    exclude_template_ids = {};
end

assert(isstruct(candidate_feature), 'candidate_feature must be a struct.');
assert(isstruct(lib) && isfield(lib, 'templates') && ~isempty(lib.templates), ...
    'lib.templates must be available.');

if ischar(exclude_template_ids)
    exclude_template_ids = {exclude_template_ids};
elseif isstring(exclude_template_ids)
    exclude_template_ids = cellstr(exclude_template_ids(:));
end

z = local_feature_vector(candidate_feature);

m = numel(lib.templates);
dist = inf(m,1);

for i = 1:m
    tpl_id = lib.templates(i).template_id;
    if any(strcmp(exclude_template_ids, tpl_id))
        continue
    end

    z_tpl = lib.templates(i).prototype_feature(:).';
    dist(i) = norm(z - z_tpl, 2);
end

[best_distance, idx] = min(dist);
assert(isfinite(best_distance), 'No valid template remains after exclusion.');

match = struct();
match.best_template_id = lib.templates(idx).template_id;
match.best_template_family = lib.templates(idx).template_family;
match.best_distance = best_distance;
match.best_index = idx;
match.ref_ids = lib.templates(idx).prototype_ids(:).';
match.all_distances = dist;
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
