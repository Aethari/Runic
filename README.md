**Disclaimer:** Runic is only in a semi-usable state at the
moment, so if you are cloning now don't expect it to be
super functional.

# Runic - A minimalist text editor written in pure Lua
See the [doc](doc/) directory for some (very simple)
documentation

## Todo
#### Drawing
- stop flickering / other drawing "artifacts" - make drawing
  smoother
- draw an asterisk (*) after the filename if the file has
  changes that have not been saved (use a state boolean, like a
  "saved" var or something that is set to false when a character
  is inserted, and set to true when the file is saved)

#### Input
- find a way to listen for esc key presses separate from other
  esc sequences - right now it just crashes the program
- undo/redo
- find/replace
- cut/copy/paste (start by implementing basic line removal - 
  nothing to do with the clipboard yet)
- highlighting/selection

#### Commands
- make the line command scroll down / adjust `buff.offset` if
  the line is off of the screen

#### File management
- implement file finder (separate buffer? command line stuff?
  idk)

## Known bugs
#### Rendering/drawing
- "artifacting" of sorts occurs when spamming inputs (reproduce
  by opening file and rapid-fire type a bunch of chars)

#### Command input
- After navigating down through more recent commands and
  reaching the newest command (empty), the first time
  navigating up through older commands, the most recently
  sent command is skipped (this is so niche we may not need to
  fix it lol)

## License
Runic is licensed under the MIT License  
See [LICENSE.txt](LICENSE.txt) for more license info
