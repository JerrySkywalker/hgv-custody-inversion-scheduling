function box = stage15_default_local_box_3d()
%STAGE15_DEFAULT_LOCAL_BOX_3D  Minimal 3D local reference box schema.

box = struct();
box.box_name = 'default_local_box_3d';
box.center_xyz_km = [0, 0, 30];
box.half_span_km = 1000;
box.height_ref_km = 1000;
box.velocity_ref_mps = 5000;
box.note = 'Stage15-F schema3d only. No stage-cache coupling yet.';
end
