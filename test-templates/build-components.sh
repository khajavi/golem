#!/bin/bash

rust_test_components=("write-stdout" "write-stderr" "read-stdin" "clocks" "shopping-cart" "file-write-read-delete" "file-service" "http-client" "directories" "environment-service" "promise" "interruption" "clock-service" 
"option-service" "flags-service" "http-client-2" "stdio-cc" "failing-component" "variant-service" "key-value-service" "blob-store-service" "runtime-service" "networking" "shopping-cart-resource")
zig_test_components=("zig-1" "zig-2")
tinygo_test_components=("tinygo-wasi" "tinygo-wasi-http")
grain_test_components=("grain-1")
js_test_components=("js-1" "js-2")
java_test_components=("java-1" "java-2")
dotnet_test_components=("csharp-1")
swift_test_components=("swift-1")
c_test_components=("c-1")
python_test_components=("python-1")

# Optional arguments:
# - rebuild: clean all projects before building them
# - rust / zig / tinygo / grain / js / java / dotnet / swift / c / python: build only the specified language

rebuild=false
single_lang=false
lang=""
for arg in "$@"; do
  case $arg in
    rebuild)
      rebuild=true
      ;;
    rust)
      single_lang=true
      lang="rust"
      ;;
    zig)
      single_lang=true
      lang="zig"
      ;;
    tinygo)
      single_lang=true
      lang="tinygo"
      ;;
    grain)
      single_lang=true
      lang="grain"
      ;;
    js)
      single_lang=true
      lang="js"
      ;;
    java)
      single_lang=true
      lang="java"
      ;;
    dotnet)
      single_lang=true
      lang="dotnet"
      ;;
    swift)
      single_lang=true
      lang="swift"
      ;;
    c)
      single_lang=true
      lang="c"
      ;;
    python)
      single_lang=true
      lang="python"
      ;;
    *)
      echo "Unknown argument: $arg"
      exit 1
      ;;
  esac
done

if [ "$single_lang" = "false" ] || [ "$lang" = "rust" ]; then
  echo "Building the Rust test components"
  for subdir in "${rust_test_components[@]}"; do
    echo "Building $subdir..."
    pushd "$subdir" || exit

    if [ "$rebuild" = true ]; then
      cargo clean
    fi
    cargo component build --release

    echo "Turning the module into a WebAssembly Component..."
    target="../$subdir.wasm"
    target_wat="../$subdir.wat"
    cp -v $(find target/wasm32-wasi/release -name '*.wasm' -maxdepth 1) "$target"
    wasm-tools print "$target" >"$target_wat"

    popd || exit
  done
fi

if [ "$single_lang" = "false" ] || [ "$lang" = "zig" ]; then
  echo "Building the Zig test components"
  for subdir in "${zig_test_components[@]}"; do
    echo "Building $subdir..."
    pushd "$subdir" || exit

    if [ "$rebuild" = true ]; then
      rm -rf zig-out
      rm -rf zig-cache
    fi
    zig build

    echo "Turning the module into a WebAssembly Component..."
    target="../$subdir.wasm"
    target_wat="../$subdir.wat"
    wasm-tools component new zig-out/bin/main.wasm -o "$target" --adapt ../../golem-wit/adapters/tier3/wasi_snapshot_preview1.wasm
    wasm-tools print "$target" >"$target_wat"

    popd || exit
  done
fi

if [ "$single_lang" = "false" ] || [ "$lang" = "tinygo" ]; then
  echo "Building the TinyGo test components"
  for subdir in "${tinygo_test_components[@]}"; do
    echo "Building $subdir..."
    pushd "$subdir" || exit

    if [ "$rebuild" = true ]; then
      rm *.wasm
      rm -rf tinygo_wasi
    fi
    wit-bindgen tiny-go --out-dir tinygo_wasi ./wit
    tinygo build -target=wasi -tags=purego -o main.wasm main.go

    echo "Turning the module into a WebAssembly Component..."
    target="../$subdir.wasm"
    target_wat="../$subdir.wat"
    wasm-tools component embed ./wit main.wasm --output main.embed.wasm
    wasm-tools component new main.embed.wasm -o "$target" --adapt ../../golem-wit/adapters/tier2/wasi_snapshot_preview1.wasm
    wasm-tools print "$target" >"$target_wat"

    popd || exit
  done
fi

if [ "$single_lang" = "false" ] || [ "$lang" = "grain" ]; then
  echo "Building the Grain test components"
  for subdir in ${grain_test_components[@]}; do
    echo "Building $subdir..."
    pushd "$subdir" || exit

    if [ "$rebuild" = true ]; then
      rm *.wasm
    fi
    grain compile --release main.gr

    echo "Turning the module into a WebAssembly Component..."
    target="../$subdir.wasm"
    target_wat="../$subdir.wat"
    wasm-tools component new main.gr.wasm -o "$target" --adapt ../../golem-wit/adapters/tier3/wasi_snapshot_preview1.wasm
    wasm-tools print "$target" >"$target_wat"

    popd || exit
  done
fi

if [ "$single_lang" = "false" ] || [ "$lang" = "js" ]; then
  echo "Building the JS test components"
  for subdir in ${js_test_components[@]}; do
    echo "Building $subdir..."
    pushd "$subdir" || exit

    if [ "$rebuild" = true ]; then
      rm *.wasm
      rm package-lock.json
      rm -rf node_modules
    fi
    mkdir -pv out
    npm install
    npm run build

    echo "Turning the module into a WebAssembly Component..."
    target="../$subdir.wasm"
    target_wat="../$subdir.wat"
    cp -v "out/component.wasm" "$target"
    wasm-tools print "$target" >"$target_wat"

    popd || exit
  done
fi

if [ "$single_lang" = "false" ] || [ "$lang" = "java" ]; then
  echo "Building the Java test components"
  for subdir in ${java_test_components[@]}; do
    echo "Building $subdir..."
    pushd "$subdir" || exit

    if [ "$rebuild" = true ]; then
      mvn clean
    fi
    wit-bindgen teavm-java ./wit --out-dir src/main/java
    mvn prepare-package

    echo "Turning the module into a WebAssembly Component..."
    target="../$subdir.wasm"
    target_wat="../$subdir.wat"
    wasm-tools component new target/generated/wasm/teavm-wasm/classes.wasm -o "$target" --adapt ../../golem-wit/adapters/tier2/wasi_snapshot_preview1.wasm
    wasm-tools print "$target" >"$target_wat"

    popd || exit
  done
fi

if [ "$single_lang" = "false" ] || [ "$lang" = "dotnet" ]; then
  echo "Building the .NET test components"
  for subdir in ${dotnet_test_components[@]}; do
    echo "Building $subdir..."
    pushd "$subdir" || exit

    if [ "$rebuild" = true ]; then
      dotnet clean
    fi
    dotnet build -p:Configuration=Release

    echo "Turning the module into a WebAssembly Component..."
    target="../$subdir.wasm"
    target_wat="../$subdir.wat"
    wasm-tools component new bin/Release/net7.0/$subdir.wasm -o "$target" --adapt ../../golem-wit/adapters/tier3/wasi_snapshot_preview1.wasm
    wasm-tools print "$target" >"$target_wat"

    popd || exit
  done
fi

if [ "$single_lang" = "false" ] || [ "$lang" = "swift" ]; then
  echo "Building the Swift test components"
  for subdir in ${swift_test_components[@]}; do
    echo "Building $subdir..."
    pushd "$subdir" || exit

    if [ "$rebuild" = true ]; then
      rm *.wasm
    fi
    /Library/Developer/Toolchains/swift-latest.xctoolchain/usr/bin/swiftc -target wasm32-unknown-wasi main.swift -o main.wasm -sdk /Library/Developer/Toolchains/swift-wasm-5.7.3-RELEASE.xctoolchain/usr/share/wasi-sysroot/
    wasm-opt -Os main.wasm -o main.opt.wasm

    echo "Turning the module into a WebAssembly Component..."
    target="../$subdir.wasm"
    target_wat="../$subdir.wat"
    wasm-tools component new main.opt.wasm -o "$target" --adapt ../../golem-wit/adapters/tier3/wasi_snapshot_preview1.wasm
    wasm-tools print "$target" >"$target_wat"

    popd || exit
  done
fi

if [ "$single_lang" = "false" ] || [ "$lang" = "c" ]; then
  echo "Building the C test components"
  for subdir in "${c_test_components[@]}"; do
    echo "Building $subdir..."
    pushd "$subdir" || exit

    if [ "$rebuild" = true ]; then
      rm *.wasm
    fi
    wit-bindgen c ./wit
    ~/wasi-sdk-20.0/bin/clang --sysroot ~/wasi-sdk-20.0/share/wasi-sysroot main.c c_api1.c c_api1_component_type.o -o main.wasm

    echo "Turning the module into a WebAssembly Component..."
    target="../$subdir.wasm"
    target_wat="../$subdir.wat"
    wasm-tools component new main.wasm -o "$target" --adapt ../../golem-wit/adapters/tier2/wasi_snapshot_preview1.wasm
    wasm-tools print "$target" >"$target_wat"

    popd || exit
  done
fi

if [ "$single_lang" = "false" ] || [ "$lang" = "python" ]; then
  echo "Building the Python test components"
  for subdir in "${python_test_components[@]}"; do
    echo "Building $subdir..."
    pushd "$subdir" || exit

    if [ "$rebuild" = true ]; then
      rm *.wasm
      rm -rf bindings
    fi

    echo "Compiling the python code into a WebAssembly Component..."
    componentize-py bindings bindings
    componentize-py componentize test

    target="../$subdir.wasm"
    target_wat="../$subdir.wat"
    mv index.wasm $target
    wasm-tools print "$target" >"$target_wat"

    popd || exit
  done
fi
