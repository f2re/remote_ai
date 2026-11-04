#include <QtTest/QtTest>
#include <QTemporaryDir>
#include "core.h"

class CoreTests final : public QObject {
    Q_OBJECT
private slots:
    void states() {
        QCOMPARE(rai::label(rai::State::Offline), QStringLiteral("Не в сети"));
        QCOMPARE(rai::sprite(rai::State::Thinking), QStringLiteral("thinking"));
        QCOMPARE(rai::sprite(rai::State::Error), QStringLiteral("error"));
    }
    void escaping() {
        QCOMPARE(rai::shellQuote(QStringLiteral("a'b")), QStringLiteral("'a'\\''b'"));
    }
    void profileGuard() {
        QTemporaryDir dir;
        QVERIFY(dir.isValid());
        rai::Profile p {QStringLiteral("example.org"), QStringLiteral("developer"), 22,
            QString(), dir.path(), QStringLiteral("/home/developer/project")};
        QString reason;
        QVERIFY(rai::validate(p, &reason));
        const QString session = rai::sessionName(p);
        QVERIFY(session.startsWith(QStringLiteral("rai-")));
        QCOMPARE(session.size(), 20);
        p.host = QStringLiteral("-oProxyCommand=malicious");
        QVERIFY(!rai::validate(p));
        p.host = QStringLiteral("example.org");
        p.remotePath = QStringLiteral("/home/developer/../root");
        QVERIFY(!rai::validate(p));
        p.remotePath = QStringLiteral("/home/developer/project");
        p.user = QStringLiteral("alice;cat");
        QVERIFY(!rai::validate(p));
        p.user = QStringLiteral("alice");
        p.port = 0;
        QVERIFY(!rai::validate(p));
    }
    void commandInvariants() {
        QTemporaryDir dir;
        rai::Profile p {QStringLiteral("ssh.example"), QStringLiteral("alice"), 22,
            QString(), dir.path(), QStringLiteral("/home/alice/dev")};
        const QStringList ssh = rai::sshArgs(p, rai::preflightCommand(p));
        QVERIFY(ssh.contains(QStringLiteral("StrictHostKeyChecking=yes")));
        QVERIFY(!ssh.contains(QStringLiteral("StrictHostKeyChecking=no")));
        const QString cmd = rai::launchCommand(p);
        QVERIFY(cmd.contains(QStringLiteral("tmux has-session")));
        QVERIFY(cmd.contains(QStringLiteral("exec claude")));
        QVERIFY(cmd.contains(QStringLiteral(" -c '/home/alice/dev' ")));
    }
    void parsing() {
        QCOMPARE(rai::parsePane(QStringLiteral("__RA_SESSION__=0")), rai::State::Offline);
        QCOMPARE(rai::parsePane(QStringLiteral("__RA_SESSION__=1\nthinking")), rai::State::Thinking);
        QCOMPARE(rai::parsePane(QStringLiteral("__RA_SESSION__=1\nwaiting for input")), rai::State::Waiting);
        QVERIFY(!rai::hasMutagenConflict(QStringLiteral("Conflicts: 0")));
        QVERIFY(rai::hasMutagenConflict(QStringLiteral("Conflicts: 1")));
    }
};
QTEST_APPLESS_MAIN(CoreTests)
#include "core_tests.moc"
