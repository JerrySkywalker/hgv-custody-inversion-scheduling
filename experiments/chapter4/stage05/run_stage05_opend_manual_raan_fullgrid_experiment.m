function res = run_stage05_opend_manual_raan_fullgrid_experiment(varargin)
%RUN_STAGE05_OPEND_MANUAL_RAAN_FULLGRID_EXPERIMENT Run Stage05/OpenD full-grid manual-RAAN experiment.

spec = make_stage05_opend_manual_raan_fullgrid_spec(varargin{:});
res = run_search_experiment(spec);
end
