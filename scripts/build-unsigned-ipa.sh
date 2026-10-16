#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

if [[ "$(uname -s)" != Darwin ]]; then
  echo "This script requires macOS with Xcode and the iOS SDK." >&2
  exit 1
fi

for library in Libraries/libiPhone-lib.a Libraries/libil2cpp.a Libraries/baselib.a; do
  if [[ ! -s "$library" ]]; then
    echo "Missing Unity library: $library" >&2
    exit 1
  fi
  if head -c 128 "$library" | grep -q 'https://git-lfs.github.com/spec/v1'; then
    echo "Git LFS pointer found instead of $library. Run git lfs pull." >&2
    exit 1
  fi
done

# Use a fresh directory for every build, including local reruns.
mkdir -p build
build_dir="$(mktemp -d "$project_root/build/unsigned.XXXXXX")"
archive_path="$build_dir/Dragonball.xcarchive"

# Archive without provisioning or a signing identity. Do not use -exportArchive:
# that step expects distribution signing, whereas this output must be unsigned.
xcodebuild \
  -project Unity-iPhone.xcodeproj \
  -scheme Unity-iPhone \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$build_dir/DerivedData" \
  -archivePath "$archive_path" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY= \
  DEVELOPMENT_TEAM= \
  PROVISIONING_PROFILE_SPECIFIER= \
  ENABLE_BITCODE=NO \
  ENABLE_USER_SCRIPT_SANDBOXING=NO \
  archive 2>&1 | tee "$project_root/build/xcodebuild.log"

shopt -s nullglob
apps=("$archive_path/Products/Applications/"*.app)
if [[ ${#apps[@]} -ne 1 ]]; then
  echo "Expected exactly one archived iOS app, found ${#apps[@]}." >&2
  exit 1
fi

mkdir -p "$build_dir/package/Payload"
app_path="$build_dir/package/Payload/$(basename "${apps[0]}")"
ditto "${apps[0]}" "$app_path"

executable_name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app_path/Info.plist")"
test -x "$app_path/$executable_name"
test -f "$app_path/Frameworks/UnityFramework.framework/UnityFramework"
test -d "$app_path/Data"
if codesign -d "$app_path" >/dev/null 2>&1; then
  echo "The archived app has a code signature; expected an unsigned app." >&2
  exit 1
fi

ipa_path="$build_dir/Dragonball-unsigned.ipa"
(
  cd "$build_dir/package"
  /usr/bin/zip -qry "$ipa_path" Payload
)
/usr/bin/unzip -tq "$ipa_path"
mv -f "$ipa_path" "$project_root/build/Dragonball-unsigned.ipa"
echo "Unsigned IPA: $project_root/build/Dragonball-unsigned.ipa"
