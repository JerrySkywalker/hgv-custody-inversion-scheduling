function dX = eval_dynamics_model(t, X, target_cfg)
%EVAL_DYNAMICS_MODEL Evaluate configured target dynamics model.
%
%   dX = EVAL_DYNAMICS_MODEL(t, X, target_cfg)

if nargin < 3 || ~isstruct(target_cfg)
    error('eval_dynamics_model:InvalidInput', ...
        'target_cfg must be a struct.');
end

model_name = 'hgv_vtc';

if isfield(target_cfg, 'model') && isstruct(target_cfg.model)
    if isfield(target_cfg.model, 'dynamics') && ~isempty(target_cfg.model.dynamics)
        model_name = char(target_cfg.model.dynamics);
    end
end

switch lower(model_name)
    case 'hgv_vtc'
        dX = hgv_vtc_dynamics(t, X, target_cfg);

    otherwise
        error('eval_dynamics_model:UnsupportedModel', ...
            'Unsupported dynamics model: %s', model_name);
end
end
