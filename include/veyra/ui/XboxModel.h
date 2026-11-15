// SPDX-License-Identifier: GPL-3.0-only
#pragma once
// The "Xbox 串流" side of the UI (unofficial): Microsoft device-code sign-in, the consoles on the account,
// and starting a stream. Network work runs on worker threads and reports back on the UI thread.
#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <atomic>
#include <functional>
#include <memory>
#include <thread>

#include "veyra/source/XboxSessionSource.h"
#include "veyra/xbox/Account.h"

namespace veyra::ui {

class XboxModel final : public QObject {
    Q_OBJECT
    // {signedIn, busy, status, code, verificationUri, selected, gamepad, streaming, stream{...}, lastLabel}
    Q_PROPERTY(QVariantMap state READ state NOTIFY changed)
    // [{id, name, type, power, selected}]
    Q_PROPERTY(QVariantList consoles READ consoles NOTIFY changed)
    // Cloud gaming (xCloud): [{id, name, publisher, image, entitled}], entitled first.
    Q_PROPERTY(QVariantList games READ games NOTIFY changed)
public:
    struct Launch {
        source::XboxConnectDesc desc;
        QString label;
    };
    using LaunchFn = std::function<bool(Launch)>;

    explicit XboxModel(QObject* parent = nullptr);
    ~XboxModel() override;

    void setLaunchHandler(LaunchFn handler) { launch_ = std::move(handler); }
    void updateStream(bool active, const source::XboxStats& stats);

    QVariantMap state() const;
    QVariantList consoles() const { return consoles_; }
    QVariantList games() const { return games_; }

    Q_INVOKABLE void load();
    Q_INVOKABLE void signIn();
    Q_INVOKABLE void openSignInPage();
    Q_INVOKABLE void signOut();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void select(const QString& id);
    Q_INVOKABLE void loadGames();
    Q_INVOKABLE void selectGame(const QString& id);
    Q_INVOKABLE bool playGame();
    Q_INVOKABLE void cancel();
    Q_INVOKABLE bool connectStream();
    Q_INVOKABLE bool resumeLast();
    Q_INVOKABLE bool set(const QString& key, const QVariant& value);

    QString lastLabel() const { return lastName_; }

signals:
    void changed();
    void started();
    void notice(const QString& text, bool isError);

private:
    void startJob(const QString& status, std::function<std::function<void()>(const std::atomic<bool>&)> work);
    void loadSettings();
    void saveSettings() const;
    bool launchConsole(const QString& id, const QString& name);
    bool launchGame(const QString& id, const QString& name);

    LaunchFn launch_;
    std::shared_ptr<xbox::Account> account_;
    QVariantList consoles_;
    QString selected_, status_, code_, verificationUri_, lastId_, lastName_;
    QVariantList games_;
    // mode_: "console" or "cloud". lastKind_ says what resumeLast() restarts (lastId_ is a titleId for "cloud").
    QString mode_ = QStringLiteral("console"), lastKind_ = QStringLiteral("console"), selectedGame_, cloudOffering_;
    bool cloudChecked_ = false, cloudAvailable_ = false;
    bool busy_ = false, gamepad_ = true, loaded_ = false, streamActive_ = false, signingIn_ = false;
    QVariantMap stream_;
    std::atomic<bool> cancel_{false};
    std::jthread worker_;
};

} // namespace veyra::ui
