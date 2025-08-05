# ⌨️ 34-Key ZMK Layout (Ferris Sweep 🦀)

My personal keymap for the Ferris Sweep using [ZMK](https://zmk.dev/), drawn with [keymap-drawer](https://github.com/caksoylar/keymap-drawer).

## 🧠 Design Philosophy

- My keymap tries to retain some familiar QWERTY features — for example, using the top row for numbers and symbols, similar to a traditional layout.
- Naturally, with a 34-key layout, not everything can be replicated, but I aim to keep frequently used characters close to the home row — such as []{}\_-|:),
  and also to the thumb key the ones that i use most (space, backspace, ctrl, tab)
- I use combos too, and in some cases I’ve added duplicate combos (like Enter or Escape) for one-handed use (when using mouse) — The ones that i really use (mostly) are on right_hand
- 🔴Currently, function keys are not included in my keymap. I haven’t missed them yet, but I’ll add them when I do.

## 🎯 Key Features

- ⌨️ **Home-row mods** inspired by [urob's timeless layout](https://github.com/urob/zmk-config)
  - 🧠 **Hold-tap logic** with tuned tapping terms and release conditions
- 🎨 **Small combo keys** (Enter, Esc, Cut/Copy/Paste, Mouse toggle, Numpad)
- 🎛️ Multi-layered:
  - **BASE**: QWERTY with mod tap
  - **SYMBOL**: Symbols and punctuation (Top row on qwerty)
  - **NAVIGATION_NUMBER**: Number rows, with vim-style navigation
  - **MOUSE**: Mouse related
  - **SETTINGS**: Bluetooth, bootloader, reset
  - **ONE-HAND NUMPAD** layer for quick entry

## 🖼️ Layer Map

<img src="./keymap-drawer/cradio.svg?raw=true" alt="My personal keymap" width="600">
