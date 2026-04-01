function split = stage15_split_staticworld_dataset_holdout_stratified(dataset)
%STAGE15_SPLIT_STATICWORLD_DATASET_HOLDOUT_STRATIFIED
% Stratified hold-out by geometry_class.
%
% For each geometry_class, hold out the last target_id (stable order) as test.
% The remaining target_ids are used for train.

geometry_classes = string({dataset.geometry_class});
target_ids = string({dataset.target_id});

ug = unique(geometry_classes, 'stable');

train_targets = strings(0,1);
test_targets = strings(0,1);

for i = 1:numel(ug)
    g = ug(i);
    mask_g = geometry_classes == g;
    targets_g = unique(target_ids(mask_g), 'stable');

    assert(numel(targets_g) >= 2, ...
        'Each geometry_class must have at least 2 target_ids for stratified hold-out.');

    test_targets(end+1,1) = targets_g(end); %#ok<AGROW>
    train_targets = [train_targets; targets_g(1:end-1).']; %#ok<AGROW>
end

train_mask = ismember(target_ids, train_targets);
test_mask = ismember(target_ids, test_targets);

split = struct();
split.train_targets = cellstr(train_targets);
split.test_targets = cellstr(test_targets);
split.train_dataset = dataset(train_mask);
split.test_dataset = dataset(test_mask);
end
