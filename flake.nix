{
	description = "Dev shell for compiling Rust and C++ with CXX";

	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
		flake-utils.url = "github:numtide/flake-utils";
		naersk.url = "github:nix-community/naersk";
	};

	outputs = { self, nixpkgs, flake-utils, naersk }: flake-utils.lib.eachDefaultSystem (system:
		let
			pkgs = import nixpkgs { inherit system; };
			naersk' = pkgs.callPackage naersk {};
		in {
			devShell = pkgs.mkShell {
				nativeBuildInputs = with pkgs; [
					cxx-rs
					clang
				];
			};

			packages.default = let
				rust = naersk'.buildPackage {
					src = ./rust;
					copyBins = false;
					copyLibs = true;
				};
			in pkgs.stdenv.mkDerivation {
				name = "cxx-ffi-demo";
				version = "0.1.0";
				src = ./.;

				buildInputs = with pkgs; [
					cxx-rs
					clang
				];

				installPhase = ''
					mkdir -p $out/temp
					cxxbridge rust/src/lib.rs --header > $out/temp/bridge.rs.hpp
					cxxbridge rust/src/lib.rs > $out/temp/bridge.rs.cpp
					ls
					for file in *.cpp; do
						clang++ -std=c++17 -c $file -I$out/temp -I. -o $out/temp/$(basename $file cpp)o
					done
					clang++ -std=c++17 -c $out/temp/bridge.rs.cpp -I. -o $out/temp/bridge.o
					mkdir $out/bin
					clang++ $out/temp/*.o -L${rust}/lib -lrust -o $out/bin/cxx-ffi-demo
					runHook cleanupPhase
				'';

				cleanupPhase = ''
						rm $out/temp -rf
				'';
			};
		}
	);
}
