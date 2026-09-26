fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios status

```sh
[bundle exec] fastlane ios status
```

Show the App Store Connect app record for this bundle ID

### ios build

```sh
[bundle exec] fastlane ios build
```

Build a signed App Store .ipa

### ios metadata_text

```sh
[bundle exec] fastlane ios metadata_text
```

Build and upload to TestFlight

Upload only the store texts of all languages (no screenshots, no binary)

### ios beta

```sh
[bundle exec] fastlane ios beta
```



### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Upload only texts + screenshots from fastlane/metadata and fastlane/screenshots

### ios release

```sh
[bundle exec] fastlane ios release
```

Build + upload binary, texts and screenshots (review is NOT auto-submitted)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
