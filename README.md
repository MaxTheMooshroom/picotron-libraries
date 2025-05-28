
# Picotron Libraries

This is a collection of libraries I've worked on for [Picotron](https://www.lexaloffle.com/picotron.php).

Will probably provide [Teal](https://teal-language.org/) type-definition files at some point.

## Libraries

- array - A library stub for working with wrapped [userdata](https://www.lexaloffle.com/dl/docs/picotron_userdata.html) to introduce [slices](https://en.wikipedia.org/wiki/Array_slicing) of userdata.
- extern - A place for 3rd-party libraries (such as [30log](https://github.com/Yonaba/30log)) to go.
- gfx - A graphics library I never went anywhere with or finished, mostly because of [AbledBody's Blade3D](https://github.com/abledbody/blade3d) library.
- struct - A library for parsing binary files using [DSDL](#), a __Data Structure Definition Language__, which lacks a lua implementation (And the EBNF isn't finished).
- sys - The meat and potatoes of this repo, it contains multiple sub-libraries for the picotron system and provides some functions itself:
  - init.lua
    - loadfile - missing from standard lua environments
    - dofile - missing from standard lua environments
    - xpcall - missing from standard lua environments
    - wraps:
      - error
      - pcall
      - exit
    - auto-loads:
      - sys.string
      - sys.module
      - extern.class
      - sys.buffer
      - sys.std.io (not yet added, will be added once the io library is ready for use)
      - sys.std.os
  - hash - A library that provides various hashing algorithms for picotron using userdata. Currently only contains a stub for sha1.
  - std An implementation of lua's standard library in pure lua to qualify picotron's lua runtime:
      - io - enables file and stream I/O in Lua. This implementation also adds file descriptors and subprocesses that are managed by a parent process, along with secure communication between them.
      - os - provides Picotron's operating system interface: date/time, environment, and command execution via the `term` module.
  - table - A module that adds functions to the `table` table.
  - uuid - A library that adds support for UUIDs. Currently only uuid4 has been added.
  - buffer - a fixed-size circular buffer of bytes (u8) using userdata.
  - event - An unfinished module for wrapping picotron's event subsystem.
  - font - A module stub for working with a custom font format.
  - fs - A module stub for interacting with picotron's filesystem.
  - p8tron-plus - Some basic utility functions that add a little more convenience.
  - string - A module that adds functions for working with strings
  - term - A quick and dirty shell API for mimicking the built-in terminal, primary intended for `os.execute()`.
- submodules - A module that allows for including or requiring additional files and having each definition of `_update()` and `_draw()` get aggragated into a single `_update()` and `_draw()` function.
