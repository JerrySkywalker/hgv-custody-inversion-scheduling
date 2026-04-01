function rec = stage15_package_kernel_record_3d(box, xi, eta, kernel_type, kernel_struct)
%STAGE15_PACKAGE_KERNEL_RECORD_3D  Package one 3D local-kernel record.

rec = struct();
rec.box = box;
rec.xi = xi;
rec.eta = eta;
rec.kernel_type = kernel_type;
rec.kernel = kernel_struct;
end
