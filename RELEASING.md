# Releasing (Android)

Release builds are signed with your upload key. They never fall back to the debug key: if the key isn't set up, the build fails.

1. Keep the keystore **outside** the repo, for example `~/keys/birthdays-upload.jks`.
2. Create `android/key.properties`. It's git-ignored; never commit it.

   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/Users/<you>/keys/birthdays-upload.jks
   ```

3. Raise `version` in `pubspec.yaml` (for example `1.0.0+2` → `1.0.1+3`). Android only installs an update with a higher build number.
4. Build one file per phone type (about 19 MB each instead of 50 MB):

   ```bash
   flutter build apk --release --split-per-abi
   ```

5. On GitHub, create a release (tag like `v1.0.1`) and attach `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`. Keep that exact file name: the README's Download button links to `releases/latest/download/app-arm64-v8a-release.apk`, so it always serves the newest release.

**Moving to a new computer:** copy the `.jks` file and recreate `android/key.properties` with its passwords. Nothing else is tied to the machine.

**Back up the keystore and its password off this machine.** If they're lost, installed copies can never be updated; users would have to uninstall, which wipes their list.
