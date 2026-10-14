# X3Peek (X3F Peek)

Finder thumbnails and Quick Look previews for Sigma Foveon X3F raw files. The
extensions show the full-size JPEG preview that the camera embeds in each file.
They do not decode raw data.

## Install a release

Download `X3FPeek.zip` from the
[latest release](https://github.com/sagwaco/x3fpeek/releases/latest), unzip
it, and move `X3FPeek.app` to /Applications. The release is not notarized, so
remove the quarantine flag before you open it:

```sh
xattr -dr com.apple.quarantine /Applications/X3FPeek.app
open /Applications/X3FPeek.app   # Run once to register the extensions.
qlmanage -r && qlmanage -r cache # Reset Quick Look so Finder uses them.
```

## Build and install

```sh
xcodebuild -project X3FPeek.xcodeproj -scheme X3FPeek -configuration Release -destination 'generic/platform=macOS' -derivedDataPath build build
cp -R build/Build/Products/Release/X3FPeek.app /Applications/
open /Applications/X3FPeek.app   # Run once to register the extensions.
qlmanage -r && qlmanage -r cache # Reset Quick Look so Finder uses them.
```

Make sure both extensions are on in System Settings > General > Login Items &
Extensions > Quick Look.

The default build is signed to run locally. To share it, set your team and a
Developer ID signing certificate in Xcode, then notarize the app.

## Release

CI builds every push and pull request. To publish a release, push a version
tag. The tag sets the app version.

```sh
git tag v1.0.0 && git push origin v1.0.0
```

## Check

```sh
swiftc Shared/X3F.swift Tests/main.swift -o "$TMPDIR/x3fcheck" && "$TMPDIR/x3fcheck" [file.x3f ...]
```
