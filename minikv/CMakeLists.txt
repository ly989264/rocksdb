set(MINIKV_PUBLIC_HEADERS
  include/minikv/command.h
  include/minikv/config.h
  include/minikv/minikv.h)

set(MINIKV_INTERNAL_HEADERS
  src/command/cmd.h
  src/command/cmd_create.h
  src/command/cmd_factory.h
  src/command/t_hash.h
  src/command/t_kv.h
  src/common/thread_name.h
  src/engine/db_engine.h
  src/engine/key_codec.h
  src/server/resp_parser.h
  src/server/server.h
  src/worker/key_lock_table.h
  src/worker/worker.h)

set(MINIKV_SOURCES
  src/command/cmd.cc
  src/command/cmd_create.cc
  src/command/cmd_factory.cc
  src/command/t_hash.cc
  src/command/t_kv.cc
  src/common/thread_name.cc
  src/engine/db_engine.cc
  src/engine/key_codec.cc
  src/server/resp_parser.cc
  src/server/server.cc
  src/worker/key_lock_table.cc
  src/worker/worker.cc
  src/minikv.cc)

add_library(minikv_core STATIC
  ${MINIKV_PUBLIC_HEADERS}
  ${MINIKV_INTERNAL_HEADERS}
  ${MINIKV_SOURCES})

target_include_directories(minikv_core
  PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
  PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(minikv_core
  PUBLIC
    ${ROCKSDB_LIB}
  PRIVATE
    ${THIRDPARTY_LIBS}
    ${SYSTEM_LIBS})

target_compile_features(minikv_core PUBLIC cxx_std_17)

add_executable(minikv_server src/main.cc)
target_link_libraries(minikv_server PRIVATE minikv_core)
target_compile_features(minikv_server PRIVATE cxx_std_17)

if(WITH_TESTS)
  function(minikv_add_test target source)
    add_executable(${target} ${source})
    target_link_libraries(${target}
      PRIVATE
        minikv_core
        testharness
        gtest
        ${THIRDPARTY_LIBS}
        ${ROCKSDB_LIB})
    target_compile_features(${target} PRIVATE cxx_std_17)
    target_include_directories(${target} PRIVATE
      ${CMAKE_CURRENT_SOURCE_DIR}/src)
    gtest_discover_tests(${target} DISCOVERY_TIMEOUT 120)
    add_dependencies(rocksdb_check ${target})
  endfunction()

  minikv_add_test(minikv_cmd_test tests/command_test/cmd_test.cc)
  minikv_add_test(minikv_hash_test tests/command_test/hash_command_test.cc)
  minikv_add_test(minikv_server_test tests/server_test/server_test.cc)
  minikv_add_test(minikv_worker_test tests/worker_test/worker_test.cc)
endif()
