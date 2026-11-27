#!/usr/bin/env bash
set -eo pipefail

scriptDir=$(cd "$(dirname "$0")" && pwd)
setReplaceRoot=$(dirname "${scriptDir}")
cd "${setReplaceRoot}"

# Obtain requested architectures

os=$(uname -s)
machine=$(uname -m)

if [[ -n $1 ]]; then
  arch="$1"
else
  arch="${machine}"
fi

# Set the platform-specific names

if [[ ${os} == "Darwin" && ${arch} == "arm64" ]]; then
  cmakeArchitectureArg="-DCMAKE_OSX_ARCHITECTURES=arm64"
  libraryResourcesDirName=MacOSX-ARM64
  libraryExtension=dylib
elif [[ ${os} == "Darwin" && ${arch} == "x86_64" ]]; then
  cmakeArchitectureArg="-DCMAKE_OSX_ARCHITECTURES=x86_64"
  libraryResourcesDirName=MacOSX-x86-64
  libraryExtension=dylib
elif [[ ${os} == "Linux" && ${arch} == "x86_64" ]]; then
  libraryResourcesDirName=Linux-x86-64
  libraryExtension=so
elif [[ ${OSTYPE} == "msys" && ${machine} == "x86_64" ]]; then # Windows
  libraryResourcesDirName=Windows-x86-64
  libraryExtension=dll
else
  echo "Operating system unsupported"
  exit 1
fi

libraryDir=LibraryResources/${libraryResourcesDirName}
echo "LibraryResources directory: ${setReplaceRoot}/${libraryDir}"
echo "Library extension: ${libraryExtension}"

# Compute the source hash

sourceFiles="$(ls libSetReplace/*pp CMakeLists.txt cmake/* scripts/buildLibraryResources.sh)"

if shaTool=$(command -v shasum); then
  echo "Using SHA tool: ${shaTool}"
  sha=$(
    {
      for fileToHash in ${sourceFiles}; do
        shasum -a 256 "${fileToHash}"
      done
      echo "${os}"
      echo "${arch}"
    } | shasum -a 256 | cut -d\  -f1
  )
elif [[ ${OSTYPE} == "msys" ]] && shaTool=$(command -v certutil); then # there is another certutil in macOS
  echo "Using SHA tool: ${shaTool}"
  {
    for fileToHash in ${sourceFiles}; do
      fileHash=$(certutil -hashfile "${fileToHash}" SHA256 | findstr -v "hash")
      echo "${fileHash}" "${fileToHash}"
    done
    echo "${os}"
    echo "${arch}"
  } >"${TEMP}"/libSetReplaceFilesToHash
  sha=$(certutil -hashfile "${TEMP}"/libSetReplaceFilesToHash SHA256 | findstr -v "hash")
else
  echo "Could not find SHA utility"
  exit 1
fi

shortSHA=$(echo "${sha}" | cut -c 1-13)
echo "libSetReplace sources hash: ${shortSHA}"

# Build the library

mkdir -p build
cd build
cmake .. -DSET_REPLACE_ENABLE_ALLWARNINGS=ON -DBUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release \
  ${cmakeArchitectureArg:+"${cmakeArchitectureArg}"}
cmake --build . --config Release # Needed for multi-config generators
cd ..

# Find the compiled library

compiledLibrary=build/libSetReplace.${libraryExtension}
if [[ ! -f ${compiledLibrary} ]]; then
  compiledLibrary=build/Release/SetReplace.${libraryExtension}
fi

if [[ ! -f ${compiledLibrary} ]]; then
  echo "Could not find compiled library"
  exit 1
fi

echo "Found compiled library at ${setReplaceRoot}/${compiledLibrary}"

# Copy the library to LibraryResources

mkdir -p "${libraryDir}"
libraryDestination=${libraryDir}/libSetReplace-${shortSHA}.${libraryExtension}
echo "Copying the library to ${setReplaceRoot}/${libraryDestination}"
cp "${compiledLibrary}" "${libraryDestination}"

metadataDestination=${libraryDir}/libSetReplaceBuildInfo.json
echo "Writing metadata to ${setReplaceRoot}/${metadataDestination}"
buildTime=$(date -u "+[%-Y, %-m, %-d, %-H, %-M, %-S]")
echo "\
{
  \"LibraryFileName\": \"libSetReplace-${shortSHA}.${libraryExtension}\",
  \"LibraryBuildTime\": ${buildTime},
  \"LibrarySourceHash\": \"${shortSHA}\"
}" >"${metadataDestination}"

cat "${metadataDestination}"
echo "Build done"
