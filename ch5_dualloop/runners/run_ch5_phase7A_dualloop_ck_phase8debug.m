function out = run_ch5_phase7A_dualloop_ck_phase8debug(case_name, mode_name)
%RUN_CH5_PHASE7A_DUALLOOP_CK_PHASE8DEBUG
% Minimal wrapper to run Phase7A CK with Phase08 candidate-level diff logging.
%
% case_name: 'ref128' | 'stress96'
% mode_name: 'ck_only' | 'ck_plus_fragility' | 'ck_plus_full_prior'

if nargin < 1 || isempty(case_name)
    case_name = 'ref128';
end
if nargin < 2 || isempty(mode_name)
    mode_name = 'ck_plus_fragility';
end

cfg = default_ch5_params(case_name);
cfg.ch5.continuous_prior_enable = ~strcmp(mode_name, 'ck_only');
cfg.ch5.continuous_prior_mode = mode_name;

debug_root = fullfile(pwd, 'outputs', 'cpt5', 'phase8_candidate_diff', char(case_name), char(mode_name));
if ~exist(debug_root, 'dir'); mkdir(debug_root); end

cfg.ch5.continuous_prior_debug_enable = true;
cfg.ch5.continuous_prior_debug_csv = fullfile(debug_root, 'candidate_diff.csv');

if exist(cfg.ch5.continuous_prior_debug_csv, 'file')
    delete(cfg.ch5.continuous_prior_debug_csv);
end

base_out = run_ch5_phase7A_dualloop_ck(cfg, true);

out = struct();
out.base_out = base_out;
out.debug_root = debug_root;
out.candidate_diff_csv = cfg.ch5.continuous_prior_debug_csv;

disp('=== Phase7A CK Phase08 debug ===');
disp(['[phase8-debug] result mat : ', base_out.mat_file]);
disp(['[phase8-debug] diff csv   : ', cfg.ch5.continuous_prior_debug_csv]);
end
