-- Опциональная конфигурация окна Finder; вызывается только на смонтированном RW DMG.
-- Никаких путей, имён и пользовательского ввода в исполняемый AppleScript не интерполируется.
on run argv
    if (count of argv) is not 2 then error "Ожидаются имя тома и имя приложения."
    set volumeName to item 1 of argv
    set applicationName to item 2 of argv

    tell application "Finder"
        tell disk volumeName
            open
            set current view of container window to icon view
            set toolbar visible of container window to false
            set statusbar visible of container window to false
            set bounds of container window to {160, 160, 800, 520}

            set iconOptions to icon view options of container window
            set arrangement of iconOptions to not arranged
            set icon size of iconOptions to 128
            set text size of iconOptions to 14
            set background color of iconOptions to {65535, 65535, 65535}

            set position of item applicationName of container window to {168, 185}
            set position of item "Applications" of container window to {470, 185}
            update
            close
        end tell
    end tell
end run
