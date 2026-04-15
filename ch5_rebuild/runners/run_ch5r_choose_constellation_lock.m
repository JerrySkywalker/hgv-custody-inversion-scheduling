function out = run_ch5r_choose_constellation_lock(opts)
%RUN_CH5R_CHOOSE_CONSTELLATION_LOCK
% Phase 1 runner:
% - export Stage05-based constellation candidates
% - choose theta_star / theta_plus
% - write lock file
%
% Default is NON-interactive:
%   theta_star <- star_candidates(rank=1)
%   theta_plus <- plus_candidates(rank=1)

if nargin < 1 || isempty(opts)
    opts = struct();
end

opts = local_apply_defaults(opts);

cand = export_ch5r_constellation_candidates(struct( ...
    'top_k', opts.top_k, ...
    'pass_ratio_eq_one_only', opts.pass_ratio_eq_one_only, ...
    'exclude_same_as_star_default', true));

star_idx = min(opts.star_rank, height(cand.star_candidates));
plus_idx = min(opts.plus_rank, height(cand.plus_candidates));

if opts.interactive
    disp(' ')
    disp('=== choose theta_star candidate ===')
    disp(cand.star_candidates(:, {'rank','h_km','i_deg','P','T','F','Ns','DG','pass_ratio'}))
    tmp = input(sprintf('theta_star rank [default=%d]: ', star_idx), 's');
    if ~isempty(tmp)
        star_idx = str2double(tmp);
    end

    disp(' ')
    disp('=== choose theta_plus candidate ===')
    disp(cand.plus_candidates(:, {'rank','h_km','i_deg','P','T','F','Ns','DG','pass_ratio'}))
    tmp = input(sprintf('theta_plus rank [default=%d]: ', plus_idx), 's');
    if ~isempty(tmp)
        plus_idx = str2double(tmp);
    end
end

star_idx = max(1, min(star_idx, height(cand.star_candidates)));
plus_idx = max(1, min(plus_idx, height(cand.plus_candidates)));

theta_star = local_row_to_struct(cand.star_candidates(star_idx,:));
theta_plus = local_row_to_struct(cand.plus_candidates(plus_idx,:));

lock_data = struct();
lock_data.selection_mode = ternary(opts.interactive, 'interactive', 'noninteractive_default');
lock_data.selection_rule = 'stage05_topk_then_user_or_default_choice';
lock_data.source_stage05_feasible_csv = cand.stage05_feasible_csv;
lock_data.source_candidate_star_csv = cand.paths.star_csv;
lock_data.source_candidate_plus_csv = cand.paths.plus_csv;
lock_data.gamma_req = cand.bundle.gamma_req;
lock_data.target_case = cand.bundle.target_case;
lock_data.theta_star = theta_star;
lock_data.theta_plus = theta_plus;
lock_data.bootstrap_meta = cand.bundle.meta;
lock_data.stage04 = cand.bundle.stage04;
lock_data.stage05 = cand.bundle.stage05;
lock_data.consistency = cand.bundle.consistency;

lock_write = write_ch5r_constellation_lock(lock_data, struct('lock_name', opts.lock_name));

disp(' ')
disp('=== [ch5r:choose-lock] final selection ===')
disp('theta_star = ')
disp(theta_star)
disp('theta_plus = ')
disp(theta_plus)

out = struct();
out.ok = true;
out.candidates = cand;
out.lock_write = lock_write;
out.theta_star = theta_star;
out.theta_plus = theta_plus;
out.paths = lock_write.paths;
end

function opts = local_apply_defaults(opts)
if ~isfield(opts, 'interactive') || isempty(opts.interactive)
    opts.interactive = false;
end
if ~isfield(opts, 'top_k') || isempty(opts.top_k)
    opts.top_k = 5;
end
if ~isfield(opts, 'pass_ratio_eq_one_only') || isempty(opts.pass_ratio_eq_one_only)
    opts.pass_ratio_eq_one_only = true;
end
if ~isfield(opts, 'star_rank') || isempty(opts.star_rank)
    opts.star_rank = 1;
end
if ~isfield(opts, 'plus_rank') || isempty(opts.plus_rank)
    opts.plus_rank = 1;
end
if ~isfield(opts, 'lock_name') || isempty(opts.lock_name)
    opts.lock_name = 'ch5_constellation_lock';
end
end

function S = local_row_to_struct(Trow)
S = struct();
S.source = 'stage05_candidate_table';
S.h_km = Trow.h_km(1);
S.i_deg = Trow.i_deg(1);
S.P = Trow.P(1);
S.T = Trow.T(1);
S.F = Trow.F(1);
S.Ns = Trow.Ns(1);
S.DG = Trow.DG(1);
S.pass_ratio = Trow.pass_ratio(1);
end

function y = ternary(cond, a, b)
if cond
    y = a;
else
    y = b;
end
end
