function box = stage15_default_local_box()
%STAGE15_DEFAULT_LOCAL_BOX  Minimal local reference box schema.

box = struct();
box.box_name = 'default_local_box';
box.center_xy_km = [0, 0];
box.half_span_km = 1000;
box.velocity_ref_mps = 5000;
box.note = 'Stage15-A schema only. No scene coupling yet.';
end
