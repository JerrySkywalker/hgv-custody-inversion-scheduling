function filt = filter_candidates_by_template(candidate_feats, lib, match, topK)
%FILTER_CANDIDATES_BY_TEMPLATE
% WS-5-R1
% Keep the top-K candidates closest to the matched template prototype.

assert(isstruct(candidate_feats) && ~isempty(candidate_feats), ...
    'candidate_feats must be a non-empty struct array.');
assert(isstruct(lib) && isfield(lib, 'templates') && ~isempty(lib.templates), ...
    'lib.templates must be available.');
assert(isstruct(match) && isfield(match, 'best_index'), ...
    'match.best_index is required.');

if nargin < 4 || isempty(topK)
    topK = min(8, numel(candidate_feats));
end

tpl = lib.templates(match.best_index);
z_tpl = tpl.prototype_feature(:).';

n = numel(candidate_feats);
dist = zeros(n,1);

for i = 1:n
    z = local_feature_vector(candidate_feats(i));
    dist(i) = norm(z - z_tpl, 2);
end

[dist_sorted, ord] = sort(dist, 'ascend');
keep_n = min(topK, n);
keep_idx = ord(1:keep_n);

filt = struct();
filt.keep_idx = keep_idx(:).';
filt.keep_distances = dist(keep_idx);
filt.all_distances = dist;
filt.sorted_distances = dist_sorted;
filt.template_id = tpl.template_id;
filt.template_family = tpl.template_family;
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
