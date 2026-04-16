# MiniKV Baseline

This document records the current `minikv` baseline as of 2026-04-16. It is a
snapshot of the existing implementation and verification results. It is not a
future planning document.

## Machine Information

Authoritative build and test environment:

- host OS: macOS Darwin `arm64`
- host repository path: `/Users/liuyu/centos_ex/projects/OpenSource/rocksdb`
- Docker container: `974d83bcff5c`
- container repository path: `/workspace/projects/OpenSource/rocksdb`
- build and test OS: Linux `x86_64`
- container kernel: `Linux 6.10.14-linuxkit`
- available container CPUs: `10`
- toolchain:
  - `gcc` / `g++`: `14.2.1 20250110 (Red Hat 14.2.1-7)`
  - `cmake`: `3.26.5`
  - `make`: `4.3`

## Build Method

The authoritative local workflow for `minikv` in this workspace is the Linux
Docker container documented in `COMPILE.md`.

Baseline build command:

```bash
docker exec 974d83bcff5c sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  ./build_tools/build_linux.sh --mode minikv --build-dir build-minikv --jobs 8
'
```

Baseline test execution commands:

```bash
docker exec 974d83bcff5c sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  ./build-minikv/minikv/minikv_cmd_test
'

docker exec 974d83bcff5c sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  ./build-minikv/minikv/minikv_hash_test
'

docker exec 974d83bcff5c sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  ./build-minikv/minikv/minikv_server_test
'

docker exec 974d83bcff5c sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  ./build-minikv/minikv/minikv_worker_test
'
```

Important execution note:

- a build tree configured inside Docker can embed container absolute paths such
  as `/workspace/projects/OpenSource/rocksdb/...`
- because of that, host-side `ctest` against a container-configured build tree
  is not authoritative and may fail even when the binaries pass inside the
  container
- for this baseline, configure, build, and run tests inside the same container
  context that produced the build directory

## Current Test Results

The current four `minikv` test binaries pass in the documented container
workflow.

- `minikv_cmd_test`: passed, 12 tests
- `minikv_hash_test`: passed, 12 tests
- `minikv_server_test`: passed, 10 tests
- `minikv_worker_test`: passed, 7 tests

## Basic RESP Smoke And Latency

Tooling used:

- `minikv/tools/resp_cli.py`: minimal RESP socket client
- `minikv/tools/baseline_smoke.py`: current smoke and latency sampler
- server launch command:

```bash
docker exec 974d83bcff5c sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  rm -rf /tmp/minikv-baseline-db &&
  ./build-minikv/minikv/minikv_server \
    --db_path /tmp/minikv-baseline-db \
    --bind 127.0.0.1 \
    --port 6390 \
    --io_threads 2 \
    --workers 4
'
```
- smoke command:

```bash
docker exec 974d83bcff5c sh -lc '
  cd /workspace/projects/OpenSource/rocksdb &&
  python3 minikv/tools/baseline_smoke.py --host 127.0.0.1 --port 6390 --iterations 20
'
```

Smoke commands exercised:

- `PING`
- `HSET baseline:key:0 field value:0`
- `HGETALL baseline:key:0`
- `HDEL baseline:key:0 field`

Observed result:

- `PING` -> `PONG`
- `HSET` -> integer `1`
- `HGETALL` -> flat array `["field", "value:0"]`
- `HDEL` -> integer `1`

Latency sample method:

- one persistent TCP connection to `minikv_server`
- sequential request/response measurement with `time.perf_counter_ns()`
- 20 iterations per command
- metrics reported in milliseconds

Sample latency results:

- `PING`: min `0.093`, p50 `0.106`, p95 `0.136`, avg `0.180`, max `1.566`
- `HSET`: min `0.138`, p50 `0.166`, p95 `0.526`, avg `0.215`, max `0.733`
- `HGETALL`: min `0.140`, p50 `0.160`, p95 `0.344`, avg `0.180`, max `0.355`
- `HDEL`: min `0.144`, p50 `0.164`, p95 `0.202`, avg `0.171`, max `0.250`

## Current Scope Boundary

This baseline applies only to the current implementation surface:

- supported commands: `PING`, `HSET`, `HGETALL`, `HDEL`
- supported data type: hash only
- supported replies: simple string, integer, flat array, error

Explicitly not supported in this baseline:

- non-hash data types
- complex reply shapes
- snapshot semantics
- module platform behavior
- search, including any `FT.*` commands

## Current Architecture Risks

- same-key correctness currently depends on `KeyLockTable` in the worker layer,
  not on storage-layer transactions
- reads are not snapshot-based; `HGETALL` reads metadata and scans the hash
  column family without a RocksDB snapshot
- multi-key atomicity does not exist in the current execution model
- `version` and `expire_at_ms` exist in metadata but are currently reserved
  fields only; they do not implement version rollover or TTL semantics
- the response surface is intentionally narrow; anything that needs richer RESP
  reply types, module platform behavior, or search semantics is outside the
  current baseline
