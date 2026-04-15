#include "command/cmd_factory.h"

#include "command/t_hash.h"
#include "command/t_kv.h"

namespace minikv {
namespace {

const CmdRegistration kRegistrations[] = {
    {"PING", CommandType::kPing, CmdFlags::kRead | CmdFlags::kFast,
     &CreatePingCmd},
    {"HSET", CommandType::kHSet, CmdFlags::kWrite | CmdFlags::kFast,
     &CreateHSetCmd},
    {"HGETALL", CommandType::kHGetAll, CmdFlags::kRead | CmdFlags::kSlow,
     &CreateHGetAllCmd},
    {"HDEL", CommandType::kHDel, CmdFlags::kWrite | CmdFlags::kSlow,
     &CreateHDelCmd},
};

}  // namespace

const CmdRegistration* CmdFactory::FindByName(const std::string& name) {
  for (const auto& registration : kRegistrations) {
    if (name == registration.name) {
      return &registration;
    }
  }
  return nullptr;
}

const CmdRegistration* CmdFactory::FindByType(CommandType type) {
  for (const auto& registration : kRegistrations) {
    if (type == registration.type) {
      return &registration;
    }
  }
  return nullptr;
}

}  // namespace minikv
