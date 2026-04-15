# Compile Document

This file is the top-level local entrypoint for build and test instructions in
this workspace.

Related documents:

- [README.md](/Users/liuyu/centos_ex/projects/OpenSource/rocksdb/README.md)
- [minikv/docs/README.md](/Users/liuyu/centos_ex/projects/OpenSource/rocksdb/minikv/docs/README.md)
- [minikv/docs/build.md](/Users/liuyu/centos_ex/projects/OpenSource/rocksdb/minikv/docs/build.md)
- [minikv/docs/architecture.md](/Users/liuyu/centos_ex/projects/OpenSource/rocksdb/minikv/docs/architecture.md)

## Environment
- Host repository path: `/Users/liuyu/centos_ex/projects/OpenSource/rocksdb`
- Docker container: `974d83bcff5c`
- Container repository path: `/workspace/projects/OpenSource/rocksdb`
- OS inside container: Linux `x86_64`
- Toolchain:
  - `gcc` / `g++`: `14.2.1`
- `cmake`: `3.26.5`
- `make`: `4.3`

## Required Execution Context

For this workspace, the authoritative Linux build and test workflow is inside
the Docker container, not on the macOS host.

Why this matters:

- the repository is mounted into the container at
  `/workspace/projects/OpenSource/rocksdb`
- build directories configured inside the container can embed container absolute
  paths
- host-side `ctest` against a container-configured build tree can fail even if
  the same binaries run correctly inside the container

Practical rule:

- configure, build, and run Linux test binaries inside the same container
  context that produced the build directory
- use host-side inspection only for reading sources and generated files, not as
  the default place to execute container-configured tests

## Configure
The project was configured in a fresh out-of-tree build directory to avoid stale host-generated caches:

```bash
docker exec 974d83bcff5c sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  cmake -S . -B build-docker \
    -DCMAKE_BUILD_TYPE=Debug \
    -DWITH_LIBURING=OFF \
    -DWITH_GFLAGS=OFF \
    -DWITH_SNAPPY=OFF \
    -DWITH_LZ4=OFF \
    -DWITH_ZLIB=OFF \
    -DWITH_ZSTD=OFF \
    -DWITH_BZ2=OFF \
    -DWITH_JEMALLOC=OFF
'
```

## Build
Full build command:

```bash
docker exec 974d83bcff5c sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  cmake --build build-docker --parallel 8
'
```

For the current Linux/minikv workflow, prefer the one-click script:

```bash
docker exec 974d83bcff5c sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  ./build_tools/build_linux.sh --mode all --build-dir build-minikv --jobs 8
'
```

Mode examples:

```bash
# Build RocksDB shared library only
./build_tools/build_linux.sh --mode rocksdb --build-dir build-minikv

# Build minikv only, reusing the previously built RocksDB targets in the same directory
./build_tools/build_linux.sh --mode minikv --build-dir build-minikv

# Build both RocksDB and minikv
./build_tools/build_linux.sh --mode all --build-dir build-minikv
```

## MiniKV Build And Test

`minikv` is built through the repository CMake configuration when
`WITH_MINIKV=ON`. In this workspace, the preferred path is:

```bash
docker exec 974d83bcff5c sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  ./build_tools/build_linux.sh --mode all --build-dir build-minikv --jobs 8
'
```

If RocksDB is already built in that directory and only `minikv` needs a rebuild:

```bash
docker exec 974d83bcff5c sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  ./build_tools/build_linux.sh --mode minikv --build-dir build-minikv --jobs 8
'
```

Expected `minikv` outputs inside the container:

- `build-minikv/minikv/minikv_server`
- `build-minikv/minikv/minikv_hash_test`
- `build-minikv/minikv/minikv_server_test`

Run `minikv` tests directly inside the same container:

```bash
docker exec 974d83bcff5c sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  ./build-minikv/minikv/minikv_hash_test &&
  ./build-minikv/minikv/minikv_server_test
'
```

At the time of writing, both test binaries pass in that container workflow:

- `minikv_hash_test`: 10 tests passed
- `minikv_server_test`: 6 tests passed

For more detailed `minikv` notes, see:

- [minikv/docs/build.md](/Users/liuyu/centos_ex/projects/OpenSource/rocksdb/minikv/docs/build.md)
- [minikv/docs/README.md](/Users/liuyu/centos_ex/projects/OpenSource/rocksdb/minikv/docs/README.md)

## Result
- Build status: success
- Main library targets built:
  - `build-docker/librocksdb.a`
  - `build-docker/librocksdb.so`
- Tools built include `ldb`, `sst_dump`, `db_bench`, `db_stress`, `trace_analyzer`, and `block_cache_trace_analyzer`.
- The default CMake build also completed compilation and linking of the test binaries.

## Compilation Database
Linux container builds do not emit `compile_commands.json` by default in this repository. Use `compiledb` to generate it from the configured Make-based build directory.

Install `compiledb` inside the container if needed:

```bash
docker exec 974d83bcff5c sh -lc '
  python3 -m ensurepip --user &&
  export PATH=$PATH:/root/.local/bin &&
  python3 -m pip install --user compiledb
'
```

Generate both the repository-wide and `minikv`-scoped compilation databases:

```bash
docker exec 974d83bcff5c sh -lc '
  export PATH=$PATH:/root/.local/bin &&
  cd /workspace/projects/OpenSource/rocksdb &&
  ./build_tools/generate_compile_commands.sh build-minikv
'
```

The one-click build script above also runs this step automatically.

Generated files:
- `compile_commands.json`: full RocksDB + minikv compilation database
- `minikv/compile_commands.json`: filtered entries for files under `minikv/`

## Notes
- A few test executables printed messages such as `Please install gflags to run this test... Skipping...`.
- This did not fail the build because `WITH_GFLAGS=OFF` was used intentionally for a portable container build.
- If a build directory was configured inside Docker, do not assume host-side
  `ctest` will work against it. Prefer `docker exec ... ctest --test-dir ...`
  or direct execution of the generated test binaries inside the same container.
- Rebuild from scratch with:

```bash
docker exec 974d83bcff5c sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  rm -rf build-docker &&
  cmake -S . -B build-docker -DCMAKE_BUILD_TYPE=Debug -DWITH_GFLAGS=OFF -DWITH_LIBURING=OFF &&
  cmake --build build-docker --parallel 8
'
```
