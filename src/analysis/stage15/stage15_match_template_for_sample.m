function match_rec = stage15_match_template_for_sample(sample_rec, template_library)
%STAGE15_MATCH_TEMPLATE_FOR_SAMPLE
% Match one sample to the nearest template.

best_d = inf;
best_idx = 1;

for i = 1:numel(template_library)
    d = stage15_compute_template_distance(sample_rec, template_library(i));
    if d < best_d
        best_d = d;
        best_idx = i;
    end
end

tpl = template_library(best_idx);

match_rec = struct();
match_rec.sample_id = sample_rec.sample_id;
match_rec.true_label = sample_rec.risk_label;
match_rec.matched_template_id = tpl.template_id;
match_rec.matched_label = tpl.risk_label;
match_rec.distance = best_d;
match_rec.is_correct = strcmp(sample_rec.risk_label, tpl.risk_label);
end
