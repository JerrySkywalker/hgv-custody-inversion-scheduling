function out = stage14_joint_phase_orientation_postprocess(raw_in, cfg)
%STAGE14_JOINT_PHASE_ORIENTATION_POSTPROCESS
% Stage14.4 formal wrapper for B2 / B2-dual postprocess based on the
% frozen A1 legacy postprocess asset.

    if nargin < 1 || isempty(raw_in)
        error('raw_in is required.');
    end
    if nargin < 2 || isempty(cfg)
        cfg = default_params();
    end

    legacy_name = local_resolve_legacy_postprocess();
    assert(~isempty(legacy_name), ...
        'Stage14.4 wrapper cannot find legacy A1 postprocess function.');

    out = feval(legacy_name, raw_in.raw, cfg);

    fprintf('\n=== Stage14.4 B2/B2-dual Postprocess ===\n');
    fprintf('legacy source    : %s\n', legacy_name);
    if isfield(out, 'files')
        disp(out.files)
    end
end

function name = local_resolve_legacy_postprocess()
    candidates = { ...
        'manual_smoke_stage14_F_RAAN_postprocess_A1_legacy_prepivot_20260329', ...
        'manual_smoke_stage14_F_RAAN_postprocess_A1' ...
        };
    name = "";
    for k = 1:numel(candidates)
        if exist(candidates{k}, 'file') == 2
            name = string(candidates{k});
            return;
        end
    end
end
