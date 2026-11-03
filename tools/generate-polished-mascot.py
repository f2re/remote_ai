#!/usr/bin/env python3
"""Generate the canonical Remote AI polished pixel-cloud mascot.

This script is intentionally dependency-free. It creates the six runtime PNG
states, the README/documentation contact sheet, an AppIcon SVG that embeds the
same mascot, and a Swift source file containing the exact generated PNG bytes.
That keeps runtime, app icon, documentation and release snapshots on one source
of truth.
"""
from __future__ import annotations

import argparse
import base64
import binascii
import re
import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SIZE = 64
SCALE = 8
OUT = 512

PALETTE = {
    "transparent": (0, 0, 0, 0),
    "outline": (20, 34, 82, 255),
    "outline2": (28, 47, 104, 255),
    "body": (220, 230, 255, 255),
    "body_hi": (248, 251, 255, 255),
    "body_mid": (198, 214, 255, 255),
    "body_shadow": (151, 181, 255, 255),
    "body_deep": (105, 145, 244, 255),
    "cheek": (255, 157, 171, 255),
    "gold": (255, 190, 48, 255),
    "gold_hi": (255, 225, 96, 255),
    "lavender": (188, 190, 255, 255),
    "red": (255, 83, 96, 255),
    "red_dark": (180, 42, 61, 255),
    "white": (255, 255, 255, 255),
}

# One canonical stepped cloud silhouette shared by every state.
SPANS = {
    18:(28,35), 19:(25,38), 20:(23,40), 21:(22,41), 22:(20,43),
    23:(18,45), 24:(17,46), 25:(16,47), 26:(14,49), 27:(13,50),
    28:(12,51), 29:(11,52), 30:(10,53), 31:(9,54), 32:(8,55),
    33:(7,56), 34:(6,57), 35:(6,58), 36:(5,58), 37:(5,59),
    38:(4,59), 39:(4,60), 40:(4,60), 41:(4,60), 42:(4,60),
    43:(5,59), 44:(6,58), 45:(7,57), 46:(8,56), 47:(10,54),
    48:(12,52), 49:(15,49),
}


def canvas():
    return [[PALETTE["transparent"] for _ in range(SIZE)] for _ in range(SIZE)]


def setpx(img, x, y, c):
    if 0 <= x < SIZE and 0 <= y < SIZE:
        img[y][x] = PALETTE[c] if isinstance(c, str) else c


def rect(img, x0, y0, x1, y1, c):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            setpx(img, x, y, c)


def line(img, pts, c):
    for x, y in pts:
        setpx(img, x, y, c)


def cloud_mask():
    mask = [[False for _ in range(SIZE)] for _ in range(SIZE)]
    for y, (x0, x1) in SPANS.items():
        for x in range(x0, x1 + 1):
            mask[y][x] = True
    return mask


def base_cloud():
    img = canvas()
    mask = cloud_mask()
    # 8-neighbour outline gives the dark stepped edge seen in the approved art.
    for y in range(SIZE):
        for x in range(SIZE):
            if not mask[y][x]:
                continue
            edge = False
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    nx, ny = x + dx, y + dy
                    if not (0 <= nx < SIZE and 0 <= ny < SIZE) or not mask[ny][nx]:
                        edge = True
            setpx(img, x, y, "outline" if edge else "body")

    # Volumetric cool shadows and glossy highlights, clipped to silhouette.
    def paint_if(x0,y0,x1,y1,c):
        for y in range(y0,y1+1):
            for x in range(x0,x1+1):
                if 0 <= y < SIZE and 0 <= x < SIZE and mask[y][x] and img[y][x] != PALETTE["outline"]:
                    setpx(img,x,y,c)
    paint_if(8,39,56,48,"body_mid")
    paint_if(11,44,53,49,"body_shadow")
    paint_if(17,47,47,49,"body_deep")
    paint_if(13,29,17,36,"body_shadow")
    paint_if(47,31,53,38,"body_mid")
    paint_if(22,22,28,27,"body_hi")
    paint_if(18,28,22,31,"body_hi")
    paint_if(29,20,34,23,"body_hi")
    paint_if(37,24,41,27,"body_mid")
    return img


def open_eyes(img):
    rect(img, 22, 34, 25, 38, "outline")
    rect(img, 39, 34, 42, 38, "outline")
    setpx(img, 23, 35, "white"); setpx(img, 40, 35, "white")


def closed_eyes(img):
    line(img, [(21,35),(22,36),(23,37),(24,37),(25,36),(26,35)], "outline")
    line(img, [(38,35),(39,36),(40,37),(41,37),(42,36),(43,35)], "outline")


def cheeks(img):
    rect(img, 17, 39, 20, 41, "cheek")
    rect(img, 44, 39, 47, 41, "cheek")


def smile(img):
    line(img, [(29,39),(29,40),(30,41),(31,41),(32,41),(33,41),(34,40),(34,39)], "outline")


def sleep_mouth(img):
    line(img, [(30,40),(31,41),(32,41),(33,40)], "outline")


def worried(img):
    open_eyes(img)
    line(img, [(21,32),(22,31),(23,31),(24,32)], "outline")
    line(img, [(40,32),(41,31),(42,31),(43,32)], "outline")
    rect(img, 29, 40, 34, 43, "outline")
    rect(img, 30, 41, 33, 42, "cheek")


def z_marks(img):
    for ox, oy, s in [(43,22,1),(48,16,2)]:
        for i in range(4*s): setpx(img, ox+i, oy, "lavender")
        for i in range(4*s): setpx(img, ox+3*s-i, oy+i, "lavender")
        for i in range(4*s): setpx(img, ox+i, oy+3*s, "lavender")


def gold_rays(img, x=48, y=23):
    rect(img,x,y-5,x+1,y-2,"gold_hi")
    rect(img,x+4,y-3,x+6,y-2,"gold")
    rect(img,x+6,y+1,x+8,y+2,"gold")


def thought_bubble(img):
    # little ellipsis bubble, matching the approved promo language.
    rect(img,45,20,53,25,"body_hi")
    rect(img,44,21,54,24,"body_hi")
    for x in (47,50,53): setpx(img,x,22,"outline")
    setpx(img,43,27,"body_hi"); setpx(img,41,29,"body_hi")


def sync_ring(img):
    # Pixel circular-arrow orbit surrounding the same cloud body.
    for x,y in [
        (13,17),(14,16),(15,15),(16,14),(17,13),(18,12),(19,12),(20,11),
        (44,11),(45,12),(46,12),(47,13),(48,14),(49,15),(50,16),(51,17),
        (55,22),(56,24),(57,26),(58,28),(59,30),(59,32),(59,34),
        (54,50),(53,51),(52,52),(51,53),(50,54),(49,55),(47,56),(45,57),
        (18,57),(16,56),(14,55),(13,54),(12,53),(11,52),(10,51),(9,50),
        (5,43),(4,41),(4,39),(4,37),(4,35),(4,33),(5,31)
    ]: setpx(img,x,y,"lavender")
    # arrow heads
    line(img,[(12,17),(12,14),(9,17),(12,20)],"lavender")
    line(img,[(52,54),(55,54),(52,57),(49,54)],"lavender")


def error_badge(img):
    # red stepped alert bubble with white exclamation.
    rect(img,46,17,54,25,"red")
    rect(img,45,19,55,23,"red")
    rect(img,47,25,49,27,"red_dark")
    rect(img,50,19,51,22,"white")
    setpx(img,50,24,"white"); setpx(img,51,24,"white")


def render_state(state):
    img = base_cloud()
    cheeks(img)
    if state == "offline":
        closed_eyes(img); sleep_mouth(img); z_marks(img)
    elif state == "connecting":
        open_eyes(img); smile(img); gold_rays(img)
    elif state == "syncing":
        open_eyes(img); smile(img); sync_ring(img)
    elif state == "thinking":
        open_eyes(img); smile(img); thought_bubble(img)
    elif state == "waiting":
        open_eyes(img); smile(img); gold_rays(img,49,22)
    elif state == "error":
        worried(img); error_badge(img)
    else:
        raise ValueError(state)
    return img


def png_bytes(img, scale=SCALE):
    w=h=SIZE*scale
    raw=bytearray()
    for y in range(SIZE):
        row=[]
        for x in range(SIZE): row.extend(img[y][x])
        expanded=bytearray()
        for x in range(SIZE):
            px=bytes(row[x*4:x*4+4])
            expanded.extend(px*scale)
        for _ in range(scale):
            raw.append(0); raw.extend(expanded)
    def chunk(t,d):
        return struct.pack(">I",len(d))+t+d+struct.pack(">I",binascii.crc32(t+d)&0xffffffff)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR",struct.pack(">IIBBBBB",w,h,8,6,0,0,0)) + chunk(b"IDAT",zlib.compress(bytes(raw),9)) + chunk(b"IEND",b"")


def write_pngs():
    out = ROOT / "Resources" / "Mascot"
    out.mkdir(parents=True, exist_ok=True)
    states = ["offline","connecting","syncing","thinking","waiting","error"]
    payloads={}
    for state in states:
        data=png_bytes(render_state(state))
        (out/f"mascot-{state}.png").write_bytes(data)
        payloads[state]=data
    return payloads


def make_sheet(payloads):
    # Documentation sheet is produced from the same logical sprites, no separate artwork.
    cell_w, cell_h = 72, 80
    w, h = cell_w*6, cell_h
    bg=(23,27,46,255)
    pix=[[bg for _ in range(w)] for _ in range(h)]
    states=["offline","connecting","syncing","thinking","waiting","error"]
    for idx,state in enumerate(states):
        sprite=render_state(state)
        ox=idx*cell_w+4; oy=4
        for y in range(SIZE):
            for x in range(SIZE):
                c=sprite[y][x]
                if c[3]: pix[oy+y][ox+x]=c
    # encode arbitrary-size RGBA sheet
    raw=bytearray()
    for row in pix:
        raw.append(0)
        for c in row: raw.extend(c)
    def chunk(t,d): return struct.pack(">I",len(d))+t+d+struct.pack(">I",binascii.crc32(t+d)&0xffffffff)
    data=b"\x89PNG\r\n\x1a\n"+chunk(b"IHDR",struct.pack(">IIBBBBB",w,h,8,6,0,0,0))+chunk(b"IDAT",zlib.compress(bytes(raw),9))+chunk(b"IEND",b"")
    p=ROOT/"docs"/"screenshots"/"mascot-v2-states.png"; p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(data)


def make_app_icon(waiting_png):
    enc=base64.b64encode(waiting_png).decode()
    svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#16244f"/><stop offset="0.55" stop-color="#55479c"/><stop offset="1" stop-color="#d98ba8"/></linearGradient></defs>
  <rect x="64" y="64" width="896" height="896" rx="220" fill="url(#bg)"/>
  <image x="116" y="116" width="792" height="792" image-rendering="pixelated" href="data:image/png;base64,{enc}"/>
</svg>\n'''
    (ROOT/"Resources"/"AppIcon.svg").write_text(svg)


def make_swift(payloads):
    labels={"offline":"Отключён","connecting":"Подключается","syncing":"Синхронизирует","thinking":"Думает","waiting":"Ждёт ввода","error":"Ошибка"}
    chunks=[]
    for state,data in payloads.items():
        b64=base64.b64encode(data).decode()
        wrapped="\n".join(b64[i:i+120] for i in range(0,len(b64),120))
        chunks.append(f'''    private static let {state}Base64 = """\n{wrapped}\n    """''')
    src='''import AppKit\nimport Foundation\nimport SwiftUI\n\n/// Canonical polished pixel-cloud artwork. Generated by tools/generate-polished-mascot.py.\nenum PolishedMascotAssets {\n'''+"\n".join(chunks)+'''\n\n    private static func decode(_ value: String) -> NSImage {\n        guard let data = Data(base64Encoded: value, options: .ignoreUnknownCharacters),\n              let image = NSImage(data: data) else {\n            return NSImage(size: NSSize(width: 1, height: 1))\n        }\n        image.isTemplate = false\n        return image\n    }\n\n    static let offline = decode(offlineBase64)\n    static let connecting = decode(connectingBase64)\n    static let syncing = decode(syncingBase64)\n    static let thinking = decode(thinkingBase64)\n    static let waiting = decode(waitingBase64)\n    static let error = decode(errorBase64)\n\n    static func image(for state: MascotState) -> NSImage {\n        switch state {\n        case .offline: offline\n        case .connecting: connecting\n        case .syncing: syncing\n        case .thinking: thinking\n        case .waiting: waiting\n        case .error: error\n        }\n    }\n}\n\nfunc polishedMascotAccessibilityLabel(for state: MascotState) -> String {\n    switch state {\n    case .offline: "Отключён"\n    case .connecting: "Подключается"\n    case .syncing: "Синхронизирует"\n    case .thinking: "Думает"\n    case .waiting: "Ждёт ввода"\n    case .error: "Ошибка"\n    }\n}\n\nstruct PolishedMascotArtwork: View {\n    let state: MascotState\n    @Environment(\\.accessibilityReduceMotion) private var reduceMotion\n    @State private var breathe = false\n    @State private var hovered = false\n\n    var body: some View {\n        Image(nsImage: PolishedMascotAssets.image(for: state))\n            .resizable()\n            .interpolation(.none)\n            .aspectRatio(contentMode: .fit)\n            .scaleEffect(hovered ? 1.045 : (breathe ? 1.018 : 1.0))\n            .offset(y: reduceMotion ? 0 : (breathe ? -1.2 : 0.8))\n            .shadow(color: .black.opacity(0.18), radius: 5, y: 3)\n            .onHover { hovered = $0 }\n            .onAppear {\n                guard !reduceMotion else { return }\n                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { breathe = true }\n            }\n            .animation(.easeOut(duration: 0.14), value: hovered)\n            .animation(.easeInOut(duration: 0.18), value: state)\n            .accessibilityHidden(true)\n    }\n}\n'''
    (ROOT/"Sources"/"RemoteAI"/"PolishedMascotAssets.swift").write_text(src)


def matching_brace(text, open_at):
    depth=0
    for i in range(open_at,len(text)):
        if text[i]=='{': depth+=1
        elif text[i]=='}':
            depth-=1
            if depth==0: return i
    raise RuntimeError("unbalanced Swift braces")


def patch_mascot_view():
    path=ROOT/"Sources"/"RemoteAI"/"MascotView.swift"
    text=path.read_text()
    if "PolishedMascotArtwork(state:" in text:
        return
    struct_m=re.search(r"struct\s+MascotView\s*:\s*View\s*\{",text)
    if not struct_m: raise RuntimeError("MascotView struct not found")
    struct_open=text.find('{',struct_m.start()); struct_end=matching_brace(text,struct_open)
    segment=text[struct_open:struct_end]
    state_m=re.search(r"(?:let|var)\s+(\w+)\s*:\s*MascotState\b",segment)
    action_m=re.search(r"(?:let|var)\s+(\w+)\s*:\s*\(\s*\)\s*->\s*Void",segment)
    if not state_m or not action_m:
        raise RuntimeError("MascotView state/action properties not found; refusing an unsafe rewrite")
    state_name=state_m.group(1); action_name=action_m.group(1)
    body_m=re.search(r"var\s+body\s*:\s*some\s+View\s*\{",segment)
    if not body_m: raise RuntimeError("MascotView body not found")
    body_abs=struct_open+body_m.start(); body_open=text.find('{',body_abs); body_end=matching_brace(text,body_open)
    replacement=f'''var body: some View {{\n        Button(action: {action_name}) {{\n            PolishedMascotArtwork(state: {state_name})\n                .frame(width: 68, height: 68)\n                .contentShape(Rectangle())\n        }}\n        .buttonStyle(.plain)\n        .accessibilityLabel(Text(polishedMascotAccessibilityLabel(for: {state_name})))\n    }}'''
    text=text[:body_abs]+replacement+text[body_end+1:]
    path.write_text(text)


def patch_version_and_docs():
    plist=ROOT/"Resources"/"Info.plist"
    if plist.exists():
        t=plist.read_text()
        t=re.sub(r'(<key>CFBundleShortVersionString</key>\s*<string>)[^<]+(</string>)',r'\g<1>0.2.2\2',t)
        plist.write_text(t)
    readme=ROOT/"README.md"
    if readme.exists():
        t=readme.read_text()
        local='docs/screenshots/mascot-v2-states.png'
        t=re.sub(r'https://github\.com/f2re/remote_ai/releases/download/v[0-9.]+/mascot-states-light\.png',local,t)
        if 'mascot-v2-states.png' not in t:
            marker='## Состояния маскота'
            pos=t.find(marker)
            if pos>=0:
                insert='\n<p align="center"><img src="docs/screenshots/mascot-v2-states.png" width="860" alt="Новый пиксельный облачный маскот Remote AI — шесть состояний"></p>\n'
                t=t[:pos+len(marker)]+insert+t[pos+len(marker):]
        readme.write_text(t)
    shots=ROOT/"docs"/"SCREENSHOTS.md"
    if shots.exists():
        t=shots.read_text()
        block='''\n## Канонический маскот v2\n\nНовый runtime-маскот генерируется из единственного воспроизводимого источника `tools/generate-polished-mascot.py`. Все шесть состояний используют одну геометрию облака, тёмный пиксельный контур, холодное объёмное затенение, розовые щёки и отдельные понятные state-маркеры. Канонический лист: [`screenshots/mascot-v2-states.png`](screenshots/mascot-v2-states.png). AppIcon и runtime используют те же данные.\n'''
        if '## Канонический маскот v2' not in t: t+=block
        shots.write_text(t)
    kit=ROOT/"design"/"KIT.md"
    if kit.exists():
        t=kit.read_text()
        block='''\n\n## Polished Pixel Cloud v2\n\nКанонический персонаж — объёмное пиксельное облако с единым силуэтом для всех состояний. Нельзя заменять его упрощённой белой геометрией. Состояния отличаются только лицом и компактным маркером: Z — offline, золотые лучи — connecting/waiting, орбита — syncing, облачко мысли — thinking, красный alert — error. Источник ассетов: `tools/generate-polished-mascot.py`; PNG: `Resources/Mascot/`.\n'''
        if '## Polished Pixel Cloud v2' not in t: t+=block
        kit.write_text(t)


def make_tests():
    p=ROOT/"Tests"/"RemoteAITests"/"PolishedMascotAssetTests.swift"
    p.write_text('''import XCTest\n@testable import RemoteAI\n\nfinal class PolishedMascotAssetTests: XCTestCase {\n    func testAllStatesDecodeToFullSizeImages() {\n        let states: [MascotState] = [.offline, .connecting, .syncing, .thinking, .waiting, .error]\n        for state in states {\n            let image = PolishedMascotAssets.image(for: state)\n            XCTAssertEqual(image.size.width, 512, accuracy: 0.1)\n            XCTAssertEqual(image.size.height, 512, accuracy: 0.1)\n        }\n    }\n}\n''')


def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--apply',action='store_true'); args=ap.parse_args()
    payloads=write_pngs(); make_sheet(payloads); make_app_icon(payloads['waiting']); make_swift(payloads)
    if args.apply:
        patch_mascot_view(); patch_version_and_docs(); make_tests()
    print('generated polished mascot:', ', '.join(payloads))

if __name__=='__main__': main()
