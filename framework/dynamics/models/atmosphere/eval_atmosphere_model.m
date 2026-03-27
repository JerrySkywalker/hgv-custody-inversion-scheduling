function [rho, a_s] = eval_atmosphere_model(h_m, target_cfg)
%EVAL_ATMOSPHERE_MODEL Evaluate configured atmosphere model.
%
%   [rho, a_s] = EVAL_ATMOSPHERE_MODEL(h_m, target_cfg)

if nargin < 2 || ~isstruct(target_cfg)
    error('eval_atmosphere_model:InvalidInput', ...
        'target_cfg must be a struct.');
end

model_name = 'us76';

if isfield(target_cfg, 'atmosphere') && isstruct(target_cfg.atmosphere)
    if isfield(target_cfg.atmosphere, 'model_name') && ~isempty(target_cfg.atmosphere.model_name)
        model_name = char(target_cfg.atmosphere.model_name);
    end
end

switch lower(model_name)
    case 'us76'
        [rho, a_s] = atmosphere_us76(h_m);

    otherwise
        error('eval_atmosphere_model:UnsupportedModel', ...
            'Unsupported atmosphere model: %s', model_name);
end
end
