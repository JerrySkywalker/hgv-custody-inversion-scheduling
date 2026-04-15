clear functions
rehash
startup('force', true)

addpath(fullfile(pwd, 'ch5_rebuild'));
addpath(fullfile(pwd, 'ch5_rebuild', 'params'));
addpath(fullfile(pwd, 'ch5_rebuild', 'scenario'));

which resolve_ch5r_case_list

% direct call
out1 = resolve_ch5r_case_list(struct('case_set','smoke','case_ids',{{'N01','H04_+30'}}));
assert(numel(out1.case_ids) == 2);
assert(any(strcmp(out1.case_ids, 'N01')));
assert(any(strcmp(out1.case_ids, 'H04_+30')));

% re-entry through local function context
out2 = local_call_resolver();
assert(numel(out2.case_ids) == 2);
assert(any(strcmp(out2.case_ids, 'N01')));
assert(any(strcmp(out2.case_ids, 'H04_+30')));

disp('=== manual_ch5_case_list_reentry_smoke passed ===')
disp(out1.case_ids)
disp(out2.case_ids)

function out = local_call_resolver()
out = resolve_ch5r_case_list(struct('case_set','smoke','case_ids',{{'N01','H04_+30'}}));
end
