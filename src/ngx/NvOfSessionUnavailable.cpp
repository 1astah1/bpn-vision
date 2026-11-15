// SPDX-License-Identifier: GPL-3.0-only
// BPN Vision: NvOfSession when the build has no NVIDIA Optical Flow SDK (its headers are only handed out
// after a developer sign-in). The session reports the runtime as unavailable, exactly as the real one does
// on a PC without nvofapi64.dll (AMD, Intel, older NVIDIA), so the graph takes the same fallback paths.
#include "veyra/ngx/NvOfSession.h"

#include "veyra/Log.h"

namespace veyra::ngx {

struct NvOfSession::FnList {};

NvOfSession::~NvOfSession() { shutdown(); }

bool NvOfSession::initialize(ID3D12Device*, ID3D12Resource*, ID3D12Resource*, ID3D12Resource*, ID3D12Resource*,
                             const Desc&, Status& status) {
    log::info("nvof-session", "NVIDIA Optical Flow is not part of this build; using the fallback motion paths");
    status = Status::LoadLibraryFailure;
    return false;
}

bool NvOfSession::execute(uint64_t, Status& status) {
    status = Status::InvalidArgument;
    return false;
}

bool NvOfSession::unregisterAll(Status&) { return true; }

void NvOfSession::shutdown() { initialized_ = false; }

} // namespace veyra::ngx
