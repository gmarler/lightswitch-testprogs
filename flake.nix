{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };
  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ]
      (system:
        let
          overlays = [ (import rust-overlay) ];
          pkgs = import nixpkgs {
            inherit system overlays;
          };
          test-f77-progs = pkgs.stdenv.mkDerivation {
            dontStrip = true;
            name = "build-test-f77-prog";
            src = ./.;
            buildPhase = ''
              cd src/

              make
            '';
            installPhase = ''
              mkdir -p $out/bin

              cp basic_stack_f77-O* $out/bin
            '';

            buildInputs = [
              pkgs.gfortran11
            ];
          };
          test-cpp-progs = pkgs.stdenv.mkDerivation {
            name = "build-test-cpp-prog";
            src = ./.;
            buildPhase = ''
              		    cd src/

                            	    gcc -O0 main.cpp -o main_cpp_gcc_O0
                            	    gcc -O1 main.cpp -o main_cpp_gcc_O1
                            	    gcc -O2 main.cpp -o main_cpp_gcc_O2
                            	    gcc -O3 main.cpp -o main_cpp_gcc_O3
                            	    # In O2 and O3, GCC might swap function calls with jumps.
                                  gcc per-function-optimizations.cpp -o per-function-optimizations

                            	    clang -O0 main.cpp -o main_cpp_clang_O0
                            	    clang -O1 main.cpp -o main_cpp_clang_O1
                            	    clang -O2 main.cpp -o main_cpp_clang_O2
                            	    clang -O3 main.cpp -o main_cpp_clang_O3

                            	    clang -O3 -fno-omit-frame-pointer main.cpp -o main_cpp_clang_no_omit_fp_O3
            '';
            installPhase = ''
              mkdir -p $out/bin

              cp main_cpp_gcc_O0 $out/bin
              cp main_cpp_gcc_O1 $out/bin
              cp main_cpp_gcc_O2 $out/bin
              cp main_cpp_gcc_O3 $out/bin
              cp per-function-optimizations $out/bin

              cp main_cpp_clang_O0 $out/bin
              cp main_cpp_clang_O1 $out/bin
              cp main_cpp_clang_O2 $out/bin
              cp main_cpp_clang_O3 $out/bin

              cp main_cpp_clang_no_omit_fp_O3 $out/bin

            '';
            buildInputs = [
              pkgs.gcc
              pkgs.clang
            ];
          };

          test-static-glibc-cpp-progs = pkgs.stdenv.mkDerivation {
            name = "build-test-static-glibc-cpp-prog";
            src = ./.;
            buildPhase = ''
              	      cd src/
                            clang -O3 -static main.cpp -o main_cpp_clang_static_glibc_O3
            '';
            installPhase = ''
              mkdir -p $out/bin
              cp main_cpp_clang_static_glibc_O3 $out/bin
            '';
            buildInputs = [
              pkgs.clang
              pkgs.glibc.static
            ];
          };

          test-static-musl-cpp-progs = pkgs.stdenv.mkDerivation {
            name = "build-test-static-musl-cpp-prog";
            src = ./.;
            buildPhase = ''
              	      cd src/
                            clang -O3 -static --target=x86_64-unknown-linux-musl main.cpp -o main_cpp_clang_static_musl_O3
            '';
            installPhase = ''
              mkdir -p $out/bin
              cp main_cpp_clang_static_musl_O3 $out/bin
            '';
            buildInputs = [
              pkgs.clang
              pkgs.musl
            ];
          };

          # Trying to get a derivation that aggregates all the other derivations.
          all-progs = pkgs.stdenv.mkDerivation {
            name = "all-progs";
            buildInputs = [
            ];
          };

        in
        with pkgs;
        {
          formatter = pkgs.nixpkgs-fmt;
          packages = rec {
            default = test-cpp-progs;
            static-glibc = test-static-glibc-cpp-progs;
            static-musl = test-static-musl-cpp-progs;
            fortran = test-f77-progs;
          };
        }
      );
}
