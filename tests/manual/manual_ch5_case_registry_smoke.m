clear functions
rehash
startup('force', true)

addpath(fullfile(pwd, 'ch5_rebuild'));
addpath(fullfile(pwd, 'ch5_rebuild', 'params'));
addpath(fullfile(pwd, 'ch5_rebuild', 'scenario'));

which default_ch5r_suite_params
which build_ch5r_case_registry
which resolve_ch5r_case_list
which apply_ch5r_case_override

suite = default_ch5r_suite_params();
registry = build_ch5r_case_registry();

assert(height(registry) == suite.expected_counts.total);
assert(sum(strcmp(registry.family, 'nominal')) == suite.expected_counts.nominal);
assert(sum(strcmp(registry.family, 'heading')) == suite.expected_counts.heading);
assert(sum(strcmp(registry.family, 'critical')) == suite.expected_counts.critical);

assert(any(strcmp(registry.case_id, 'N01')));
assert(any(strcmp(registry.case_id, 'H01_+00')));
assert(any(strcmp(registry.case_id, 'C1_track_plane_aligned')));

smoke = resolve_ch5r_case_list(struct('case_set', 'smoke'));
paper = resolve_ch5r_case_list(struct('case_set', 'paper'));
fullset = resolve_ch5r_case_list(struct('case_set', 'full'));
heading_only = resolve_ch5r_case_list(struct('case_set', 'full', 'family', 'heading'));

assert(~isempty(smoke.case_ids));
assert(~isempty(paper.case_ids));
assert(numel(fullset.case_ids) == 74);
assert(all(startsWith(heading_only.case_ids, 'H')));

cfg = default_ch5r_params(true);
cfg2 = apply_ch5r_case_override(cfg, 'H04_+30');

assert(strcmp(cfg2.ch5r.bootstrap.force_case_id, 'H04_+30'));
assert(strcmp(cfg2.ch5r.bootstrap.applied_case_override, 'H04_+30'));
assert(strcmp(cfg2.ch5r.target_case.default_case_id, 'H04_+30'));
assert(strcmp(cfg2.ch5r.target_case.case_id, 'H04_+30'));
assert(strcmp(cfg2.ch5r.target_case.family, 'heading'));
assert(strcmp(cfg2.ch5r.target_case.source, 'apply_ch5r_case_override'));

disp('=== Phase2A case registry smoke passed ===')
disp(smoke.case_ids)
disp(paper.case_ids)
