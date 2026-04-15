# Repository Guidelines

## Agent Entry Points

Before building, testing, or making assumptions about `minikv`, read these
documents in order:

1. [COMPILE.md](/Users/liuyu/centos_ex/projects/OpenSource/rocksdb/COMPILE.md)
2. [minikv/docs/README.md](/Users/liuyu/centos_ex/projects/OpenSource/rocksdb/minikv/docs/README.md)
3. [minikv/docs/build.md](/Users/liuyu/centos_ex/projects/OpenSource/rocksdb/minikv/docs/build.md)
4. [minikv/docs/architecture.md](/Users/liuyu/centos_ex/projects/OpenSource/rocksdb/minikv/docs/architecture.md)

## Agent Build/Test Rules

- For this workspace, the authoritative Linux build and test workflow is inside
  the Docker container described in
  [COMPILE.md](/Users/liuyu/centos_ex/projects/OpenSource/rocksdb/COMPILE.md),
  not on the macOS host.
- If a build directory was configured inside Docker, do not rely on host-side
  `ctest` against that directory. Run `ctest` or the generated test binaries
  inside the same container context that produced the build tree.
- For `minikv`, prefer the documented container workflow in
  [COMPILE.md](/Users/liuyu/centos_ex/projects/OpenSource/rocksdb/COMPILE.md)
  and [minikv/docs/build.md](/Users/liuyu/centos_ex/projects/OpenSource/rocksdb/minikv/docs/build.md)
  before diagnosing build or test failures.

## Project Structure & Module Organization
RocksDB is a C++17 library centered on the public API in `include/rocksdb/`. Core engine code lives in `db/`, `table/`, `memtable/`, `util/`, `utilities/`, `env/`, and `port/`. Tests are typically colocated with implementation as `*_test.cc` files (for example, `table/table_test.cc`) with shared helpers under `test_util/`. Supporting tools and scripts live in `tools/`, `build_tools/`, `coverage/`, `microbench/`, `examples/`, and `db_stress_tool/`. Java bindings are under `java/`; website docs are under `docs/`.

## Build, Test, and Development Commands
Use the top-level `Makefile` for the standard Linux/macOS workflow:

- `make -j$(nproc)` builds the library, tools, benchmarks, and test binaries.
- `make check -j$(nproc)` builds everything and runs the default test suite.
- `make format` reformats changed lines with `build_tools/format-diff.sh`.
- `make check-format` verifies formatting without editing files.
- `make asan_check` or `make ubsan_check` runs sanitizer-backed test targets.
- `make coverage` rebuilds with gcov and writes reports under `coverage/`.

For CMake builds, use an out-of-tree directory:
`mkdir build && cd build && cmake .. && make -j`.

## Coding Style & Naming Conventions
Formatting follows `.clang-format`, which is `BasedOnStyle: Google`. Use 2-space indentation and keep includes and brace style consistent with nearby code. Follow existing naming patterns: classes use `CamelCase`, methods use `CamelCase`, local variables use `snake_case`, and test files end in `*_test.cc`. Keep public headers limited to `include/rocksdb/`; do not expose internal headers as API.

## Testing Guidelines
Add or update focused unit tests with every behavioral change. Prefer colocated `*_test.cc` coverage near the modified module and reuse `test_util/` helpers where possible. Run the narrowest relevant target during iteration, then finish with `make check` or the closest sanitizer target for concurrency, memory, or recovery changes.

## Commit & Pull Request Guidelines
Recent commits use short imperative subjects, often with the PR number appended, e.g. `Fix rare WAL handling crash (#12899)`. Keep commits scoped to one logical change. PRs should describe the problem, the fix, and validation performed; link the relevant issue when applicable. Include release-note updates under `unreleased_history/` when the change affects users or public behavior.
