#pragma once

#include <cstdint>
#include <string>
#include <vector>

#include "rocksdb/status.h"

namespace minikv {

enum class CommandType {
  kPing,
  kHSet,
  kHGetAll,
  kHDel,
};

enum class ResponseType {
  kSimpleString,
  kInteger,
  kArray,
};

struct FieldValue {
  std::string field;
  std::string value;
};

struct ResponseValue {
  ResponseType type = ResponseType::kSimpleString;
  std::string text;
  long long integer = 0;
  std::vector<std::string> array;
};

struct CommandRequest {
  CommandType type;
  std::string key;
  std::vector<std::string> args;
};

struct CommandResponse {
  rocksdb::Status status;
  ResponseValue value;
};

}  // namespace minikv
