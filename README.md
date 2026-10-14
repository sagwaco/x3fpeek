# X3F Peek

Finder thumbnails and Quick Look previews for Sigma X3F raw files. The
extensions show the full-size JPEG preview that the camera embeds in each file.
They do not decode raw data.

## Build and install

```sh
xcodebuild -project X3FPeek.xcodeproj -scheme X3FPeek -configuration Release -derivedDataPath build build
cp -R build/Build/Products/Release/X3FPeek.app /Applications/
open /Applications/X3FPeek.app   # Run once to register the extensions.
qlmanage -r && qlmanage -r cache # Reset Quick Look so Finder uses them.
```

Make sure both extensions are on in System Settings > General > Login Items &
Extensions > Quick Look.

The default build is signed to run locally. To share it, set your team and a
Developer ID signing certificate in Xcode, then notarize the app.

## Check

```sh
swiftc Shared/X3F.swift Tests/main.swift -o "$TMPDIR/x3fcheck" && "$TMPDIR/x3fcheck" [file.x3f ...]
```
