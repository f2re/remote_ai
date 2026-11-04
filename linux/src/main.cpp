#include "core.h"
#include <QAction>
#include <QApplication>
#include <QDialog>
#include <QDialogButtonBox>
#include <QFileDialog>
#include <QFormLayout>
#include <QIcon>
#include <QLineEdit>
#include <QMenu>
#include <QMessageBox>
#include <QMouseEvent>
#include <QPainter>
#include <QPixmap>
#include <QPointer>
#include <QProcess>
#include <QPushButton>
#include <QSettings>
#include <QSpinBox>
#include <QStandardPaths>
#include <QSystemTrayIcon>
#include <QTimer>
#include <QVBoxLayout>

class MascotWindow final : public QWidget {
public:
    MascotWindow() : QWidget(nullptr, Qt::FramelessWindowHint | Qt::Tool | Qt::WindowStaysOnTopHint) {
        setAttribute(Qt::WA_TranslucentBackground);
        setFixedSize(144, 144);
        setMouseTracking(true);
        setWindowTitle(QStringLiteral("Remote AI Astra"));
        loadProfile();
        buildMenu();
        tray_ = new QSystemTrayIcon(QIcon(QStringLiteral(":/mascot/waiting.png")), this);
        tray_->setContextMenu(menu_);
        connect(tray_, &QSystemTrayIcon::activated, this, [this](QSystemTrayIcon::ActivationReason reason) {
            if (reason == QSystemTrayIcon::Trigger) primaryAction();
        });
        if (QSystemTrayIcon::isSystemTrayAvailable()) tray_->show();
        const QVariant position = QSettings(QStringLiteral("RemoteAI"), QStringLiteral("Astra"))
                                      .value(QStringLiteral("mascotPosition"));
        if (position.isValid()) move(position.toPoint());
        else move(80, 80);
        polling_.setInterval(7000);
        connect(&polling_, &QTimer::timeout, this, [this] {
            if (!busy_ && running_) startSyncStatus();
        });
        setState(rai::State::Offline);
    }

protected:
    void paintEvent(QPaintEvent *) override {
        QPainter painter(this);
        painter.setRenderHint(QPainter::SmoothPixmapTransform, false);
        const QPixmap sprite(QStringLiteral(":/mascot/") + rai::sprite(state_) + QStringLiteral(".png"));
        if (!sprite.isNull()) {
            const QPixmap scaled = sprite.scaled(124, 124, Qt::KeepAspectRatio, Qt::FastTransformation);
            painter.drawPixmap((width() - scaled.width()) / 2, (height() - scaled.height()) / 2, scaled);
        } else {
            painter.drawText(rect(), Qt::AlignCenter, QStringLiteral("☁"));
        }
    }

    void mousePressEvent(QMouseEvent *event) override {
        if (event->button() == Qt::RightButton) {
            menu_->popup(event->globalPos());
            return;
        }
        if (event->button() == Qt::LeftButton) {
            mouseStart_ = event->globalPos();
            windowStart_ = pos();
            dragging_ = false;
        }
    }

    void mouseMoveEvent(QMouseEvent *event) override {
        if (!(event->buttons() & Qt::LeftButton)) return;
        const QPoint delta = event->globalPos() - mouseStart_;
        if (delta.manhattanLength() > QApplication::startDragDistance()) dragging_ = true;
        if (dragging_) move(windowStart_ + delta);
    }

    void mouseReleaseEvent(QMouseEvent *event) override {
        if (event->button() != Qt::LeftButton) return;
        if (dragging_) {
            QSettings(QStringLiteral("RemoteAI"), QStringLiteral("Astra"))
                .setValue(QStringLiteral("mascotPosition"), pos());
        } else {
            primaryAction();
        }
    }

private:
    enum class Phase { Preflight, SyncList, SyncResume, SyncCreate, SyncFlush, Launch, SyncStatus, RemotePoll, Stop };

    void setState(rai::State next, const QString &detail = QString()) {
        state_ = next;
        statusDetail_ = detail;
        const QString tooltip = QStringLiteral("Remote AI Astra — ") + rai::label(next) +
            (detail.isEmpty() ? QString() : QStringLiteral("\n") + detail);
        setToolTip(tooltip);
        setAccessibleName(tooltip);
        if (tray_) tray_->setToolTip(tooltip);
        update();
    }

    void fail(const QString &message) {
        busy_ = false;
        running_ = false;
        polling_.stop();
        setState(rai::State::Error, message);
    }

    void loadProfile() {
        QSettings settings(QStringLiteral("RemoteAI"), QStringLiteral("Astra"));
        profile_.host = settings.value(QStringLiteral("host")).toString();
        profile_.user = settings.value(QStringLiteral("user"), qEnvironmentVariable("USER")).toString();
        profile_.port = settings.value(QStringLiteral("port"), 22).toInt();
        profile_.identity = settings.value(QStringLiteral("identity")).toString();
        profile_.localPath = settings.value(QStringLiteral("localPath")).toString();
        profile_.remotePath = settings.value(QStringLiteral("remotePath")).toString();
    }

    void saveProfile() {
        QSettings settings(QStringLiteral("RemoteAI"), QStringLiteral("Astra"));
        settings.setValue(QStringLiteral("host"), profile_.host);
        settings.setValue(QStringLiteral("user"), profile_.user);
        settings.setValue(QStringLiteral("port"), profile_.port);
        settings.setValue(QStringLiteral("identity"), profile_.identity);
        settings.setValue(QStringLiteral("localPath"), profile_.localPath);
        settings.setValue(QStringLiteral("remotePath"), profile_.remotePath);
        settings.sync();
    }

    void settingsDialog() {
        QDialog dialog(this);
        dialog.setWindowTitle(QStringLiteral("Настройки Remote AI Astra"));
        dialog.resize(520, 300);
        auto *layout = new QVBoxLayout(&dialog);
        auto *form = new QFormLayout;
        auto *host = new QLineEdit(profile_.host);
        auto *user = new QLineEdit(profile_.user);
        auto *port = new QSpinBox;
        port->setRange(1, 65535);
        port->setValue(profile_.port);
        auto *identity = new QLineEdit(profile_.identity);
        auto *local = new QLineEdit(profile_.localPath);
        auto *remote = new QLineEdit(profile_.remotePath);
        auto *pickProject = new QPushButton(QStringLiteral("Выбрать локальный проект…"));
        auto *pickKey = new QPushButton(QStringLiteral("Выбрать SSH-ключ…"));
        connect(pickProject, &QPushButton::clicked, &dialog, [local, &dialog] {
            const QString path = QFileDialog::getExistingDirectory(&dialog, QStringLiteral("Проект"), local->text());
            if (!path.isEmpty()) local->setText(path);
        });
        connect(pickKey, &QPushButton::clicked, &dialog, [identity, &dialog] {
            const QString path = QFileDialog::getOpenFileName(&dialog, QStringLiteral("Приватный SSH-ключ"));
            if (!path.isEmpty()) identity->setText(path);
        });
        form->addRow(QStringLiteral("SSH-хост:"), host);
        form->addRow(QStringLiteral("Пользователь:"), user);
        form->addRow(QStringLiteral("Порт SSH:"), port);
        form->addRow(QStringLiteral("Приватный ключ:"), identity);
        form->addRow(QString(), pickKey);
        form->addRow(QStringLiteral("Локальный проект:"), local);
        form->addRow(QString(), pickProject);
        form->addRow(QStringLiteral("Удалённая папка (абсолютный путь):"), remote);
        layout->addLayout(form);
        auto *buttons = new QDialogButtonBox(QDialogButtonBox::Save | QDialogButtonBox::Cancel);
        connect(buttons, &QDialogButtonBox::accepted, &dialog, &QDialog::accept);
        connect(buttons, &QDialogButtonBox::rejected, &dialog, &QDialog::reject);
        layout->addWidget(buttons);
        if (dialog.exec() != QDialog::Accepted) return;
        profile_ = {host->text().trimmed(), user->text().trimmed(), port->value(),
            identity->text().trimmed(), local->text().trimmed(), remote->text().trimmed()};
        saveProfile();
        setState(rai::State::Offline);
    }

    void buildMenu() {
        menu_ = new QMenu(this);
        QAction *start = menu_->addAction(QStringLiteral("Запустить / переподключить"));
        QAction *attach = menu_->addAction(QStringLiteral("Открыть текущую tmux-сессию"));
        QAction *stop = menu_->addAction(QStringLiteral("Остановить удалённую tmux-сессию"));
        menu_->addSeparator();
        QAction *settings = menu_->addAction(QStringLiteral("Настройки…"));
        QAction *diagnostics = menu_->addAction(QStringLiteral("Диагностика…"));
        menu_->addSeparator();
        QAction *quit = menu_->addAction(QStringLiteral("Завершить Remote AI"));
        connect(start, &QAction::triggered, this, [this] { startSession(); });
        connect(attach, &QAction::triggered, this, [this] { openTerminal(); });
        connect(stop, &QAction::triggered, this, [this] { stopSession(); });
        connect(settings, &QAction::triggered, this, [this] { settingsDialog(); });
        connect(diagnostics, &QAction::triggered, this, [this] {
            QMessageBox::information(this, QStringLiteral("Диагностика"),
                QStringLiteral("Состояние: ") + rai::label(state_) + QStringLiteral("\n") + statusDetail_);
        });
        connect(quit, &QAction::triggered, qApp, &QApplication::quit);
    }

    void primaryAction() {
        if (profile_.host.isEmpty() || profile_.localPath.isEmpty()) { settingsDialog(); return; }
        if (!running_ || state_ == rai::State::Offline || state_ == rai::State::Error) startSession();
        else openTerminal();
    }

    void openTerminal() {
        QString reason;
        if (!rai::validate(profile_, &reason)) { fail(reason); return; }
        QString terminal = QStandardPaths::findExecutable(QStringLiteral("x-terminal-emulator"));
        if (terminal.isEmpty()) terminal = QStandardPaths::findExecutable(QStringLiteral("xterm"));
        if (terminal.isEmpty()) { fail(QStringLiteral("Не найден системный терминал.")); return; }
        const QString cmd = QStringLiteral("tmux attach-session -t ") +
            rai::shellQuote(rai::sessionName(profile_));
        const QStringList args = QStringList{QStringLiteral("-e"), QStringLiteral("ssh")} +
            rai::sshArgs(profile_, cmd, true);
        if (!QProcess::startDetached(terminal, args)) fail(QStringLiteral("Не удалось открыть терминал."));
    }

    void startSession() {
        if (busy_) return;
        QString reason;
        if (!rai::validate(profile_, &reason)) { fail(reason); return; }
        if (QStandardPaths::findExecutable(QStringLiteral("ssh")).isEmpty()) {
            fail(QStringLiteral("Не установлен OpenSSH client.")); return;
        }
        if (QStandardPaths::findExecutable(QStringLiteral("mutagen")).isEmpty()) {
            fail(QStringLiteral("Mutagen не найден в PATH. Установите Mutagen перед запуском.")); return;
        }
        running_ = false;
        polling_.stop();
        busy_ = true;
        setState(rai::State::Connecting);
        run(QStringLiteral("ssh"), rai::sshArgs(profile_, rai::preflightCommand(profile_)), Phase::Preflight);
    }

    void stopSession() {
        if (busy_) return;
        QString reason;
        if (!rai::validate(profile_, &reason)) { fail(reason); return; }
        polling_.stop();
        busy_ = true;
        run(QStringLiteral("ssh"), rai::sshArgs(profile_,
            QStringLiteral("tmux kill-session -t ") + rai::shellQuote(rai::sessionName(profile_))), Phase::Stop);
    }

    void startSyncStatus() {
        busy_ = true;
        run(QStringLiteral("mutagen"), {QStringLiteral("sync"), QStringLiteral("list"), rai::sessionName(profile_)}, Phase::SyncStatus);
    }

    void run(const QString &program, const QStringList &args, Phase phase) {
        phase_ = phase;
        auto *job = new QProcess(this);
        process_ = job;
        job->setProcessChannelMode(QProcess::MergedChannels);
        connect(job, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, job](int exitCode, QProcess::ExitStatus exitStatus) {
                const QString output = QString::fromUtf8(job->readAllStandardOutput());
                job->deleteLater();
                if (process_ != job) return;
                process_ = nullptr;
                onCommandFinished(exitStatus == QProcess::NormalExit ? exitCode : -1, output);
            });
        connect(job, &QProcess::errorOccurred, this, [this, job](QProcess::ProcessError error) {
            if (error == QProcess::FailedToStart && process_ == job) {
                process_ = nullptr;
                job->deleteLater();
                fail(QStringLiteral("Не удалось запустить необходимую команду."));
            }
        });
        QPointer<QProcess> guarded(job);
        QTimer::singleShot(30000, job, [guarded] {
            if (guarded && guarded->state() != QProcess::NotRunning) guarded->kill();
        });
        job->start(program, args);
    }

    void onCommandFinished(int code, const QString &output) {
        if (code != 0 && phase_ != Phase::SyncList && phase_ != Phase::Stop) {
            fail(QStringLiteral("Команда завершилась с ошибкой. Проверьте SSH, tmux, Claude и Mutagen."));
            return;
        }
        const QString session = rai::sessionName(profile_);
        switch (phase_) {
        case Phase::Preflight:
            setState(rai::State::Syncing);
            run(QStringLiteral("mutagen"), {QStringLiteral("sync"), QStringLiteral("list")}, Phase::SyncList);
            return;
        case Phase::SyncList:
            if (code != 0) { fail(QStringLiteral("Не удалось прочитать список сессий Mutagen.")); return; }
            if (output.contains(QStringLiteral("Name: ") + session)) {
                run(QStringLiteral("mutagen"), {QStringLiteral("sync"), QStringLiteral("resume"), session}, Phase::SyncResume);
            } else {
                QStringList args = {QStringLiteral("sync"), QStringLiteral("create"),
                    QStringLiteral("--name=") + session, QStringLiteral("--sync-mode=two-way-safe")};
                for (const QString &ignore : {QStringLiteral(".git"), QStringLiteral(".build"),
                    QStringLiteral("node_modules"), QStringLiteral(".venv"), QStringLiteral("dist")})
                    args << QStringLiteral("--ignore=") + ignore;
                args << profile_.localPath << rai::mutagenEndpoint(profile_);
                run(QStringLiteral("mutagen"), args, Phase::SyncCreate);
            }
            return;
        case Phase::SyncResume:
        case Phase::SyncCreate:
            run(QStringLiteral("mutagen"), {QStringLiteral("sync"), QStringLiteral("flush"), session}, Phase::SyncFlush);
            return;
        case Phase::SyncFlush:
            run(QStringLiteral("ssh"), rai::sshArgs(profile_, rai::launchCommand(profile_)), Phase::Launch);
            return;
        case Phase::Launch:
            busy_ = false;
            running_ = true;
            polling_.start();
            startSyncStatus();
            return;
        case Phase::SyncStatus:
            if (rai::hasMutagenConflict(output)) {
                fail(QStringLiteral("Mutagen обнаружил конфликт. Разрешите его вручную."));
                return;
            }
            if (output.contains(QStringLiteral("Paused"), Qt::CaseInsensitive) ||
                output.contains(QStringLiteral("Disconnected"), Qt::CaseInsensitive)) {
                fail(QStringLiteral("Mutagen остановлен или потерял соединение."));
                return;
            }
            run(QStringLiteral("ssh"), rai::sshArgs(profile_, rai::pollCommand(profile_)), Phase::RemotePoll);
            return;
        case Phase::RemotePoll: {
            busy_ = false;
            const rai::State next = rai::parsePane(output);
            running_ = next != rai::State::Offline;
            if (!running_) polling_.stop();
            setState(next);
            return;
        }
        case Phase::Stop:
            busy_ = false;
            running_ = false;
            polling_.stop();
            if (code != 0) { fail(QStringLiteral("Не удалось остановить tmux-сессию.")); return; }
            setState(rai::State::Offline);
            return;
        }
    }

    rai::Profile profile_;
    rai::State state_ = rai::State::Offline;
    QString statusDetail_;
    QSystemTrayIcon *tray_ = nullptr;
    QMenu *menu_ = nullptr;
    QProcess *process_ = nullptr;
    QTimer polling_;
    Phase phase_ = Phase::Preflight;
    bool busy_ = false;
    bool running_ = false;
    bool dragging_ = false;
    QPoint mouseStart_;
    QPoint windowStart_;
};

int main(int argc, char **argv) {
    QApplication app(argc, argv);
    QApplication::setApplicationName(QStringLiteral("Remote AI Astra"));
    QApplication::setOrganizationName(QStringLiteral("RemoteAI"));
    QApplication::setQuitOnLastWindowClosed(false);
    if (app.arguments().contains(QStringLiteral("--smoke"))) {
        for (const QString &sprite : {QStringLiteral("offline"), QStringLiteral("connecting"),
                QStringLiteral("syncing"), QStringLiteral("thinking"),
                QStringLiteral("waiting"), QStringLiteral("error")}) {
            if (QPixmap(QStringLiteral(":/mascot/") + sprite + QStringLiteral(".png")).isNull()) {
                return 3; // Неполный ресурсный набор маскота должен блокировать пакет.
            }
        }
    }
    MascotWindow mascot;
    mascot.show();
    if (app.arguments().contains(QStringLiteral("--smoke"))) {
        QTimer::singleShot(250, &app, &QApplication::quit);
    }
    return app.exec();
}
