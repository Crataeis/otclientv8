# OTClientV8

## Contribution

If you add custom feature, make sure it's optional and can be enabled via g_game.enableFeature function, otherwise your pull request will be rejected.

## Compilation

### Windows

Install vcpkg

```
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg.exe integrate install
```

Use Visual Studio 2022, select backend (OpenGL, DirectX), platform (x86, x64) and just build, all required libraries will be installed for you.

### Linux

If you have **minimal** step by step guide for different distro, please feel free to add it below for others!

### Ubuntu 22.04 / 24.04

```
sudo apt update
sudo apt install git curl build-essential cmake gcc g++ pkg-config autoconf libtool libglew-dev -y
cd ~
git clone https://github.com/microsoft/vcpkg.git
cd vcpkg && ./bootstrap-vcpkg.sh && cd ..
git clone https://github.com/OTAcademy/otclientv8.git
cd otclientv8
~/vcpkg/vcpkg install
mkdir build && cd build
cmake -DCMAKE_TOOLCHAIN_FILE=~/vcpkg/scripts/buildsystems/vcpkg.cmake .. && make -j$(nproc)
cp otclient ../otclient && cd ..
./otclient
```


## Useful tips

- To run tests manually, unpack tests.7z and use command `otclient_debug.exe --test`
- To test mobile UI use command `otclient_debug.exe --mobile`
