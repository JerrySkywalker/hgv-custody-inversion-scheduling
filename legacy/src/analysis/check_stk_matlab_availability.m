function info = check_stk_matlab_availability(cfg)
%CHECK_STK_MATLAB_AVAILABILITY Check STK-MATLAB COM availability.

if nargin < 1 || isempty(cfg)
    cfg = shared_scenario_common_defaults();
end

progids = string(cfg.shared_scenarios.stk.progid_candidates);
available_progid = "";

for k = 1:numel(progids)
    progid = progids(k);
    try
        winqueryreg('HKEY_CLASSES_ROOT', char(progid));
        available_progid = progid;
        break;
    catch
    end
end

info = struct();
info.is_windows = ispc;
info.has_actxserver = (exist('actxserver', 'file') == 2 || exist('actxserver', 'builtin') == 5);
info.available_progid = available_progid;
info.is_available = info.is_windows && info.has_actxserver && strlength(available_progid) > 0;

if info.is_available
    info.message = "STK-MATLAB COM interface is available.";
else
    info.message = ['shared_scenarios SS2 requires STK-MATLAB COM support. ' ...
        'Checked progids: ' char(strjoin(progids, ", ")) '.'];
end
end
