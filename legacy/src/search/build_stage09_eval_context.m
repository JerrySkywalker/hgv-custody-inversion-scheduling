function eval_ctx = build_stage09_eval_context(trajs_in, cfg, gamma_eff_scalar)
%BUILD_STAGE09_EVAL_CONTEXT Build shared Stage09 evaluation context.

    if nargin < 3 || isempty(gamma_eff_scalar)
        gamma_eff_scalar = 1.0;
    end

    cfg = stage09_prepare_cfg(cfg);

    nCase = numel(trajs_in);
    t_end_all = arrayfun(@(s) s.traj.t_s(end), trajs_in);
    t_max = max(t_end_all);
    dt = cfg.stage02.Ts_s;

    case_id = strings(nCase,1);
    family = strings(nCase,1);
    subfamily = strings(nCase,1);
    entry_id = nan(nCase,1);
    heading_offset_deg = nan(nCase,1);

    for k = 1:nCase
        case_id(k) = string(trajs_in(k).case.case_id);
        if isfield(trajs_in(k).case, 'family')
            family(k) = string(trajs_in(k).case.family);
        end
        if isfield(trajs_in(k).case, 'subfamily')
            subfamily(k) = string(trajs_in(k).case.subfamily);
        end
        if isfield(trajs_in(k).case, 'entry_id')
            entry_id(k) = trajs_in(k).case.entry_id;
        elseif isfield(trajs_in(k).case, 'entry_point_id')
            entry_id(k) = trajs_in(k).case.entry_point_id;
        end
        if isfield(trajs_in(k).case, 'heading_offset_deg')
            heading_offset_deg(k) = trajs_in(k).case.heading_offset_deg;
        end
    end

    eval_ctx = struct();
    eval_ctx.cfg = cfg;
    eval_ctx.gamma_eff_scalar = gamma_eff_scalar;
    eval_ctx.t_s_common = (0:dt:t_max).';
    eval_ctx.nCase = nCase;
    eval_ctx.case_id = case_id;
    eval_ctx.family = family;
    eval_ctx.subfamily = subfamily;
    eval_ctx.entry_id = entry_id;
    eval_ctx.heading_offset_deg = heading_offset_deg;
end
