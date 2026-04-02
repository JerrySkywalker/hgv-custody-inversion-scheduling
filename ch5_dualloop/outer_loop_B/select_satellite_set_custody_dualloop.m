function selected_ids = select_satellite_set_custody_dualloop(caseData, k, prev_ids, mode, cfg)
%SELECT_SATELLITE_SET_CUSTODY_DUALLOOP
% P-Back-1 wrapper.
selected_ids = select_satellite_set_custody_dualloop_impl(caseData, k, prev_ids, mode, cfg);
end
