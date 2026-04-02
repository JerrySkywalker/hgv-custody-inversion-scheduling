function out = run_ch5_phase8_prior_integration(cfg, verbose)
%RUN_CH5_PHASE8_PRIOR_INTEGRATION
% P-Back-1 third cut
% Formal Phase8 integration using:
%   C
%   CK
%   CK-ref-only
%   CK-prior-balanced
%
% Notes:
%   - baseline default behavior is preserved
%   - CK-ref-only isolates reference-selection effect
%   - CK-prior-balanced uses balanced library cap but relaxed filter topK=8
%     to avoid over-forcing candidate pruning at this integration stage

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params('ref128');
end
if nargin < 2
    verbose = true;
end

scene_preset = cfg.ch5.scene_preset;
out_root = fullfile(pwd, 'outputs', 'cpt5', 'phase8');
fig_dir = fullfile(out_root, 'figs');
tbl_dir = fullfile(out_root, 'tables');
log_dir = fullfile(out_root, 'logs');
mat_dir = fullfile(out_root, 'mats');
if ~exist(fig_dir, 'dir'); mkdir(fig_dir); end
if ~exist(tbl_dir, 'dir'); mkdir(tbl_dir); end
if ~exist(log_dir, 'dir'); mkdir(log_dir); end
if ~exist(mat_dir, 'dir'); mkdir(mat_dir); end

% ------------------------------------------------
% Build a representative prior library
% ------------------------------------------------
cfg_bal = apply_ws5_balanced_template_defaults(cfg);
caseData = build_ch5_case(cfg_bal);

[k_ref, visible_ids] = local_find_reference_snapshot(caseData);
pair_cap = cfg_bal.ch5.library_pair_cap;

pair_sets = nchoosek(visible_ids(:).', 2);
pair_sets = pair_sets(1:min(pair_cap, size(pair_sets,1)), :);
pair_feats = extract_candidate_local_features(caseData, k_ref, pair_sets);
prior_library = build_reference_prior_library(pair_feats);

% ------------------------------------------------
% A) baseline CK branch
% ------------------------------------------------
cfg_base = cfg;
cfg_base.ch5.prior_enable = false;
cfg_base.ch5.template_filter_enable = false;

out_base = run_ch5_phase7A_dualloop_ck(cfg_base, true);
S_base = load(out_base.mat_file);

% ------------------------------------------------
% B) CK-ref-only
% ------------------------------------------------
cfg_ref = apply_ws5_balanced_template_defaults(cfg);
cfg_ref.ch5.prior_enable = true;
cfg_ref.ch5.template_filter_enable = false;
cfg_ref.ch5.prior_library = prior_library;

out_ref = run_ch5_phase7A_dualloop_ck(cfg_ref, true);
S_ref = load(out_ref.mat_file);

% ------------------------------------------------
% C) CK-prior-balanced (relaxed topK for integration)
% ------------------------------------------------
cfg_prior = apply_ws5_balanced_template_defaults(cfg);
cfg_prior.ch5.prior_enable = true;
cfg_prior.ch5.template_filter_enable = true;
cfg_prior.ch5.prior_library = prior_library;
cfg_prior.ch5.template_filter_topk = 8;

out_prior = run_ch5_phase7A_dualloop_ck(cfg_prior, true);
S_prior = load(out_prior.mat_file);

methods = struct([]);

methods(1).name = 'C';
methods(1).q_worst_window = local_get_qworst_window(S_base.custodyC);
methods(1).phi_mean = S_base.custodyC.phi_mean;
methods(1).outage_ratio = S_base.custodyC.outage_ratio;
methods(1).longest_outage_steps = S_base.custodyC.longest_outage_steps;
methods(1).mean_rmse = S_base.trackingStatsC.mean_rmse;
methods(1).switch_count = local_count_switches(S_base, 'trackingC');

methods(2).name = 'CK';
methods(2).q_worst_window = local_get_qworst_window(S_base.custodyCK);
methods(2).phi_mean = S_base.custodyCK.phi_mean;
methods(2).outage_ratio = S_base.custodyCK.outage_ratio;
methods(2).longest_outage_steps = S_base.custodyCK.longest_outage_steps;
methods(2).mean_rmse = S_base.trackingStatsCK.mean_rmse;
methods(2).switch_count = local_count_switches(S_base, 'trackingCK');

methods(3).name = 'CK-ref-only';
methods(3).q_worst_window = local_get_qworst_window(S_ref.custodyCK);
methods(3).phi_mean = S_ref.custodyCK.phi_mean;
methods(3).outage_ratio = S_ref.custodyCK.outage_ratio;
methods(3).longest_outage_steps = S_ref.custodyCK.longest_outage_steps;
methods(3).mean_rmse = S_ref.trackingStatsCK.mean_rmse;
methods(3).switch_count = local_count_switches(S_ref, 'trackingCK');

methods(4).name = 'CK-prior-balanced';
methods(4).q_worst_window = local_get_qworst_window(S_prior.custodyCK);
methods(4).phi_mean = S_prior.custodyCK.phi_mean;
methods(4).outage_ratio = S_prior.custodyCK.outage_ratio;
methods(4).longest_outage_steps = S_prior.custodyCK.longest_outage_steps;
methods(4).mean_rmse = S_prior.trackingStatsCK.mean_rmse;
methods(4).switch_count = local_count_switches(S_prior, 'trackingCK');

fig_path = fullfile(fig_dir, ['phase8_prior_summary_', scene_preset, '.png']);
local_plot_phase8_summary(methods, scene_preset, fig_path);

txt_path = fullfile(tbl_dir, ['phase8_prior_summary_', scene_preset, '.txt']);
local_write_summary(txt_path, scene_preset, prior_library, k_ref, visible_ids, methods);

log_path = fullfile(log_dir, ['phase8_prior_integration_log_', scene_preset, '.txt']);
local_write_log(log_path, scene_preset, prior_library, k_ref, methods);

mat_path = fullfile(mat_dir, ['phase8_prior_integration_', scene_preset, '.mat']);
save(mat_path, 'scene_preset', 'prior_library', 'k_ref', 'visible_ids', ...
    'cfg_base', 'cfg_ref', 'cfg_prior', ...
    'out_base', 'out_ref', 'out_prior', 'methods');

if verbose
    disp('=== Chapter 5 Phase 8 Prior Integration Summary ===')
    disp(['scene_preset = ', scene_preset])
    disp(['prior_library_size = ', num2str(numel(prior_library.templates))])
    disp(struct2table(methods))
    disp(['[phase8] fig  : ', fig_path])
    disp(['[phase8] text : ', txt_path])
    disp(['[phase8] log  : ', log_path])
    disp(['[phase8] mat  : ', mat_path])
end

out = struct();
out.fig_file = fig_path;
out.text_file = txt_path;
out.log_file = log_path;
out.mat_file = mat_path;
end

function [k_ref, visible_ids] = local_find_reference_snapshot(caseData)
k_ref = [];
visible_ids = [];
Nt = caseData.time.num_steps;

for k = 1:Nt
    ids = find(caseData.candidates.visible_mask(k,:) > 0);
    if numel(ids) >= 2
        k_ref = k;
        visible_ids = ids(:).';
        return
    end
end

error('No valid reference snapshot with at least two visible satellites.');
end

function q = local_get_qworst_window(custody)
if isfield(custody, 'q_worst_window')
    q = custody.q_worst_window;
else
    q = custody.q_worst;
end
end

function n = local_count_switches(S, field_name)
n = NaN;
if isfield(S, field_name)
    T = S.(field_name);
    if isstruct(T) && isfield(T, 'selected_sets')
        ss = T.selected_sets;
        c = 0;
        for i = 2:numel(ss)
            c = c + ~isequal(ss{i-1}, ss{i});
        end
        n = c;
    end
end
end

function local_plot_phase8_summary(methods, scene_preset, fig_path)
names = {methods.name};
qw = [methods.q_worst_window];
pm = [methods.phi_mean];
outage = [methods.outage_ratio];
longest = [methods.longest_outage_steps];
rmse = [methods.mean_rmse];
sw = [methods.switch_count];

f = figure('Visible', 'off');
tiledlayout(2,3);

nexttile; bar(qw); set(gca,'XTickLabel',names); title('q worst window','Interpreter','none'); grid on
nexttile; bar(pm); set(gca,'XTickLabel',names); title('phi mean','Interpreter','none'); grid on
nexttile; bar(outage); set(gca,'XTickLabel',names); title('outage ratio','Interpreter','none'); grid on
nexttile; bar(longest); set(gca,'XTickLabel',names); title('longest outage steps','Interpreter','none'); grid on
nexttile; bar(rmse); set(gca,'XTickLabel',names); title('mean rmse','Interpreter','none'); grid on
nexttile; bar(sw); set(gca,'XTickLabel',names); title('switch count','Interpreter','none'); grid on

sgtitle(['Phase8 prior integration - ', scene_preset], 'Interpreter', 'none');
saveas(f, fig_path);
close(f);
end

function local_write_summary(pathStr, scene_preset, prior_library, k_ref, visible_ids, methods)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open summary file.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=== Chapter 5 Phase 8 Prior Integration Summary ===\n');
fprintf(fid, 'scene_preset = %s\n', scene_preset);
fprintf(fid, 'prior_library_size = %d\n', numel(prior_library.templates));
fprintf(fid, 'reference_snapshot_k = %d\n', k_ref);
fprintf(fid, 'reference_visible_ids = %s\n\n', local_vec_to_str(visible_ids));

for i = 1:numel(methods)
    m = methods(i);
    fprintf(fid, '--- %s ---\n', m.name);
    fprintf(fid, 'q_worst_window = %.6f\n', m.q_worst_window);
    fprintf(fid, 'phi_mean = %.6f\n', m.phi_mean);
    fprintf(fid, 'outage_ratio = %.6f\n', m.outage_ratio);
    fprintf(fid, 'longest_outage_steps = %d\n', m.longest_outage_steps);
    fprintf(fid, 'mean_rmse = %.6f\n', m.mean_rmse);
    fprintf(fid, 'switch_count = %.6f\n\n', m.switch_count);
end
end

function local_write_log(pathStr, scene_preset, prior_library, k_ref, methods)
fid = fopen(pathStr, 'w');
assert(fid >= 0, 'Failed to open log file.');
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '[INFO] phase8 prior integration\n');
fprintf(fid, '[INFO] scene_preset = %s\n', scene_preset);
fprintf(fid, '[INFO] prior_library_size = %d\n', numel(prior_library.templates));
fprintf(fid, '[INFO] reference_snapshot_k = %d\n', k_ref);
for i = 1:numel(methods)
    fprintf(fid, '[INFO] %s q_worst_window = %.6f\n', methods(i).name, methods(i).q_worst_window);
end
end

function s = local_vec_to_str(v)
if isempty(v)
    s = '[]';
    return
end
v = v(:).';
parts = arrayfun(@num2str, v, 'UniformOutput', false);
s = ['[', strjoin(parts, ' '), ']'];
end
