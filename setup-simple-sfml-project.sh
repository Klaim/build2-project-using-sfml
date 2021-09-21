
rm -rf */

# This script assumes Windows + Visual Studio installed, and Git Bash (over cmd in my case) as the CLI.
# If you use another cli, you might have to addapt the following commands (in particular the escaping).

git clone --depth 1 --branch master git@github.com:SFML/SFML.git
# generate VS project with cmake (should use the highest version Visual Studio installed by default, for 64bit)
# The macro DEBUG_POSTFIX is used so that the debug and release versions of the binaries have the same name (but different directories, per configuration).
cmake -S ./SFML -B ./build-SFML/ -DBUILD_SHARED_LIBS=NO -DSFML_STATIC_LIBRARIES=ON
# build the Debug and Release configurations
cmake --build ./build-SFML/  --config Debug
cmake --build ./build-SFML/  --config Release
# install the Debug and Release versions in `install/<config>/SFML`
cmake --install ./build-SFML/ --config Debug --prefix ./install/debug/SFML
cmake --install ./build-SFML/ --config Release --prefix ./install/release/SFML

for file in ./install/debug/SFML/lib/*-d.lib
do
  mv "$file" "${file/-s-d.lib/-s.lib}"
done


# ###################### CMAKE
# mkdir game

# cp -r SFML/examples/tennis/*.cpp SFML/examples/tennis/resources/ game/
# echo "
# cmake_minimum_required (VERSION 3.21.2)
# project (game)

# find_package(SFML 2 REQUIRED
#     COMPONENTS
#         audio graphics window system
# )

# add_executable(game Tennis.cpp)
# target_link_libraries(game sfml-audio sfml-graphics)

# install(TARGETS game DESTINATION bin)
# install(DIRECTORY resources/
#         DESTINATION bin/resources
# )

# " > game/CMakeLists.txt
# cmake -S ./game -B ./build-game/ -G "Visual Studio 17 2022" -A x64 -DSFML_STATIC_LIBRARIES=ON -DCMAKE_PREFIX_PATH=$PWD/install/debug/SFML/
# cmake --build ./build-game/  --config Debug
# cmake --install ./build-game/ --config Debug --prefix ./install/debug/game


################### build2

# # Create a small executable build2 project with no tests and no sub-directories, using .cpp, .hpp etc.
bdep new game -l c++,cpp -t exe,no-tests,no-subdir

# # Copy-paste the code from https://gist.github.com/fschr/92958222e35a823e738bb181fe045274 into `game.cpp`
cp -r SFML/examples/tennis/* game/
rm game/CMakeLists.txt game/game.cpp

# # # Now in the buildfile, try to import SFML like if it was already available in the system:
# sed -i '$ a config [string] config.game.sfml_libs_suffix ?= ''\n' game/build/root.build
sed -i -e '/\#import/ r import-sfml.build2' game/buildfile
sed -i -e '/cxx.poptions/ r resources.build2' game/buildfile

# Create a configuration that adds flags exposing the binaries
# You must replace the paths by the full paths of the lib and include directories. (this is different from the doc I pointed though, but maybe easier to understand - prefer the technique in the doc if you you can)
# Because we pass the paths directly to the linker and compiler, we must pass the paths in the form that these tools know (not `/e/blah/blah` but `E:/blah/blah`) and with their speicfic flags (mainly `/LIBPATH:` instead of `-L` when using MSVC toolchain).
# I also setup these configurations to be able to install the built project in the install directories.
# The first configuration is the default/forwarding configuration (the one used by default when you just invoke `b`).
bdep init -d game/ -C build-msvc-debug @debug cc --options-file config-msvc-debug.options -- config.game.sfml_libs_suffix=-d
bdep init -d game/ -C build-msvc-release @release cc --options-file config-msvc-release.options

# # At this point, your setup is ready to build the game project.
# # There are several ways, but for simplicity, I will just build+install all the versions/configurations:
b install: build-msvc-debug/game/
b install: build-msvc-release/game/


# Once everything is installed you can run the program:
# ./install/debug/game/bin/game.exe
# ./install/release/game/bin/game.exe

