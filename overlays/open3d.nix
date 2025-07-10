# overlays/open3d.nix
self: prev:
let
  pname    = "open3d";
  version  = "0.19.0";
  pyTag    = "cp311";
  platTag  = "manylinux_2_31_x86_64";

  open3dDrv = prev.python3Packages.buildPythonPackage rec {
    inherit pname version;
    format = "wheel";

    src = prev.python3Packages.fetchPypi {
  inherit pname version format;
  python = pyTag; abi = pyTag; dist = pyTag; platform = platTag;
  sha256 = "sha256-Z4AXOS9sxkoZ2Dr+tTKf/oGWiT3iQy9MJY6qqBlCG7U=";
};

    nativeBuildInputs = [ prev.autoPatchelfHook ];
    autoPatchelfIgnoreMissingDeps = [
  # CUDA/Torch déjà listés
  "libtorch_cuda_cpp.so" "libtorch_cuda_cu.so"
  "libtorch_cuda.so"     "libc10_cuda.so"

  # Torch-CPU qu’il réclamait
  "libtorch_cpu.so" "libtorch.so" "libc10.so"

  # CUDA runtime (wheel l’inclut par mégarde)
  "libcudart.so.12"
];

    buildInputs = with prev; [
      stdenv.cc.cc.lib libusb.out libGL xorg.libX11 xorg.libXfixes mesa
    ];

    propagatedBuildInputs = with prev.python3Packages; [
      numpy scikit-learn matplotlib dash ipywidgets
      addict configargparse pyyaml pandas tqdm pyquaternion
    ];

    postInstall = ''
  # Symlink LLVM (inchangé)
  ln -s ${prev.llvmPackages.llvm.lib}/lib/libLLVM-${prev.llvmPackages.llvm.version}.so \
        $out/lib/libLLVM-10.so.1 || true

  # On supprime les extensions Torch (CPU & CUDA)
  rm -f $out/lib/python*/site-packages/open3d/*/open3d_torch_ops.so || true
  rm -f $out/lib/python*/site-packages/open3d/**/lib{GL,EGL}.so.1   || true
  rm -f $out/lib/python*/site-packages/open3d/**/*swrast_dri.so     || true
'';

    meta = with prev.lib; {
      description = "Modern 3D data processing library";
      homepage    = "https://www.open3d.org/";
      license     = licenses.mit;
      platforms   = platforms.linux;
    };
  };
in {
  # exposé au top-level pour commodité
  open3d = open3dDrv;

  python3Packages = prev.python3Packages // { open3d = open3dDrv; };
}

