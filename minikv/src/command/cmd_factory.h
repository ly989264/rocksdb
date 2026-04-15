#pragma once

#include <memory>
#include <string>

#include "command/cmd.h"

namespace minikv {

struct CmdRegistration {
  const char* name;
  CommandType type;
  CmdFlags flags;
  std::unique_ptr<Cmd> (*creator)(const CmdRegistration&);
};

class CmdFactory {
 public:
  static const CmdRegistration* FindByName(const std::string& name);
  static const CmdRegistration* FindByType(CommandType type);
};

}  // namespace minikv
