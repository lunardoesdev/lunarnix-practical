cmake_minimum_required(VERSION 3.20)
project(sdl3-renderer C)

find_package(SDL3 CONFIG REQUIRED)

add_executable(sdl3-renderer main.c)
target_link_libraries(sdl3-renderer PRIVATE SDL3::SDL3)

if(EMSCRIPTEN)
  set_target_properties(sdl3-renderer PROPERTIES SUFFIX ".html")
  target_link_options(sdl3-renderer PRIVATE
    "-sALLOW_MEMORY_GROWTH=1"
    "-sEXIT_RUNTIME=1"
  )
endif()

if(EMSCRIPTEN)
  install(TARGETS sdl3-renderer RUNTIME DESTINATION share/sdl3-renderer)
  install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/sdl3-renderer.js"
    "${CMAKE_CURRENT_BINARY_DIR}/sdl3-renderer.wasm"
    DESTINATION share/sdl3-renderer
  )
else()
  install(TARGETS sdl3-renderer RUNTIME DESTINATION bin)
endif()

if(WIN32)
  install(FILES $<TARGET_RUNTIME_DLLS:sdl3-renderer> DESTINATION bin)
endif()
