Memos on sublime text


# Link syntax to file extension (if not working automatically)

1. Open a file with the extension and apply the syntax manually.

2. With this file in the active window, goto menu bar to Preferences > `Settings - Synatax specific`

3. This should open up a settings file for you where you can modify. For instance, following is an example of adding f90 and F90 extensions to my fortran (modern) syntax:

```
// These settings override both User and Default settings for the FortranModern syntax
{
	"extensions":
	[
		"f90", "F90"
	]
}
```

4. Thenafter, every f90 and F90 files that I opened got displayed in the syntax desired.

`Note:` Needless to say, this only works for valid files. For instance if I just name a random text file with f90 extension, it won't work.
