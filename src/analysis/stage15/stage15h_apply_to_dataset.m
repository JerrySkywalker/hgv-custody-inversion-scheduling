function out = stage15h_apply_to_dataset(dataset)
% Stage15-H:
% 对 staticworld dataset 批量生成连续 prior。

n = numel(dataset);
prior_dataset = repmat(struct(), 1, n);

for i = 1:n
    rec = dataset(i);
    prior = stage15h_make_local_prior(rec.xi, rec.eta, rec.kappa2);

    prior_dataset(i).sample_id = rec.sample_id;
    if isfield(rec, 'target_id'); prior_dataset(i).target_id = rec.target_id; end
    if isfield(rec, 'pair_id'); prior_dataset(i).pair_id = rec.pair_id; end
    if isfield(rec, 'geometry_class'); prior_dataset(i).geometry_class = rec.geometry_class; end
    if isfield(rec, 'layout_class'); prior_dataset(i).layout_class = rec.layout_class; end
    if isfield(rec, 'risk_label'); prior_dataset(i).risk_label = rec.risk_label; end

    prior_dataset(i).prior = prior;
end

out = struct();
out.prior_dataset = prior_dataset;
out.num_samples = n;
end
