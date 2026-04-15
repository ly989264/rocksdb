# MiniKV Docs

This directory stores implementation-facing documentation for `minikv/`.

Top-level build entrypoint for this workspace:

- [COMPILE.md](/Users/liuyu/centos_ex/projects/OpenSource/rocksdb/COMPILE.md)

Current documents:

- [getting-started.md](./getting-started.md): newcomer-oriented map of the
  codebase, class responsibilities, thread model, and a step-by-step reading
  route.
- [architecture.md](./architecture.md): overall architecture audit, current
  boundaries, and major design risks.
- [build.md](./build.md): build integration, targets, common commands, and
  current local verification blockers.
- [layers/facade.md](./layers/facade.md): `MiniKV` public facade and ownership
  model.
- [layers/server.md](./layers/server.md): TCP server, I/O threading, RESP path,
  and connection lifecycle.
- [layers/command.md](./layers/command.md): command parsing, dispatch, and
  execution path.
- [layers/worker.md](./layers/worker.md): keyed worker routing, queueing, and
  backpressure model.
- [layers/engine.md](./layers/engine.md): RocksDB storage model, column
  families, key encoding, and hash data semantics.

Suggested reading order:

1. `getting-started.md`
2. `architecture.md`
3. `build.md`
4. `layers/server.md`
5. `layers/command.md`
6. `layers/worker.md`
7. `layers/engine.md`

The docs are intentionally based on the current code in `minikv/`, not on a
future target architecture.
