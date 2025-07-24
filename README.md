# Runic - A minimalist text editor written in pure Lua

## Todo
#### Drawing
- instead of using tabstops, print 4 spaces when a tab characer
  is found

#### Input
- find a way to listen for esc key presses separate from other
  esc sequences
- undo/redo

#### Commands
- make a list of available commands
- implement basic, existing editor functions as commands
  (opening/saving files, closing editor, etc.)

#### File management
- implement file finder (separate buffer? command line stuff?
  idk) 

#### Other
- implement different modes (edit and nav modes)

## Known bugs
#### Rendering/drawing
- "artifacting" of sorts when spamming inputs (reproduce by
  opening file and rapid-fire type a bunch of chars)

#### Command input
- After navigating down through more recent commands and
  reaching the newest command (empty), the first time
  navigating up through older commands, the most recently
  sent command is sent (this is so niche we may not need to
  fix it lol)

## License
Runic is licensed under the MIT License  
See [LICENSE.txt](LICENSE.txt) for more license info
