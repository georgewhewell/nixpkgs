{ lib
  , stdenv
  , fetchFromGitHub
  , cmake
  , pkgconfig
  , openssl
  , boost
  , symlinkJoin
  , llvmPackages_4
  , secp256k1
  , gmp
  , mongoc
  , zlib
  , ncurses
  , doxygen
  , graphviz
  , git
}:

let
  # requires static boost
  boostStatic = boost.override { enableStatic = true; };

  # requires WebAssembly llvm backend
  llvmWasm = llvmPackages_4.llvm.overrideAttrs(old: {
    cmakeFlags = old.cmakeFlags ++ [
      "-DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly"
    ];
  });

  # build expects these binaries/headers in same directory, so symlink together
  clangWasm = symlinkJoin {
    name = "clang-wasm";
    paths = [ 
      llvmWasm
      llvmPackages_4.clang
      llvmPackages_4.libclang
      llvmPackages_4.clang-unwrapped
    ];
  };

  # eosio builds against this fork of secp256k1
  secp256k1-zkp = secp256k1.overrideAttrs(old: {
    src = fetchFromGitHub {
      owner = "cryptonomex";
      repo = "secp256k1-zkp";
      rev  = "bd067945ead3b514fba884abd0de95fc4b5db9ae";
      sha256 = "13h48hrl186qjq20fn9xynwqcm7lfvisqhi6dg4l34yw3s65d5sv";
    };
  });
in llvmPackages_4.stdenv.mkDerivation rec {
  name = "eos-${version}";
  version = "1.2.5";

  src = fetchFromGitHub {
    owner = "EOSIO";
    repo = "eos";
    rev = "v${version}";
    sha256 = "1gi4y2bng91xqrxpikwd82w0igxldd1fw6rb750sqdgnw9bq2w6y";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ cmake git doxygen graphviz pkgconfig ];
  buildInputs = [ gmp mongoc ncurses openssl secp256k1-zkp zlib ];

  prePatch = ''
    # test fails to compile
    # sed -i /add_subdirectory\(\ test\ \)/d libraries/chainbase/CMakeLists.txt

    # tests fail to compile
    # sed -i /test_cypher_suites/d libraries/fc/test/crypto/CMakeLists.txt

    # examples fail to compile
    # ../libappbase.a(application.cpp.o): In function `appbase::application::version_string[abi:cxx11]() const':
    # application.cpp:(.text+0x2c3): undefined reference to `appbase::appbase_version_string'
    sed -i /add_subdirectory\(\ examples\ \)/d libraries/appbase/CMakeLists.txt

    # skip tests
    sed -i /add_subdirectory\(\ unittests\ \)/d CMakeLists.txt
    sed -i /add_subdirectory\(\ tests\ \)/d CMakeLists.txt
    # sed -i /add_subdirectory\(txn_test_gen_plugin\)/d plugins/CMakeLists.txt
  '';

  cmakeFlags = [
    "-DBOOST_INCLUDEDIR=${boostStatic.dev}/include"
    "-DBOOST_LIBRARYDIR=${boostStatic.out}/lib"
    "-DLLVM_DIR=${clangWasm}/lib/cmake/llvm"
    "-DWASM_ROOT=${clangWasm}"
  ];

  hardeningDisable = [ "all" ];
  enableParallelBuilding = true;

  meta = with lib; {
    description = "An open source smart contract platform";
    homepage = "https://eos.io";
    license = licenses.mit;
    maintainers = with maintainers; [ georgewhewell ];
    platforms = platforms.unix;
  };
}
