function recipes = default_ch5b_trajectory_recipes(cfg)
%DEFAULT_CH5B_TRAJECTORY_RECIPES Manual trajectory recipes for Chapter 5.
%
% Each recipe defines one interpretable trajectory seed.
% Coordinates are specified in local ENU offsets relative to cfg.geo anchor.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5b_params();
end

recipes = struct([]);

% -------------------------------------------------------------------------
% N01 nominal baseline
% -------------------------------------------------------------------------
recipes(1).case_id = 'N01';
recipes(1).family = 'nominal';
recipes(1).subfamily = 'baseline';
recipes(1).x0_km = 0.0;
recipes(1).y0_km = 0.0;
recipes(1).h0_m = 80000.0;
recipes(1).heading_deg = 90.0;
recipes(1).heading_offset_deg = 0.0;
recipes(1).note = 'Nominal baseline';

% -------------------------------------------------------------------------
% N02 nominal shifted entry
% -------------------------------------------------------------------------
recipes(2).case_id = 'N02';
recipes(2).family = 'nominal';
recipes(2).subfamily = 'shifted_entry';
recipes(2).x0_km = 30.0;
recipes(2).y0_km = 15.0;
recipes(2).h0_m = 80000.0;
recipes(2).heading_deg = 90.0;
recipes(2).heading_offset_deg = 0.0;
recipes(2).note = 'Nominal entry shifted in ENU';

% -------------------------------------------------------------------------
% H01 heading perturbation
% -------------------------------------------------------------------------
recipes(3).case_id = 'H01_+00';
recipes(3).family = 'heading';
recipes(3).subfamily = 'heading_test';
recipes(3).x0_km = 0.0;
recipes(3).y0_km = 0.0;
recipes(3).h0_m = 80000.0;
recipes(3).heading_deg = 90.0;
recipes(3).heading_offset_deg = 0.0;
recipes(3).note = 'Heading family zero offset';

recipes(4).case_id = 'H01_+30';
recipes(4).family = 'heading';
recipes(4).subfamily = 'heading_test';
recipes(4).x0_km = 0.0;
recipes(4).y0_km = 0.0;
recipes(4).h0_m = 80000.0;
recipes(4).heading_deg = 120.0;
recipes(4).heading_offset_deg = 30.0;
recipes(4).note = 'Heading family +30 deg';

recipes(5).case_id = 'H01_-30';
recipes(5).family = 'heading';
recipes(5).subfamily = 'heading_test';
recipes(5).x0_km = 0.0;
recipes(5).y0_km = 0.0;
recipes(5).h0_m = 80000.0;
recipes(5).heading_deg = 60.0;
recipes(5).heading_offset_deg = -30.0;
recipes(5).note = 'Heading family -30 deg';

% -------------------------------------------------------------------------
% Critical representative
% -------------------------------------------------------------------------
recipes(6).case_id = 'C1_track_plane_aligned';
recipes(6).family = 'critical';
recipes(6).subfamily = 'track_plane_aligned';
recipes(6).x0_km = -20.0;
recipes(6).y0_km = 20.0;
recipes(6).h0_m = 78000.0;
recipes(6).heading_deg = 90.0;
recipes(6).heading_offset_deg = 0.0;
recipes(6).note = 'Critical C1 representative';

end
