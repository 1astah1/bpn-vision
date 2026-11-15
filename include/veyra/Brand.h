// SPDX-License-Identifier: GPL-3.0-only
#pragma once
// BPN Vision: this fork's name and addresses, in one place. BPN Vision is a modified version of Veyra
// (https://github.com/Likely7/Veyra-NRVideo, GPL-3.0) and is distributed under the same licence.
// Internal identifiers (namespaces, file names, %LOCALAPPDATA%\Veyra, "Veyra Virtual Speaker") keep the
// upstream names on purpose: settings, presets and the audio device stay compatible, and upstream changes
// keep merging cleanly.

namespace veyra::brand {

inline constexpr const char* kName = "BPN Vision";
inline constexpr const char* kRepoUrl = "https://github.com/1astah1/bpn-vision";
inline constexpr const char* kRepoPath = "/1astah1/bpn-vision";                 // on github.com
inline constexpr const char* kLatestReleaseApi = "https://api.github.com/repos/1astah1/bpn-vision/releases/latest";
inline constexpr const char* kUpstreamUrl = "https://github.com/Likely7/Veyra-NRVideo";
// The VPN this build is distributed with (Telegram bot, tagged start link).
inline constexpr const char* kBpnUrl = "https://t.me/tgbpn_bot?start=utm_bpnvision";

} // namespace veyra::brand
