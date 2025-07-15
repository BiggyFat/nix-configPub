# nixos/modules/python-envs.nix
{ pkgs }:
let
  open3dPkg = pkgs.python3Packages.open3d or pkgs.open3d;
in
{
  cameraServerEnv = pkgs.python3.withPackages (ps: [
    ps.spyder-kernels
    ps.numpy
    ps.requests
    ps.dill
    ps.pycurl

    open3dPkg

    ps.pyrealsense2
    ps.pillow
    ps.pyttsx3
    ps.pylibdmtx
    ps.zxing-cpp
    ps.opencv4
    ps.pyudev
    ps.natsort
    ps.fastapi
    ps.uvicorn
    ps.gunicorn
    ps.pyscard
  ]);
}
