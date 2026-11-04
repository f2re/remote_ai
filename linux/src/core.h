#pragma once

#include <QCryptographicHash>
#include <QDir>
#include <QFileInfo>
#include <QRegularExpression>
#include <QString>
#include <QStringList>

namespace rai {

enum class State { Offline, Connecting, Syncing, Thinking, Waiting, Error };

inline QString label(State state) {
    switch (state) {
    case State::Offline: return QStringLiteral("Не в сети");
    case State::Connecting: return QStringLiteral("Подключение");
    case State::Syncing: return QStringLiteral("Синхронизация");
    case State::Thinking: return QStringLiteral("Claude Code работает");
    case State::Waiting: return QStringLiteral("Ожидание ввода");
    case State::Error: return QStringLiteral("Ошибка");
    }
    return QStringLiteral("Неизвестно");
}

inline QString sprite(State state) {
    switch (state) {
    case State::Offline: return QStringLiteral("offline");
    case State::Connecting: return QStringLiteral("connecting");
    case State::Syncing: return QStringLiteral("syncing");
    case State::Thinking: return QStringLiteral("thinking");
    case State::Waiting: return QStringLiteral("waiting");
    case State::Error: return QStringLiteral("error");
    }
    return QStringLiteral("error");
}

struct Profile {
    QString host;
    QString user;
    int port = 22;
    QString identity;
    QString localPath;
    QString remotePath;
};

inline QString shellQuote(const QString &value) {
    QString output = value;
    output.replace(QLatin1Char('\''), QStringLiteral("'\\''"));
    return QStringLiteral("'") + output + QStringLiteral("'");
}

inline bool validate(const Profile &p, QString *reason = nullptr) {
    auto fail = [&](const QString &detail) {
        if (reason) *reason = detail;
        return false;
    };
    const QRegularExpression host(QStringLiteral("^[A-Za-z0-9][A-Za-z0-9.-]{0,252}$"));
    const QRegularExpression user(QStringLiteral("^[A-Za-z_][A-Za-z0-9_-]{0,31}$"));
    const QRegularExpression path(QStringLiteral("^/[A-Za-z0-9_.\\-/]+$"));
    if (!host.match(p.host).hasMatch()) return fail(QStringLiteral("Проверьте SSH-хост (DNS/IPv4)."));
    if (!user.match(p.user).hasMatch()) return fail(QStringLiteral("Некорректное имя пользователя SSH."));
    if (p.port < 1 || p.port > 65535) return fail(QStringLiteral("Порт SSH вне диапазона 1–65535."));
    if (!p.identity.isEmpty() && !QFileInfo(p.identity).isFile())
        return fail(QStringLiteral("Файл приватного SSH-ключа не найден."));
    if (!QFileInfo(p.localPath).isDir())
        return fail(QStringLiteral("Выберите существующую локальную папку проекта."));
    if (!path.match(p.remotePath).hasMatch() || p.remotePath == QStringLiteral("/") ||
        p.remotePath.contains(QStringLiteral("..")) || p.remotePath.contains(QStringLiteral("//")))
        return fail(QStringLiteral("Удалённый путь должен быть абсолютным и без '..'."));
    if (reason) reason->clear();
    return true;
}

inline QString sessionName(const Profile &p) {
    const QByteArray input = (p.user + QStringLiteral("@") + p.host +
        QStringLiteral(":") + QString::number(p.port) +
        QStringLiteral("|") + p.remotePath).toUtf8();
    return QStringLiteral("rai-") +
        QString::fromLatin1(QCryptographicHash::hash(input, QCryptographicHash::Sha256).toHex().left(16));
}

inline QStringList sshArgs(const Profile &p, const QString &remoteCommand, bool interactive = false) {
    QStringList args = {QStringLiteral("-o"), QStringLiteral("BatchMode=yes"),
        QStringLiteral("-o"), QStringLiteral("StrictHostKeyChecking=yes"),
        QStringLiteral("-o"), QStringLiteral("ConnectTimeout=8"),
        QStringLiteral("-p"), QString::number(p.port)};
    if (!p.identity.isEmpty()) args << QStringLiteral("-i") << p.identity;
    if (interactive) args << QStringLiteral("-t");
    args << (p.user + QStringLiteral("@") + p.host) << remoteCommand;
    return args;
}

inline QString mutagenEndpoint(const Profile &p) {
    const QString port = p.port == 22 ? QString() : QStringLiteral(":") + QString::number(p.port);
    return p.user + QStringLiteral("@") + p.host + port + QStringLiteral(":") + p.remotePath;
}

inline QString preflightCommand(const Profile &p) {
    return QStringLiteral("command -v tmux >/dev/null 2>&1 && command -v claude >/dev/null 2>&1 && mkdir -p -- ") +
        shellQuote(p.remotePath);
}

inline QString launchCommand(const Profile &p) {
    const QString session = shellQuote(sessionName(p));
    // tmux starts Claude only if an existing session is not available.
    return QStringLiteral("tmux has-session -t ") + session +
        QStringLiteral(" 2>/dev/null || tmux new-session -d -s ") + session +
        QStringLiteral(" -c ") + shellQuote(p.remotePath) +
        QStringLiteral(" ") + shellQuote(QStringLiteral("exec claude"));
}

inline QString pollCommand(const Profile &p) {
    const QString name = shellQuote(sessionName(p));
    return QStringLiteral("if tmux has-session -t ") + name +
        QStringLiteral(" 2>/dev/null; then echo __RA_SESSION__=1; tmux capture-pane -p -t ") +
        name + QStringLiteral(" -S -25; else echo __RA_SESSION__=0; fi");
}

inline State parsePane(const QString &output) {
    if (!output.contains(QStringLiteral("__RA_SESSION__=1"))) return State::Offline;
    const QString text = output.right(1600).toLower();
    if (text.contains(QStringLiteral("waiting for input")) ||
        text.contains(QStringLiteral("permission")) ||
        text.contains(QStringLiteral("do you want to proceed")) ||
        text.contains(QStringLiteral("ожидает ввода"))) return State::Waiting;
    if (text.contains(QStringLiteral("esc to interrupt")) ||
        text.contains(QStringLiteral("thinking")) ||
        text.contains(QStringLiteral("working")) ||
        text.contains(QStringLiteral("работает"))) return State::Thinking;
    return State::Waiting; // Нельзя выдавать отсутствие маркера за активную работу.
}

inline bool hasMutagenConflict(const QString &output) {
    for (const QString &line : output.toLower().split(QLatin1Char('\n'))) {
        if (!line.contains(QStringLiteral("conflict"))) continue;
        if (line.contains(QStringLiteral("conflicts: 0")) ||
            line.contains(QStringLiteral("0 conflicts")) ||
            line.contains(QStringLiteral("no conflicts"))) continue;
        return true;
    }
    return false;
}

} // namespace rai
