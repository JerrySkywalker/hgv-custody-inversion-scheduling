function fsm = ch5r_run_custody_fsm_posthoc(vr, mg, ch5case, diag_cfg)
%CH5R_RUN_CUSTODY_FSM_POSTHOC
% Shell-aligned paper-consistent FSM:
% - main variables: Vr, MG
% - if Vr unavailable, fallback to MG-only mode
%
% States:
%   0 = SC
%   1 = DC
%   2 = LoC

Nt = numel(ch5case.t_s);

fsm = struct();
fsm.state = nan(Nt,1);
fsm.valid = false(Nt,1);
fsm.V_warn = nan(Nt,1);
fsm.V_req  = nan(Nt,1);
fsm.eps_warn = nan(Nt,1);
fsm.eps_req  = nan(Nt,1);
fsm.mode = 'MG_only';

if isfield(vr, 'valid') && any(vr.valid)
    fsm.mode = 'Vr_MG';
end

eps_req = ch5case.gamma_req;
eps_warn = diag_cfg.beta_eps * eps_req;

if strcmp(fsm.mode, 'Vr_MG')
    v_seed = vr.value(vr.valid);
    init_Vbar = median(v_seed(1:min(numel(v_seed), 60)), 'omitnan');
    init_Vmad = mad(v_seed(1:min(numel(v_seed), 60)), 1);
    if ~isfinite(init_Vmad) || init_Vmad <= 0
        init_Vmad = std(v_seed(1:min(numel(v_seed), 60)), 'omitnan');
    end
    if ~isfinite(init_Vmad) || init_Vmad <= 0
        init_Vmad = 1e-3;
    end

    st.Vbar = init_Vbar;
    st.Vmad = init_Vmad;
else
    st = struct();
end

for k = 1:Nt
    mgk = mg.value(k);
    vrk = nan;
    if strcmp(fsm.mode, 'Vr_MG') && vr.valid(k)
        vrk = vr.value(k);
    end

    if ~mg.valid(k)
        continue;
    end

    fsm.valid(k) = true;
    fsm.eps_req(k) = eps_req;
    fsm.eps_warn(k) = eps_warn;

    if strcmp(fsm.mode, 'Vr_MG')
        if isfinite(vrk) && isfinite(mgk) && (mgk >= eps_req)
            st.Vmad = (1-diag_cfg.alpha_mad) * st.Vmad + diag_cfg.alpha_mad * abs(vrk - st.Vbar);
            st.Vbar = (1-diag_cfg.alpha_base) * st.Vbar + diag_cfg.alpha_base * vrk;
        end

        V_warn = st.Vbar + diag_cfg.kV * max(st.Vmad, diag_cfg.mad_floor);
        V_req  = st.Vbar + 5.0 * max(st.Vmad, diag_cfg.mad_floor);

        fsm.V_warn(k) = V_warn;
        fsm.V_req(k)  = V_req;

        if isfinite(vrk) && (vrk > V_req)
            fsm.state(k) = 2;
        elseif mgk < eps_req
            fsm.state(k) = 2;
        elseif (isfinite(vrk) && (vrk > V_warn)) || (mgk < eps_warn)
            fsm.state(k) = 1;
        else
            fsm.state(k) = 0;
        end
    else
        if mgk < eps_req
            fsm.state(k) = 2;
        elseif mgk < eps_warn
            fsm.state(k) = 1;
        else
            fsm.state(k) = 0;
        end
    end
end

fsm.state_name = strings(Nt,1);
fsm.state_name(fsm.state == 0) = "SC";
fsm.state_name(fsm.state == 1) = "DC";
fsm.state_name(fsm.state == 2) = "LoC";

fsm.summary = struct();
fsm.summary.sc_steps  = sum(fsm.state == 0, 'omitnan');
fsm.summary.dc_steps  = sum(fsm.state == 1, 'omitnan');
fsm.summary.loc_steps = sum(fsm.state == 2, 'omitnan');
fsm.summary.sc_ratio  = fsm.summary.sc_steps  / max(sum(fsm.valid),1);
fsm.summary.dc_ratio  = fsm.summary.dc_steps  / max(sum(fsm.valid),1);
fsm.summary.loc_ratio = fsm.summary.loc_steps / max(sum(fsm.valid),1);
end
