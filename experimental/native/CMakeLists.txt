cmake_minimum_required(VERSION 3.16)
project(firebase_tizen_experimental_native LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(CURL REQUIRED)

add_library(firebase_native_common STATIC
  src/http_client.cpp
)

target_include_directories(firebase_native_common PUBLIC include)
target_link_libraries(firebase_native_common PUBLIC CURL::libcurl)

add_executable(firebase_rest_cli
  src/firebase_rest_cli.cpp
)
target_link_libraries(firebase_rest_cli PRIVATE firebase_native_common)

add_executable(firebase_runtime_host
  src/firebase_runtime_host.cpp
)
target_link_libraries(firebase_runtime_host PRIVATE firebase_native_common)
