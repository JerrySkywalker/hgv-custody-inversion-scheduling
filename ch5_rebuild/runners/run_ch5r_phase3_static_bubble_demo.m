function out = run_ch5r_phase3_static_bubble_demo()
%RUN_CH5R_PHASE3_STATIC_BUBBLE_DEMO
% Real R3 rewrite:
% - one fixed real constellation
% - real HGV truth from Stage02
% - one fixed double-satellite pair for the whole horizon

cfg = default_ch5r_params(true);
cfg.ch5r.window_length_s = 60;

ch5case = build_ch5r_case(cfg);

static_pair = select_satellite_set_static(cfg, ch5case.truth, ch5case.satbank, ch5case.candidates);

Nt = numel(ch5case.t_s);
selection_trace = cell(Nt,1);

sigma_angle_rad = cfg.ch5r.sensor_profile.sigma_angle_rad;

for k = 1:Nt
    pair_list = ch5case.candidates.pair_bank{k};

    if isempty(pair_list)
        selection_trace{k} = struct( ...
            'k', k, ...
            'time_s', ch5case.t_s(k), ...
            'pair', [], ...
            'J_pair', zeros(3,3), ...
            'score', -inf, ...
            'prev_pair', static_pair, ...
            'switch_flag', false, ...
            'name', 'static_real_pair_empty');
        continue;
    end

    hit = ismember(pair_list, static_pair, 'rows');
    if any(hit)
        pair = static_pair;
        r_tgt = ch5case.truth.r_eci_km(k, :);
        r_sat_pair = [
            squeeze(ch5case.satbank.r_eci_km(k, :, pair(1)));
            squeeze(ch5case.satbank.r_eci_km(k, :, pair(2)))
        ];
        J = compute_bearing_fim_pair(r_tgt, r_sat_pair, sigma_angle_rad);

        selection_trace{k} = struct( ...
            'k', k, ...
            'time_s', ch5case.t_s(k), ...
            'pair', pair, ...
            'J_pair', J, ...
            'score', trace(J), ...
            'prev_pair', static_pair, ...
            'switch_flag', false, ...
            'name', 'static_real_pair');
    else
        % If the fixed pair is not visible at this step, no observation is available.
        selection_trace{k} = struct( ...
            'k', k, ...
            'time_s', ch5case.t_s(k), ...
            'pair', [], ...
            'J_pair', zeros(3,3), ...
            'score', -inf, ...
            'prev_pair', static_pair, ...
            'switch_flag', false, ...
            'name', 'static_real_pair_not_visible');
    end
end

wininfo = eval_window_information(ch5case, selection_trace);

bubble = struct();
bubble.t_s = wininfo.t_s;
bubble.gamma_req = ch5case.gamma_req;
bubble.lambda_min = wininfo.lambda_min;
bubble.is_bubble = wininfo.lambda_min < ch5case.gamma_req;
bubble.bubble_depth = max(0, ch5case.gamma_req - wininfo.lambda_min);

bubble_steps = nnz(bubble.is_bubble);
bubble_time_s = bubble_steps * ch5case.dt;
max_bubble_depth = max(bubble.bubble_depth);
switch_count = 0;
resource_score = 2;

out_dir = fullfile(cfg.ch5r.output_root, 'phaseR3_static_hold_real');
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

stamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
mat_file = fullfile(out_dir, ['phaseR3_static_hold_real_' stamp '.mat']);

save(mat_file, 'cfg', 'ch5case', 'static_pair', 'selection_trace', 'wininfo', 'bubble');

disp(' ')
disp('=== [ch5r:R3-real] static-hold baseline summary ===')
disp(['case id              : ' ch5case.target_case.case_id])
disp(['fixed constellation  : theta_star'])
disp(['Ns                   : ' num2str(ch5case.satbank.Ns)])
disp(['fixed static pair    : [' num2str(static_pair(1)) ', ' num2str(static_pair(2)) ']'])
disp(['tracking resource    : double-satellite'])
disp(['bubble steps         : ' num2str(bubble_steps)])
disp(['bubble time (s)      : ' num2str(bubble_time_s, '%.6f')])
disp(['max bubble depth     : ' num2str(max_bubble_depth, '%.12g')])
disp(['switch count         : ' num2str(switch_count)])
disp(['resource score       : ' num2str(resource_score)])
disp(['mat file             : ' mat_file])

out = struct();
out.cfg = cfg;
out.case = ch5case;
out.static_pair = static_pair;
out.selection_trace = selection_trace;
out.wininfo = wininfo;
out.bubble = bubble;
out.result = struct( ...
    'bubble_steps', bubble_steps, ...
    'bubble_time_s', bubble_time_s, ...
    'max_bubble_depth', max_bubble_depth, ...
    'switch_count', switch_count, ...
    'resource_score', resource_score);
out.paths = struct('mat_file', mat_file, 'output_dir', out_dir);
out.ok = true;
end
