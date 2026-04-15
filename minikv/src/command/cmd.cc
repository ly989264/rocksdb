#include "command/cmd.h"

namespace minikv {

Cmd::Cmd(std::string name, CommandType type, CmdFlags flags)
    : name_(std::move(name)), type_(type), flags_(flags) {}

rocksdb::Status Cmd::Init(const CmdInput& input) {
  initialized_ = false;
  route_key_.clear();

  rocksdb::Status status = DoInitial(input);
  if (status.ok()) {
    initialized_ = true;
  }
  return status;
}

CommandResponse Cmd::Execute(DBEngine* engine) {
  if (!initialized_) {
    return MakeStatus(rocksdb::Status::InvalidArgument(
        "command must be initialized before execution"));
  }
  return Do(engine);
}

CommandResponse Cmd::MakeStatus(rocksdb::Status status) {
  CommandResponse response;
  response.status = std::move(status);
  return response;
}

CommandResponse Cmd::MakeSimpleString(std::string text) {
  CommandResponse response;
  response.status = rocksdb::Status::OK();
  response.value.type = ResponseType::kSimpleString;
  response.value.text = std::move(text);
  return response;
}

CommandResponse Cmd::MakeInteger(long long value) {
  CommandResponse response;
  response.status = rocksdb::Status::OK();
  response.value.type = ResponseType::kInteger;
  response.value.integer = value;
  return response;
}

CommandResponse Cmd::MakeArray(std::vector<std::string> values) {
  CommandResponse response;
  response.status = rocksdb::Status::OK();
  response.value.type = ResponseType::kArray;
  response.value.array = std::move(values);
  return response;
}

}  // namespace minikv
