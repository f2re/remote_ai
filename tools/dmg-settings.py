"""Оформление DMG, не зависящее от Finder/Apple Events.

Запуск: dmgbuild -s tools/dmg-settings.py -D app=/abs/RemoteAI.app "Remote AI" output.dmg
"""
from pathlib import Path

application = Path(defines["app"]).resolve()  # noqa: F821 - переменная dmgbuild
if not application.is_dir() or application.suffix != ".app":
    raise ValueError("Для dmgbuild нужен существующий .app bundle")

files = [str(application)]
symlinks = {"Applications": "/Applications"}

# Строгая схема без GUI. Finder читает .DS_Store из готового образа.
format = "UDZO"
compression_level = 9
filesystem = "HFS+"
background = "#FFFFFF"
window_rect = ((160, 160), (640, 360))
default_view = "icon-view"
show_toolbar = False
show_status_bar = False
show_tab_view = False
show_pathbar = False
show_sidebar = False
show_icon_preview = True
arrange_by = None
icon_size = 128
text_size = 14
label_pos = "bottom"
icon_locations = {
    application.name: (168, 185),
    "Applications": (470, 185),
}
