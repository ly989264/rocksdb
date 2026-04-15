# MiniKV Build Notes

## Scope

This document records how `minikv` is built in the current repository and what
is currently known about local verification status.

## Build Integration

`minikv` is integrated into the top-level RocksDB CMake build behind the
`WITH_MINIKV` option:

- top-level `CMakeLists.txt`: `option(WITH_MINIKV "build minikv" ON)`
- when enabled, the repository adds `add_subdirectory(minikv)`

Inside `minikv/CMakeLists.txt`, the current targets are:

- `minikv_core`: static library containing public headers, internal headers, and
  all implementation sources under `src/`
- `minikv_server`: executable built from `src/main.cc`
- `minikv_hash_test`: hash behavior and concurrency tests, gated by
  `WITH_TESTS`
- `minikv_server_test`: network/server behavior tests, gated by `WITH_TESTS`

## Dependencies

Current linkage is:

- `minikv_core`
  - public: `${ROCKSDB_LIB}`
  - private: `${THIRDPARTY_LIBS}`, `${SYSTEM_LIBS}`
- test targets
  - `minikv_core`
  - `testharness`
  - `gtest`
  - `${THIRDPARTY_LIBS}`
  - `${ROCKSDB_LIB}`

Language level:

- `minikv_core`: C++17
- `minikv_server`: C++17
- test targets: C++17

## Common Build Commands

Typical local commands for `minikv` are:

```bash
mkdir -p build && cd build
cmake .. -DWITH_MINIKV=ON -DWITH_TESTS=ON
cmake --build . --target minikv_server -j
cmake --build . --target minikv_hash_test minikv_server_test -j
ctest -R minikv --output-on-failure
```

Repository-wide builds can also include `minikv` when `WITH_MINIKV` remains
enabled.

## Container Workflow

In this workspace, the reliable `minikv` build and test path is the Linux
Docker container workflow rather than running the Linux-oriented build outputs
directly from the macOS host.

The repository already contains a Linux helper:

```bash
./build_tools/build_linux.sh --mode all --build-dir build-minikv --jobs 8
```

When using Docker, run that script inside the container that has the repository
mounted. A representative form is:

```bash
docker exec <container> sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  ./build_tools/build_linux.sh --mode all --build-dir build-minikv --jobs 8
'
```

Targeted rebuilds inside the same configured Linux container:

```bash
docker exec <container> sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  ./build_tools/build_linux.sh --mode minikv --build-dir build-minikv --jobs 8
'
```

Direct test execution inside the same container:

```bash
docker exec <container> sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  ./build-minikv/minikv/minikv_hash_test &&
  ./build-minikv/minikv/minikv_server_test
'
```

This container context matters because the generated CMake and CTest metadata
can embed absolute paths from the environment where the build directory was
configured.

## Current Runtime Configuration Surface

`src/main.cc` currently accepts:

- `--db_path`
- `--bind`
- `--port`
- `--io_threads`
- `--workers`
- `--max_pending`
- `--max_connections`
- `--max_request_bytes`
- `--idle_timeout_ms`

The defaults are defined in `include/minikv/config.h`.

## Current Verification State In This Workspace

`minikv` has been verified successfully in the Linux Docker build environment
available for this workspace.

Verified test runs inside the container-configured `build-minikv` directory:

- `./build-minikv/minikv/minikv_hash_test`: passed, 10 tests
- `./build-minikv/minikv/minikv_server_test`: passed, 6 tests

The earlier confusion came from mixing execution contexts:

- `build-codex-minikv` on the host did not have usable `minikv` test binaries
  for `ctest -R minikv`.
- `build-docker` and similar directories may be configured inside a Linux
  container and can therefore embed container absolute paths such as
  `/workspace/projects/OpenSource/rocksdb/...`.
- Running host-side `ctest` against a container-configured build tree can fail
  even when the binaries are valid inside the container.

The practical rule is: build and run `minikv` tests inside the same container
context that produced the build directory, or execute the test binaries directly
from that container.

## Documentation Implication

The design docs in this directory are still grounded in code inspection first,
but they are no longer purely unverified analysis. The current command and
server tests do pass in the documented Linux container workflow.
