// SPDX-License-Identifier: GPL-3.0-only
// The Xbox streaming session API on the region host the streaming sign-in returned: home streaming of the
// user's own console (xHome, kind "home") and cloud gaming (xCloud, kind "cloud"), which differ only in the
// path, in what play() starts (a console's serverId or a game's titleId) and in the cloud's queue.
// Ported from Greenlight (unknownskl/greenlight, MIT): xcloudapi.ts and streammanager.ts. The signalling
// goes through Microsoft's servers even when the console is on the same network; the media then flows
// over WebRTC (see XboxSessionSource).
#pragma once
#include <memory>
#include <string>
#include <vector>

#include "veyra/xbox/Https.h"

namespace veyra::xbox {

struct Console {
    std::string serverId;       // "F4001234ABCD5678"
    std::string name;
    std::string powerState;     // "On", "ConnectedStandby", "Off" ...
    std::string consoleType;    // "XboxSeriesX", "XboxOne" ...
    bool outOfHomeWarning = false;
};

// A game in the cloud catalogue (GET /v2/titles), named from the Game Pass catalogue when it answers.
struct CloudTitle {
    std::string titleId;        // what play() takes, e.g. "FORTNITE"
    std::string productId;      // Microsoft Store id, the key of the Game Pass catalogue
    bool entitled = false;      // the account can start it now (in its subscription, or free)
    std::string name, publisher;
    std::string image;          // https URL of the square tile, may be empty
};

struct SessionState {
    std::string state;          // Provisioning, ReadyToConnect, Provisioned, WaitingForResources, Failed
    std::string errorCode, errorMessage;
};

struct IceCandidate {
    std::string candidate;      // "a=candidate:..." as the service sends it
    std::string sdpMid;
    int sdpMLineIndex = 0;
};

class StreamApi {
public:
    // kind: "home" for the consoles on the account, "cloud" for cloud gaming.
    StreamApi(std::shared_ptr<HttpsTransport> transport, std::string host, std::string gsToken, std::string kind = "home");

    std::vector<Console> consoles();
    // Cloud: every title of the offering; `entitled` marks the ones the account can play.
    std::vector<CloudTitle> titles();
    // Cloud: the service's estimate of the queue for a title, in seconds; -1 when it gives none.
    int waitSeconds(const std::string& titleId);
    // Starts a session on a console (home: serverId) or of a game (cloud: titleId); returns the session id.
    std::string play(const std::string& target, const std::string& locale = "zh-CN");
    SessionState state(const std::string& sessionId);
    void connect(const std::string& sessionId, const std::string& transferToken);
    // Sends the local offer, returns the console's answer SDP.
    std::string exchangeSdp(const std::string& sessionId, const std::string& offerSdp);
    // Sends local candidates, returns the console's (plus the IPv4 ones hidden in Teredo addresses).
    std::vector<IceCandidate> exchangeIce(const std::string& sessionId, const std::vector<IceCandidate>& local);
    void keepalive(const std::string& sessionId);
    void stop(const std::string& sessionId);

    // Exposed for tests.
    static std::vector<Console> parseConsoles(const std::string& body);
    static std::vector<CloudTitle> parseTitles(const std::string& body);
    static int parseWaitSeconds(const std::string& body);
    static std::vector<IceCandidate> parseIce(const std::string& exchangeResponse);
    // A Teredo address (2001:0:...) carries the client's public IPv4 and port, obfuscated.
    static bool teredoIpv4(const std::string& ipv6, std::string* ipv4, int* port);

    void setRetryDelayMs(int ms) { retryDelayMs_ = ms; }

private:
    HttpsResponse call(const std::string& method, const std::string& path, const std::string& body,
                       const std::map<std::string, std::string>& extraHeaders = {});
    std::string getExchange(const std::string& path);

    std::shared_ptr<HttpsTransport> http_;
    std::string host_, token_, kind_;
    std::string sessions() const { return "/v5/sessions/" + kind_; }
    int retryDelayMs_ = 750;
};

// Names, publishers and tiles for cloud titles from the Game Pass catalogue (catalog.gamepass.com), 100 per
// request like the web client. Best effort: titles the catalogue does not answer for keep their titleId as
// name. `language` like "ru-RU"; the market stays US, where the catalogue knows every cloud title.
void fillCatalog(HttpsTransport& http, std::vector<CloudTitle>& titles, const std::string& language);
// Exposed for tests: applies one catalogue answer ({"Products": {productId: {...}}}) to the titles.
void applyCatalog(std::vector<CloudTitle>& titles, const std::string& body);

} // namespace veyra::xbox
