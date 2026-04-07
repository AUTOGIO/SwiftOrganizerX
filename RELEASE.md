# Release Checklist

## Prepare

1. Run `swift test`.
2. Build and package the app with `bash scripts/package_macos_app.sh <version>`.
3. Verify the generated bundle in `dist/SwiftOrganizerX.app`.
4. Review `dist/SwiftOrganizerX-<version>-macos.zip`.

## Tag

1. Commit the release changes.
2. Create an annotated tag such as `git tag -a v1.0.0 -m "SwiftOrganizerX v1.0.0"`.
3. Push the branch and tag.

## Publish

1. Create a GitHub release from the tag.
2. Upload `dist/SwiftOrganizerX-<version>-macos.zip` as the binary asset.
3. Add release notes summarizing user-visible changes and known limitations.

## Remaining Manual Work

- Replace ad-hoc signing with a Developer ID signature before public distribution.
- Notarize the `.app` or `.zip` before sharing outside trusted environments.
- Add an app icon and bundle privacy strings if future features require them.
