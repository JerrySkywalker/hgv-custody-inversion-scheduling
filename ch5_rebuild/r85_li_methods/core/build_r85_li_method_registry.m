function registry = build_r85_li_method_registry(cfg)
%BUILD_R85_LI_METHOD_REGISTRY
% Build Li-style mode/selection interface registry under current ch5r params.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params(true);
    cfg = default_ch5r_r85_li_methods_params(cfg);
end

registry = struct();

registry.meta = struct();
registry.meta.family = cfg.r85.method_family;
registry.meta.scene_policy = cfg.r85.scene_policy;
registry.meta.note = ['R8.5a interface registry only. ', ...
    'Methods are bound to current ch5r experiment parameters, not Li original scene.'];

registry.modes = struct([]);

registry.modes(1).name = 'stare';
registry.modes(1).entry = 'li_mode_stare';
registry.modes(1).kind = 'tracking_mode';
registry.modes(1).description = 'Inertially fixed pointing mode';

registry.modes(2).name = 'track_rate';
registry.modes(2).entry = 'li_mode_trackrate';
registry.modes(2).kind = 'tracking_mode';
registry.modes(2).description = 'Continuously target-following pointing mode';

registry.modes(3).name = 'relay';
registry.modes(3).entry = 'li_mode_relay';
registry.modes(3).kind = 'tracking_mode';
registry.modes(3).description = 'Interval-based relay tracking mode';

registry.selection = struct([]);

registry.selection(1).name = 'pta';
registry.selection(1).entry = 'li_score_pta';
registry.selection(1).kind = 'relay_selection';
registry.selection(1).objective = 'maximize predicted tracking arc length';

registry.selection(2).name = 'cn';
registry.selection(2).entry = 'li_score_cn';
registry.selection(2).kind = 'relay_selection';
registry.selection(2).objective = 'minimize condition number of observability matrix';

registry.selection(3).name = 'detY_rim';
registry.selection(3).entry = 'li_score_detY_rim';
registry.selection(3).kind = 'relay_selection';
registry.selection(3).objective = 'maximize determinant of final information matrix via RIM';

registry.selection(4).name = 'detY_fast';
registry.selection(4).entry = 'li_score_detY_fast';
registry.selection(4).kind = 'relay_selection';
registry.selection(4).objective = 'maximize determinant of final information matrix via fast approximation';

registry.resource = cfg.r85.resource;

end
