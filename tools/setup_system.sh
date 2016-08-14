#!/usr/bin/env bash

export PLATFORM=linux

# Install lua version
if [ "$LUASUFFIX" == "jit" ]; then
  curl http://luajit.org/download/LuaJIT-2.0.2.tar.gz | tar xz
  mv LuaJIT-2.0.2 lua
  cd lua
  make && sudo make install
  sudo ln -s /usr/local/bin/luajit /usr/local/bin/lua
  sudo ln -s /usr/local/lib/libluajit.so /usr/local/lib/liblua.so
  sudo ln -s /usr/local/include/luajit-2.0 /usr/local/include/lua
else
  if [ "$LUASUFFIX" == "5.1" ]; then
    curl http://www.lua.org/ftp/lua-5.1.5.tar.gz | tar xz
    mv lua-5.1.5 lua
  elif [ "$LUASUFFIX" == "5.2" ]; then
    curl http://www.lua.org/ftp/lua-5.2.3.tar.gz | tar xz
    mv lua-5.2.3 lua
  elif [ "$LUASUFFIX" == "5.3" ]; then
    curl http://www.lua.org/ftp/lua-5.3.3.tar.gz | tar xz
    mv lua-5.3.3 lua
  fi
  cd lua
  make $PLATFORM
  cd src
  ${CC} -o liblua.so -shared liblua.a
  sudo cp liblua.so /usr/local/lib
  cd ..
  sudo make $PLATFORM install
  sudo ln -s /usr/local/bin/lua /usr/local/bin/lua${LUASUFFIX}
fi
cd $TRAVIS_BUILD_DIR;
lua -v

# Install busted and luacov-coveralls
git clone git://github.com/keplerproject/luarocks.git
cd luarocks
./configure --lua-version=$LUAVER --lua-suffix=$LUASUFFIX
make
sudo make install
sudo luarocks install busted
sudo luarocks install luacov-coveralls
cd ${TRAVIS_BUILD_DIR}

# Install premake
git clone --depth=1 --branch=master https://github.com/premake/premake-core.git
cd premake-core
git submodule update --init --recursive
make -f Bootstrap.mak $TRAVIS_OS_NAME
mv bin/release/premake5 ${TRAVIS_BUILD_DIR}
cd ${TRAVIS_BUILD_DIR}
