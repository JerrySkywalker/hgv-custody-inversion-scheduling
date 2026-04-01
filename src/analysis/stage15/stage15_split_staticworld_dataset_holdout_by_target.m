function split = stage15_split_staticworld_dataset_holdout_by_target(dataset)
%STAGE15_SPLIT_STATICWORLD_DATASET_HOLDOUT_BY_TARGET
% Hold-out split by target_id.
%
% Train targets: first 6 unique target ids
% Test targets : remaining unique target ids

target_ids = string({dataset.target_id});
u = unique(target_ids, 'stable');

assert(numel(u) >= 2, 'Need at least 2 unique target ids.');

n_train_targets = min(6, max(1, numel(u)-1));
train_targets = u(1:n_train_targets);
test_targets  = u(n_train_targets+1:end);

train_mask = ismember(target_ids, train_targets);
test_mask  = ismember(target_ids, test_targets);

split = struct();
split.train_targets = cellstr(train_targets);
split.test_targets = cellstr(test_targets);
split.train_dataset = dataset(train_mask);
split.test_dataset = dataset(test_mask);
end
