#include "command/cmd_create.h"

#include <cctype>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "command/cmd_factory.h"

namespace minikv {
namespace {

std::string NormalizeCommandName(const std::string& name) {
  std::string normalized = name;
  for (char& c : normalized) {
    c = static_cast<char>(::toupper(static_cast<unsigned char>(c)));
  }
  return normalized;
}

rocksdb::Status CreateCmdFromRegistration(const CmdRegistration& registration,
                                          const CmdInput& input,
                                          std::unique_ptr<Cmd>* cmd) {
  std::unique_ptr<Cmd> created = registration.creator(registration);
  rocksdb::Status status = created->Init(input);
  if (!status.ok()) {
    return status;
  }
  *cmd = std::move(created);
  return rocksdb::Status::OK();
}

CmdInput MakeInput(const std::vector<std::string>& parts) {
  CmdInput input;
  if (parts.size() >= 2) {
    input.has_key = true;
    input.key = parts[1];
  }
  if (parts.size() >= 3) {
    input.args.assign(parts.begin() + 2, parts.end());
  }
  return input;
}

CmdInput MakeInput(const CommandRequest& request) {
  CmdInput input;
  input.key = request.key;
  input.args = request.args;
  input.has_key = request.type == CommandType::kPing ? !request.key.empty()
                                                     : true;
  return input;
}

}  // namespace

rocksdb::Status CreateCmd(const std::vector<std::string>& parts,
                          std::unique_ptr<Cmd>* cmd) {
  if (cmd == nullptr) {
    return rocksdb::Status::InvalidArgument("cmd output is required");
  }
  cmd->reset();
  if (parts.empty()) {
    return rocksdb::Status::InvalidArgument("empty command");
  }

  const CmdRegistration* registration =
      CmdFactory::FindByName(NormalizeCommandName(parts[0]));
  if (registration == nullptr) {
    return rocksdb::Status::InvalidArgument("unsupported command");
  }
  return CreateCmdFromRegistration(*registration, MakeInput(parts), cmd);
}

rocksdb::Status CreateCmd(const CommandRequest& request,
                          std::unique_ptr<Cmd>* cmd) {
  if (cmd == nullptr) {
    return rocksdb::Status::InvalidArgument("cmd output is required");
  }
  cmd->reset();

  const CmdRegistration* registration = CmdFactory::FindByType(request.type);
  if (registration == nullptr) {
    return rocksdb::Status::InvalidArgument("unknown command type");
  }
  return CreateCmdFromRegistration(*registration, MakeInput(request), cmd);
}

}  // namespace minikv
