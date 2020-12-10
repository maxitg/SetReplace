#!/usr/bin/env bash
set -eo pipefail

setReplaceRoot=$(dirname "$(cd "$(dirname "$0")" && pwd)")
cd "$setReplaceRoot"

# Compute the source hash

sourceFiles=$(find libSetReplace -type f -name "*pp" && find cmake CMakeLists.txt scripts/buildLibraryResources.sh -type f)

if command -v shasum &>/dev/null; then
  echo "Using SHA tool: $(which shasum)"
  sha="$(
    echo "$(
      for fileToHash in $sourceFiles; do
        shasum -a 256 "$fileToHash"
      done
      uname -sm
    )" | shasum -a 256 | cut -d\  -f1
  )"
elif [[ "$OSTYPE" == "msys" && $(command -v certutil) ]]; then # there is another certutil in macOS
  echo "Using SHA tool: $(which certutil)"
  echo "$(
    for fileToHash in $sourceFiles; do
      echo "$(certutil -hashfile "$fileToHash" SHA256 | findstr -v "hash")" "$fileToHash"
    done
    uname -sm
  )" >"$TEMP"/libSetReplaceFilesToHash
  sha=$(certutil -hashfile "$TEMP"/libSetReplaceFilesToHash SHA256 | findstr -v "hash")
else
  echo "Could not find SHA utility"
  exit 1
fi

shortSHA=$(echo "$sha" | cut -c 1-13)
echo "libSetReplace sources hash: $shortSHA"

# Build the library

mkdir -p build
cd build
cmake .. -DSET_REPLACE_ENABLE_ALLWARNINGS=ON -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release # Needed for multi-config generators
cd ..

# Set the platform-specific names

if [ "$(uname -sm)" = "Darwin x86_64" ]; then
  libraryResourcesDirName=MacOSX-x86-64
  libraryExtension=dylib
elif [ "$(uname -sm)" = "Linux x86_64" ]; then
  libraryResourcesDirName=Linux-x86-64
  libraryExtension=so
elif [[ "$OSTYPE" == "msys" && "$(uname -m)" == "x86_64" ]]; then # Windows
  libraryResourcesDirName=Windows-x86-64
  libraryExtension=dll
else
  echo "Operating system unsupported"
  exit 1
fi

libraryDir=LibraryResources/$libraryResourcesDirName
echo "LibraryResources directory: $setReplaceRoot/$libraryDir"
echo "Library extension: $libraryExtension"

# Find the compiled library

compiledLibrary=build/libSetReplace.$libraryExtension
if [ ! -f $compiledLibrary ]; then
  compiledLibrary=build/Release/SetReplace.$libraryExtension
fi

if [ ! -f $compiledLibrary ]; then
  echo "Could not find compiled library"
  exit 1
fi

echo "Found compiled library at $setReplaceRoot/$compiledLibrary"

# Copy the library to LibraryResources

mkdir -p $libraryDir
libraryDestination=$libraryDir/libSetReplace-$shortSHA.$libraryExtension
echo "Copying the library to $setReplaceRoot/$libraryDestination"
cp $compiledLibrary "$libraryDestination"

metadataDestination=$libraryDir/libSetReplaceBuildInfo.json
echo "Writing metadata to $setReplaceRoot/$metadataDestination"
echo "\
{
  \"LibraryFileName\": \"libSetReplace-$shortSHA.$libraryExtension\",
  \"LibraryBuildTime\": $(date -u "+[%-Y, %-m, %-d, %-H, %-M, %-S]"),
  \"LibrarySourceHash\": \"$shortSHA\"
}" >$metadataDestination

cat $metadataDestination
echo "Build done"
