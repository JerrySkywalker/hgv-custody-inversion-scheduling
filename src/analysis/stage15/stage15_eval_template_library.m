function result = stage15_eval_template_library(dataset, template_library)
%STAGE15_EVAL_TEMPLATE_LIBRARY
% Evaluate nearest-template matching on the current dataset.

matches = struct( ...
    'sample_id', {}, ...
    'true_label', {}, ...
    'matched_template_id', {}, ...
    'matched_label', {}, ...
    'distance', {}, ...
    'is_correct', {});

for i = 1:numel(dataset)
    m = stage15_match_template_for_sample(dataset(i), template_library);
    matches(end+1) = m; %#ok<AGROW>
end

num_correct = sum([matches.is_correct]);
num_samples = numel(matches);
accuracy = num_correct / max(num_samples, 1);

result = struct();
result.matches = matches;
result.num_samples = num_samples;
result.num_correct = num_correct;
result.accuracy = accuracy;
end
