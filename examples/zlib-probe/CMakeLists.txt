cmake_minimum_required(VERSION 3.20)
project(zlib-probe C)

find_package(ZLIB REQUIRED)

add_executable(zlib-probe main.c)
target_link_libraries(zlib-probe PRIVATE ZLIB::ZLIB)

install(TARGETS zlib-probe RUNTIME DESTINATION bin)
