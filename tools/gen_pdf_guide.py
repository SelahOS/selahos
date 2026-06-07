#!/usr/bin/env python3
"""
Generates SELAH-30 Apps Installation & Usage Guide PDF.
Run: python3 tools/gen_pdf_guide.py
"""

from fpdf import FPDF
from fpdf.enums import XPos, YPos
import os

# ── Selah brand palette ─────────────────────────────────────────────────────
BG         = (11,  15, 26)
PANEL      = (19,  25, 38)
GOLD       = (214, 168, 90)
TEAL       = (142, 195, 184)
TEXT       = (237, 228, 212)
TEXT_SEC   = (154, 141, 123)
BORDER     = (42,  48, 66)
CODE_BG    = (15,  20, 32)
WHITE      = (255, 255, 255)

OUT_PATH   = os.path.join(os.path.dirname(__file__), "..", "SelahOS-Apps-Guide.pdf")


class SelahPDF(FPDF):
    def __init__(self):
        super().__init__(orientation="P", unit="mm", format="A4")
        self.set_auto_page_break(auto=True, margin=20)
        self.set_margins(20, 20, 20)

    # ── Helpers ────────────────────────────────────────────────────────────

    # Map characters that fall outside latin-1 to ASCII equivalents
    _CHAR_MAP = {
        "—": "--",   # em dash
        "–": "-",    # en dash
        "·": "*",    # middle dot
        "•": "*",    # bullet
        "●": "*",
        "▼": "[v]",
        "▲": "[^]",
        "►": ">",
        "←": "<-",
        "→": "->",
        "↻": "[r]",  # clockwise arrow (reload)
        "✕": "x",    # multiplication x (close)
        "＋": "+",    # fullwidth plus
        "◼": "[stop]",
        "△": "[send]",
        "✦": "*",    # four-pointed star (Selah logo)
        "⚡": "[!]",  # lightning bolt
        "\U0001f50b": "[bat]",  # battery emoji
        "✔": "[ok]",
        "◄": "<",
        "►": ">",
        "¶": "",
        "‘": "'",
        "’": "'",
        "“": '"',
        "”": '"',
    }

    @staticmethod
    def _s(text: str) -> str:
        result = []
        for ch in text:
            mapped = SelahPDF._CHAR_MAP.get(ch)
            if mapped is not None:
                result.append(mapped)
            else:
                try:
                    ch.encode("latin-1")
                    result.append(ch)
                except (UnicodeEncodeError, ValueError):
                    result.append("?")
        return "".join(result)

    def set_text_color_t(self, col): self.set_text_color(*col)
    def set_fill_color_t(self, col): self.set_fill_color(*col)
    def set_draw_color_t(self, col): self.set_draw_color(*col)

    # Auto-sanitize all text going into cells
    def cell(self, w=0, h=0, text="", *args, **kwargs):
        return super().cell(w, h, self._s(str(text)), *args, **kwargs)

    def multi_cell(self, w, h, text="", *args, **kwargs):
        return super().multi_cell(w, h, self._s(str(text)), *args, **kwargs)

    def rule(self, color=BORDER):
        self.set_draw_color_t(color)
        self.set_line_width(0.3)
        self.line(self.l_margin, self.get_y(), self.w - self.r_margin, self.get_y())
        self.ln(4)

    def spacer(self, h=4): self.ln(h)

    # ── Header / footer ────────────────────────────────────────────────────

    def header(self):
        if self.page_no() == 1:
            return
        self.set_fill_color_t(PANEL)
        self.rect(0, 0, self.w, 12, style="F")
        self.set_font("Helvetica", "B", 8)
        self.set_text_color_t(GOLD)
        self.set_y(3)
        self.cell(0, 6, self._s("SelahOS Native Apps -- Installation & Usage Guide"),
                  align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_y(14)

    def footer(self):
        self.set_y(-14)
        self.set_draw_color_t(BORDER)
        self.set_line_width(0.3)
        self.line(self.l_margin, self.get_y(), self.w - self.r_margin, self.get_y())
        self.set_font("Helvetica", "", 8)
        self.set_text_color_t(TEXT_SEC)
        self.cell(0, 8, self._s(f"Page {self.page_no()} * Selah Technologies LLC * selahos.com"),
                  align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    # ── Cover ──────────────────────────────────────────────────────────────

    def cover(self):
        self.add_page()
        # Full-page dark background
        self.set_fill_color_t(BG)
        self.rect(0, 0, self.w, self.h, style="F")

        # Gold top accent bar
        self.set_fill_color_t(GOLD)
        self.rect(0, 0, self.w, 3, style="F")

        # App name
        self.set_y(42)
        self.set_font("Helvetica", "B", 36)
        self.set_text_color_t(GOLD)
        self.cell(0, 14, self._s("SelahOS"), align="C",
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)

        self.set_font("Helvetica", "", 20)
        self.set_text_color_t(TEXT)
        self.cell(0, 10, self._s("Native Apps"), align="C",
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)

        self.spacer(6)
        self.set_font("Helvetica", "I", 13)
        self.set_text_color_t(TEAL)
        self.cell(0, 8, self._s("Installation & Usage Guide"), align="C",
                  new_x=XPos.LMARGIN, new_y=YPos.NEXT)

        # Divider
        self.spacer(10)
        self.set_draw_color_t(GOLD)
        self.set_line_width(0.6)
        cx = self.w / 2
        self.line(cx - 40, self.get_y(), cx + 40, self.get_y())
        self.spacer(12)

        # App cards
        apps = [
            ("SelahBrowser", "WebKit-powered browser with ad blocking"),
            ("Muse",         "Claude AI assistant  ·  Meta+M"),
            ("Omolara",      "ChatGPT assistant    ·  Meta+O"),
        ]
        for name, desc in apps:
            self.set_fill_color_t(PANEL)
            self.set_draw_color_t(BORDER)
            self.set_line_width(0.3)
            x = self.l_margin + 15
            w = self.w - 2 * self.l_margin - 30
            self.rect(x, self.get_y(), w, 18, style="FD")
            self.set_font("Helvetica", "B", 13)
            self.set_text_color_t(GOLD)
            self.set_x(x + 6)
            ty = self.get_y() + 4
            self.set_y(ty)
            self.set_x(x + 6)
            self.cell(w - 12, 5, name,
                      new_x=XPos.LMARGIN, new_y=YPos.NEXT)
            self.set_font("Helvetica", "", 10)
            self.set_text_color_t(TEXT_SEC)
            self.set_x(x + 6)
            self.cell(w - 12, 5, desc,
                      new_x=XPos.LMARGIN, new_y=YPos.NEXT)
            self.spacer(5)

        # Bottom meta
        self.set_y(-38)
        self.set_font("Helvetica", "", 9)
        self.set_text_color_t(TEXT_SEC)
        self.cell(0, 6, "SELAH-30  ·  Selah Technologies LLC  ·  selahos.com",
                  align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_font("Helvetica", "", 9)
        self.cell(0, 6, "Build: C++17 · Qt6 · WebKit2GTK · SQLite · XCB",
                  align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)

        # Gold bottom bar
        self.set_fill_color_t(GOLD)
        self.rect(0, self.h - 3, self.w, 3, style="F")

    # ── Section heading ────────────────────────────────────────────────────

    def section(self, title, color=GOLD):
        title = self._s(title)
        self.spacer(6)
        self.set_fill_color_t(PANEL)
        self.rect(self.l_margin, self.get_y(), self.w - 2 * self.l_margin, 9, style="F")
        self.set_fill_color_t(color)
        self.rect(self.l_margin, self.get_y(), 3, 9, style="F")
        self.set_font("Helvetica", "B", 13)
        self.set_text_color_t(color)
        self.set_x(self.l_margin + 7)
        self.cell(0, 9, title, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.spacer(4)

    def subsection(self, title):
        title = self._s(title)
        self.spacer(3)
        self.set_font("Helvetica", "B", 11)
        self.set_text_color_t(TEAL)
        self.cell(0, 7, title, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.spacer(1)

    def body(self, text, indent=0):
        text = self._s(text)
        self.set_font("Helvetica", "", 10)
        self.set_text_color_t(TEXT)
        self.set_x(self.l_margin + indent)
        self.multi_cell(self.w - 2 * self.l_margin - indent, 5.5, text,
                        new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.spacer(1)

    def bullet(self, text, indent=4):
        text = self._s(text)
        self.set_x(self.l_margin + indent)
        bw = self.w - 2 * self.l_margin - indent - 4
        self.set_font("Helvetica", "B", 12)
        self.set_text_color_t(GOLD)
        self.cell(5, 5.5, "-", new_x=XPos.RIGHT, new_y=YPos.TOP)
        self.set_font("Helvetica", "", 10)
        self.set_text_color_t(TEXT)
        self.multi_cell(bw, 5.5, text, new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    def code(self, lines):
        if isinstance(lines, str):
            lines = lines.strip().splitlines()
        lines = [self._s(l) for l in lines]
        pad = 5
        lh  = 5.5
        bh  = pad + lh * len(lines) + pad
        bx  = self.l_margin
        bw  = self.w - 2 * self.l_margin
        by  = self.get_y()

        self.set_fill_color_t(CODE_BG)
        self.set_draw_color_t(BORDER)
        self.set_line_width(0.25)
        self.rect(bx, by, bw, bh, style="FD")

        self.set_font("Courier", "", 9)
        self.set_text_color_t(TEAL)
        self.set_y(by + pad)
        for line in lines:
            self.set_x(bx + pad)
            self.cell(bw - 2 * pad, lh, line,
                      new_x=XPos.LMARGIN, new_y=YPos.NEXT)

        self.set_y(by + bh + 3)

    def note(self, text, color=TEAL):
        text = self._s(text)
        bx = self.l_margin
        bw = self.w - 2 * self.l_margin
        by = self.get_y()
        self.set_font("Helvetica", "I", 9.5)
        line_count = max(1, len(text) // 90 + 1)
        bh = 5 * line_count + 12
        self.set_fill_color(*(c // 6 for c in color))
        self.set_draw_color_t(color)
        self.set_line_width(0.25)
        self.rect(bx, by, bw, bh, style="FD")
        self.set_fill_color_t(color)
        self.rect(bx, by, 3, bh, style="F")
        self.set_font("Helvetica", "I", 9.5)
        self.set_text_color_t(TEXT)
        self.set_y(by + 5)
        self.set_x(bx + 8)
        self.multi_cell(bw - 14, 5, text,
                        new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        self.set_y(by + bh + 3)
        self.spacer(1)


# ── Document content ──────────────────────────────────────────────────────────

def build(pdf: SelahPDF):

    # ── COVER ─────────────────────────────────────────────────────────────
    pdf.cover()

    # ── TOC ───────────────────────────────────────────────────────────────
    pdf.add_page()
    pdf.set_fill_color_t(BG)
    pdf.rect(0, 0, pdf.w, pdf.h, style="F")

    pdf.spacer(6)
    pdf.set_font("Helvetica", "B", 18)
    pdf.set_text_color_t(GOLD)
    pdf.cell(0, 10, "Table of Contents", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.rule()
    pdf.spacer(4)

    toc = [
        ("1",   "Prerequisites & Build Machine",      ""),
        ("2",   "SelahBrowser",                         ""),
        ("2.1", "  Installation",                       ""),
        ("2.2", "  Configuration",                      ""),
        ("2.3", "  Using SelahBrowser",                 ""),
        ("3",   "Muse  (Claude AI)",                    ""),
        ("3.1", "  Installation",                       ""),
        ("3.2", "  API Key Setup",                      ""),
        ("3.3", "  Using Muse",                         ""),
        ("4",   "Omolara  (ChatGPT)",                   ""),
        ("4.1", "  Installation",                       ""),
        ("4.2", "  API Key Setup",                      ""),
        ("4.3", "  Using Omolara",                      ""),
        ("5",   "Shared Configuration",                 ""),
        ("6",   "Building from Source",                 ""),
        ("7",   "Adding Apps to the ISO",               ""),
        ("8",   "Troubleshooting",                      ""),
    ]

    for num, title, _ in toc:
        pdf.set_font("Helvetica", "B" if "." not in num else "", 10)
        color = GOLD if "." not in num else TEXT
        pdf.set_text_color_t(color)
        pdf.set_x(pdf.l_margin + (8 if "." in num else 0))
        pdf.cell(12, 7, num, new_x=XPos.RIGHT, new_y=YPos.TOP)
        pdf.cell(0, 7, title, new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    # ── 1. PREREQUISITES ──────────────────────────────────────────────────
    pdf.add_page()
    pdf.set_fill_color_t(BG)
    pdf.rect(0, 0, pdf.w, pdf.h, style="F")

    pdf.section("1 · Prerequisites & Build Machine")
    pdf.body("All three apps are built with CMake + Ninja on the SelahOS build machine "
             "(Arch Linux, linux-zen kernel). They target the SelahOS live environment "
             "and are packaged directly into the ISO.")

    pdf.subsection("Required packages (installed by install-deps.sh)")
    deps = {
        "All apps": [
            "cmake >= 3.16",
            "ninja",
            "qt6-base, qt6-quick, qt6-quickcontrols2, qt6-declarative",
            "sqlite  (Qt SQL driver)",
            "xcb-util-keysyms, libxcb  (global hotkeys)",
            "pkgconf",
        ],
        "SelahBrowser only": [
            "webkit2gtk  (webkit2gtk-4.0, GTK3-based)",
        ],
    }
    for group, items in deps.items():
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_text_color_t(TEAL)
        pdf.cell(0, 6, group + ":", new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        for item in items:
            pdf.bullet(item)
        pdf.spacer(2)

    pdf.subsection("Build machine setup")
    pdf.code("""# On SelahOS (Arch Linux)
sudo pacman -Syu
cd ~/selahbrowser && bash install-deps.sh
cd ~/muse         && bash install-deps.sh
cd ~/omolara      && bash install-deps.sh""")

    pdf.note("These scripts call pacman --needed so re-running is safe.")

    # ── 2. SELAHBROWSER ───────────────────────────────────────────────────
    pdf.section("2 · SelahBrowser", GOLD)
    pdf.body("SelahBrowser is a Qt6-native web browser using WebKit2GTK for rendering. "
             "The Qt chrome (tab bar, address bar) sits above a WebKitView widget that "
             "renders pages via an offscreen GTK surface.")

    pdf.subsection("2.1  Installation")
    pdf.code("""git clone https://github.com/SelahOS/selahbrowser
cd selahbrowser
bash install-deps.sh          # installs webkit2gtk + qt6 deps
cmake -B build -G Ninja \\
      -DCMAKE_BUILD_TYPE=Release
ninja -C build
sudo ninja -C build install   # installs to /usr/bin/selahbrowser""")

    pdf.subsection("2.2  Configuration")
    pdf.body("SelahBrowser stores its settings in ~/.config/selah/browser/. "
             "On first launch the directory is created automatically.")
    pdf.bullet("Settings file: ~/.config/selah/browser/settings.ini")
    pdf.bullet("Ad-block rules: ~/.config/selah/browser/adblock.txt  (EasyList format)")
    pdf.bullet("Window geometry persists automatically across sessions.")
    pdf.spacer(3)
    pdf.code("""# Example settings.ini
[Browser]
home_page=https://search.brave.com
default_zoom=1.0
power_mode=performance    # or: battery""")

    pdf.subsection("2.3  Using SelahBrowser")
    features = [
        ("New tab",           "Click the + button in the tab bar, or Ctrl+T"),
        ("Close tab",         "Hover over tab → click ✕, or Ctrl+W"),
        ("Navigate",          "Click the address bar, type URL or search query, press Enter"),
        ("Search",            "Type a plain query in the address bar — routes to Brave Search"),
        ("Back / Forward",    "← → buttons in the toolbar"),
        ("Reload / Stop",     "↻ / ✕ button (changes during page load)"),
        ("Power mode",        "Click the ⚡Perf or 🔋Save pill to toggle"),
        ("Battery mode",      "Disables WebGL, HW acceleration, forces click-to-play media"),
        ("Tab auto-suspend",  "Tabs idle for 5+ minutes are suspended in Battery mode"),
        ("Ad blocking",       "Enabled by default — 25+ tracker domains + path patterns"),
        ("Find on page",      "Programmatic: browser.findText(\"query\") via QML API"),
        ("Zoom",              "Set in settings.ini; runtime: browser.setZoom(factor)"),
    ]
    for feat, desc in features:
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_text_color_t(GOLD)
        pdf.set_x(pdf.l_margin + 4)
        pdf.cell(46, 5.5, feat, new_x=XPos.RIGHT, new_y=YPos.TOP)
        pdf.set_font("Helvetica", "", 10)
        pdf.set_text_color_t(TEXT)
        pdf.multi_cell(pdf.w - pdf.l_margin - pdf.r_margin - 50, 5.5, desc,
                       new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    pdf.note("SelahBrowser uses webkit2gtk-4.0 (GTK3). "
             "Input forwarding and rendering work on X11/XWayland. "
             "Pure Wayland (no XWayland) requires a compositor subsurface integration "
             "not yet included in this release.")

    # ── 3. MUSE ───────────────────────────────────────────────────────────
    pdf.add_page()
    pdf.set_fill_color_t(BG)
    pdf.rect(0, 0, pdf.w, pdf.h, style="F")

    pdf.section("3 · Muse  (Claude AI Assistant)", GOLD)
    pdf.body("Muse is the SelahOS-native Claude interface. It lives in the system tray, "
             "springs open with Meta+M, and streams responses from the Anthropic API. "
             "Conversation history is stored locally in SQLite.")

    pdf.subsection("3.1  Installation")
    pdf.code("""git clone https://github.com/SelahOS/muse
cd muse
bash install-deps.sh
cmake -B build -G Ninja \\
      -DCMAKE_BUILD_TYPE=Release
ninja -C build
sudo ninja -C build install   # installs to /usr/bin/muse

# Auto-start with the session (optional)
cp resources/muse.desktop \\
   ~/.config/autostart/muse.desktop""")

    pdf.subsection("3.2  API Key Setup")
    pdf.body("Muse reads your Anthropic API key from two sources, checked in order:")
    pdf.bullet("Environment variable: ANTHROPIC_API_KEY")
    pdf.bullet("Settings file:  ~/.config/selah/muse/settings.ini")
    pdf.spacer(3)

    pdf.code("""# Option A — environment variable (recommended)
# Add to ~/.zshrc or ~/.bash_profile:
export ANTHROPIC_API_KEY="sk-ant-api03-..."

# Option B — settings file
mkdir -p ~/.config/selah/muse
cat > ~/.config/selah/muse/settings.ini << 'EOF'
[Muse]
api_key=sk-ant-api03-...
model=claude-sonnet-4-6
EOF""")

    pdf.note("The API key is never written back to disk by Muse. "
             "Option A (env var) keeps it out of any file on disk.")

    pdf.subsection("3.3  Using Muse")
    muse_feats = [
        ("Launch",           "muse starts minimised to tray. No window appears until triggered."),
        ("Show / hide",      "Press Meta+M (Super+M) from anywhere on the desktop."),
        ("Show via tray",    "Left-click or double-click the Muse tray icon."),
        ("Send message",     "Type in the input box at the bottom. Press Enter to send."),
        ("New line",         "Shift+Enter inserts a newline without sending."),
        ("Cancel stream",    "Click the ◼ stop button while the AI is responding."),
        ("New conversation", "Click the ＋ button in the top-right of the header bar."),
        ("Switch history",   "Click any conversation in the left sidebar."),
        ("Change model",     "Click the model pill (e.g. 'Sonnet 4.6') to cycle to Haiku."),
        ("Close window",     "Press Escape or close normally — app stays in tray."),
        ("Quit",             "Right-click tray icon → Quit."),
    ]
    for feat, desc in muse_feats:
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_text_color_t(GOLD)
        pdf.set_x(pdf.l_margin + 4)
        pdf.cell(42, 5.5, feat, new_x=XPos.RIGHT, new_y=YPos.TOP)
        pdf.set_font("Helvetica", "", 10)
        pdf.set_text_color_t(TEXT)
        pdf.multi_cell(pdf.w - pdf.l_margin - pdf.r_margin - 46, 5.5, desc,
                       new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    pdf.spacer(4)
    pdf.subsection("Available models")
    pdf.code("""claude-sonnet-4-6          # default — best quality
claude-haiku-4-5-20251001  # faster, cheaper""")

    # ── 4. OMOLARA ────────────────────────────────────────────────────────
    pdf.add_page()
    pdf.set_fill_color_t(BG)
    pdf.rect(0, 0, pdf.w, pdf.h, style="F")

    pdf.section("4 · Omolara  (ChatGPT Assistant)", GOLD)
    pdf.body("Omolara is the SelahOS-native OpenAI interface. Identical UX to Muse — "
             "tray app, streaming responses, local SQLite history — but powered by GPT-4o.")

    pdf.subsection("4.1  Installation")
    pdf.code("""git clone https://github.com/SelahOS/omolara
cd omolara
bash install-deps.sh
cmake -B build -G Ninja \\
      -DCMAKE_BUILD_TYPE=Release
ninja -C build
sudo ninja -C build install   # installs to /usr/bin/omolara

# Auto-start with the session (optional)
cp resources/omolara.desktop \\
   ~/.config/autostart/omolara.desktop""")

    pdf.subsection("4.2  API Key Setup")
    pdf.body("Omolara reads your OpenAI API key from:")
    pdf.bullet("Environment variable: OPENAI_API_KEY")
    pdf.bullet("Settings file:  ~/.config/selah/omolara/settings.ini")
    pdf.spacer(3)

    pdf.code("""# Option A — environment variable (recommended)
export OPENAI_API_KEY="sk-proj-..."

# Option B — settings file
mkdir -p ~/.config/selah/omolara
cat > ~/.config/selah/omolara/settings.ini << 'EOF'
[Omolara]
api_key=sk-proj-...
model=gpt-4o
EOF""")

    pdf.subsection("4.3  Using Omolara")
    omo_feats = [
        ("Launch",           "omolara starts minimised to tray."),
        ("Show / hide",      "Press Meta+O (Super+O) from anywhere on the desktop."),
        ("Show via tray",    "Left-click or double-click the Omolara tray icon."),
        ("Send message",     "Type in the input box. Press Enter to send."),
        ("New line",         "Shift+Enter inserts a newline without sending."),
        ("Cancel stream",    "Click the ◼ stop button while responding."),
        ("New conversation", "Click ＋ in the header."),
        ("Switch history",   "Click any conversation in the left sidebar."),
        ("Change model",     "Click the model pill to cycle between GPT-4o and GPT-4o mini."),
        ("Close window",     "Escape or close normally — stays in tray."),
        ("Quit",             "Right-click tray icon → Quit."),
    ]
    for feat, desc in omo_feats:
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_text_color_t(GOLD)
        pdf.set_x(pdf.l_margin + 4)
        pdf.cell(42, 5.5, feat, new_x=XPos.RIGHT, new_y=YPos.TOP)
        pdf.set_font("Helvetica", "", 10)
        pdf.set_text_color_t(TEXT)
        pdf.multi_cell(pdf.w - pdf.l_margin - pdf.r_margin - 46, 5.5, desc,
                       new_x=XPos.LMARGIN, new_y=YPos.NEXT)

    pdf.spacer(4)
    pdf.subsection("Available models")
    pdf.code("""gpt-4o       # default — best quality
gpt-4o-mini  # faster, cheaper""")

    # ── 5. SHARED CONFIG ──────────────────────────────────────────────────
    pdf.add_page()
    pdf.set_fill_color_t(BG)
    pdf.rect(0, 0, pdf.w, pdf.h, style="F")

    pdf.section("5 · Shared Configuration")
    pdf.body("All three apps store their data under ~/.config/selah/. "
             "Each app has its own subdirectory.")

    pdf.code("""~/.config/selah/
├── browser/
│   ├── settings.ini        # home page, zoom, power mode
│   └── adblock.txt         # custom EasyList rules (optional)
├── muse/
│   ├── settings.ini        # model preference (api_key optional)
│   └── history.db          # SQLite conversation history
└── omolara/
    ├── settings.ini        # model preference (api_key optional)
    └── history.db          # SQLite conversation history""")

    pdf.subsection("Resetting an app")
    pdf.code("""# Reset Muse (clears all history and settings)
rm -rf ~/.config/selah/muse

# Reset SelahBrowser (clears settings only, keeps adblock rules)
rm ~/.config/selah/browser/settings.ini""")

    pdf.note("history.db files are plain SQLite — you can open them with any SQLite browser "
             "(e.g. DB Browser for SQLite) to export, backup, or inspect conversations.")

    # ── 6. BUILDING FROM SOURCE ───────────────────────────────────────────
    pdf.section("6 · Building from Source")
    pdf.body("Each app is a standalone CMake project. No Makefile wrappers needed.")

    pdf.subsection("General build flow")
    pdf.code("""cd <app-directory>
cmake -B build -G Ninja \\
      -DCMAKE_BUILD_TYPE=Release \\
      -DCMAKE_INSTALL_PREFIX=/usr
ninja -C build
sudo ninja -C build install""")

    pdf.subsection("Debug build")
    pdf.code("""cmake -B build-debug -G Ninja \\
      -DCMAKE_BUILD_TYPE=Debug
ninja -C build-debug
./build-debug/<appname>   # run directly without installing""")

    pdf.subsection("Build outputs")
    pdf.bullet("Binary:      /usr/bin/<appname>")
    pdf.bullet(".desktop:    /usr/share/applications/<appname>.desktop")
    pdf.bullet("Icon:        /usr/share/icons/hicolor/scalable/apps/<appname>.svg")
    pdf.spacer(4)

    pdf.note("Qt6 moc and QML compilation happen automatically via CMake's "
             "qt_add_executable / qt_add_qml_module — no manual qmake steps needed.")

    # ── 7. ISO INTEGRATION ────────────────────────────────────────────────
    pdf.section("7 · Adding Apps to the ISO")
    pdf.body("To ship all three apps in the SelahOS ISO, add the following to the "
             "airootfs build process.")

    pdf.subsection("Build step in customize_airootfs.sh")
    pdf.code("""# Build and install all three apps into the ISO rootfs
for app in selahbrowser muse omolara; do
  cd /tmp/$app
  cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \\
        -DCMAKE_INSTALL_PREFIX=/usr
  ninja -C build
  DESTDIR=/mnt/airootfs ninja -C build install
done""")

    pdf.subsection("Package list additions  (packages.x86_64)")
    pdf.code("""webkit2gtk
qt6-base
qt6-quick
qt6-quickcontrols2
qt6-declarative
xcb-util-keysyms
sqlite""")

    pdf.subsection("Autostart entries for liveuser")
    pdf.code("""# In customize_airootfs.sh, after creating liveuser:
install -d /etc/skel/.config/autostart
install -m644 /usr/share/applications/muse.desktop \\
              /etc/skel/.config/autostart/
install -m644 /usr/share/applications/omolara.desktop \\
              /etc/skel/.config/autostart/""")

    pdf.note("SelahBrowser should NOT be set to autostart. "
             "Set it as the default browser in KDE System Settings → Applications → Web Browser.")

    # ── 8. TROUBLESHOOTING ────────────────────────────────────────────────
    pdf.add_page()
    pdf.set_fill_color_t(BG)
    pdf.rect(0, 0, pdf.w, pdf.h, style="F")

    pdf.section("8 · Troubleshooting")

    issues = [
        (
            "SelahBrowser shows a blank black screen",
            "The WebKitView offscreen surface hasn't rendered yet, or webkit2gtk failed "
            "to initialize. Check that webkit2gtk-4.0 (not 4.1) is installed:\n"
            "  pacman -Q webkit2gtk\n"
            "Run selahbrowser from a terminal to see GLib/WebKit error output.",
        ),
        (
            "SelahBrowser input (keyboard/mouse) not working",
            "Input forwarding uses GTK3 GdkEvent injection which requires X11/XWayland. "
            "If you're on a pure Wayland session with no XWayland, set:\n"
            "  DISPLAY=:0 selahbrowser\n"
            "or enable XWayland in your compositor config.",
        ),
        (
            "Meta+M / Meta+O hotkey not triggering",
            "XCB key grabs require X11. On Wayland, ensure XWayland is running. "
            "You can verify:\n"
            "  echo $DISPLAY   # should print :0 or similar\n"
            "If the key is grabbed by another app, the grab will silently fail.",
        ),
        (
            "Muse / Omolara: 'ANTHROPIC_API_KEY is not set'",
            "The API key is missing. Set it in your shell profile:\n"
            "  echo 'export ANTHROPIC_API_KEY=sk-ant-...' >> ~/.zshrc\n"
            "  source ~/.zshrc\n"
            "Then relaunch the app.",
        ),
        (
            "Muse / Omolara: network error / 401 Unauthorized",
            "Your API key is invalid or expired. Generate a new one at:\n"
            "  platform.anthropic.com  (Muse)\n"
            "  platform.openai.com     (Omolara)",
        ),
        (
            "Muse / Omolara: no tray icon visible",
            "KDE Plasma sometimes delays tray icon registration. "
            "Right-click the system tray → System Tray Settings → "
            "Extra Items and make sure Muse/Omolara are enabled.",
        ),
        (
            "CMake: 'webkit2gtk-4.0 not found'",
            "Install the package:\n"
            "  sudo pacman -S webkit2gtk\n"
            "Note: webkit2gtk and webkit2gtk-4.1 are different packages.",
        ),
        (
            "Qt6 modules not found during cmake",
            "Install the full Qt6 set:\n"
            "  sudo pacman -S qt6-base qt6-quick qt6-quickcontrols2 qt6-declarative\n"
            "Then re-run cmake (delete the build/ directory first).",
        ),
        (
            "history.db locked / can't open",
            "Another instance of the same app is running. "
            "Each app uses a unique database connection name, but two instances "
            "sharing the same db file will conflict. Kill the other instance:\n"
            "  pkill muse",
        ),
    ]

    for title, desc in issues:
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_text_color_t(TEAL)
        pdf.multi_cell(0, 5.5, title, new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        pdf.set_font("Helvetica", "", 10)
        pdf.set_text_color_t(TEXT)
        pdf.set_x(pdf.l_margin + 6)
        pdf.multi_cell(pdf.w - 2 * pdf.l_margin - 6, 5.5, desc,
                       new_x=XPos.LMARGIN, new_y=YPos.NEXT)
        pdf.spacer(5)

    # ── Back cover ────────────────────────────────────────────────────────
    pdf.add_page()
    pdf.set_fill_color_t(BG)
    pdf.rect(0, 0, pdf.w, pdf.h, style="F")
    pdf.set_fill_color_t(GOLD)
    pdf.rect(0, 0, pdf.w, 3, style="F")
    pdf.rect(0, pdf.h - 3, pdf.w, 3, style="F")

    pdf.set_y(pdf.h / 2 - 30)
    pdf.set_font("Helvetica", "B", 22)
    pdf.set_text_color_t(GOLD)
    pdf.cell(0, 12, "✦  Selah Technologies LLC", align="C",
             new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.set_font("Helvetica", "", 12)
    pdf.set_text_color_t(TEXT_SEC)
    pdf.cell(0, 8, "selahos.com", align="C",
             new_x=XPos.LMARGIN, new_y=YPos.NEXT)
    pdf.spacer(8)
    pdf.set_font("Helvetica", "", 10)
    pdf.set_text_color_t(TEXT_SEC)
    pdf.cell(0, 6, "Creator-first computing, built on Arch Linux.",
             align="C", new_x=XPos.LMARGIN, new_y=YPos.NEXT)


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    pdf = SelahPDF()
    build(pdf)
    pdf.output(OUT_PATH)
    print(f"PDF written → {os.path.abspath(OUT_PATH)}")


if __name__ == "__main__":
    main()
