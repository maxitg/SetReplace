if [ $(uname) = "Darwin" ]
then
  testBinaries=$(find build/libSetReplace/test -type f -perm +111 -print)
elif [ $(uname) = "Linux" ]
then
  testBinaries=$(find build/libSetReplace/test -type f -executable -print)
else
  echo "Operating System not supported."
  exit 1
fi

if [ -z "$testBinaries" ]
then
  echo "No tests found."
  echo "Build libSetReplace tests first:"
  echo "  mkdir build && cd build"
  echo "  cmake .. -DSET_REPLACE_BUILD_TESTING=ON"
  echo "  cmake --build ."
  echo "  cd .."
  exit 1
fi

exitStatus=0
isFirstTest=1
for testBinary in $testBinaries
do
  if [ $isFirstTest -eq 0 ]
  then
    echo
  fi
  isFirstTest=0
  echo "$(basename $testBinary)..."
  if ! eval $testBinary
  then
    exitStatus=1
  fi
done
exit $exitStatus
