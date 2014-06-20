cmake_minimum_required(VERSION 2.8)
project(luapp)

if(NOT DEFINED LUAJIT_INCLUDE_DIRS)
    find_package(PkgConfig)
    message(STATUS "Detecting LuaJIT...")
    if(PKG_CONFIG_FOUND)
        message(STATUS "Using pkg-config to detect LuaJIT...")
        pkg_check_modules(LUAJIT luajit)
        if(LUAJIT_FOUND)
            message(STATUS "Found LuaJIT.")
            message(STATUS "include: ${LUAJIT_INCLUDE_DIRS}")
            include_directories(${LUAJIT_INCLUDE_DIRS})
            link_directories(${LUAJIT_LIBRARY_DIRS})
            set(EXTRA_LIBS ${LUAJIT_LIBRARIES})
        else()
            message(FATAL_ERROR "LuaJIT not found.")
        endif()
    else()
        message(STATUS "Using local LuaJIT.")
        set(LUAJIT_LIBRARIES luajit)
    endif()
endif()

option(HAVE_LOCAL_LUVIT 0)
if(${HAVE_LOCAL_LUVIT})
    add_subdirectory(libraries/luvit)
endif()
include_directories(
    ${LUAJIT_INCLUDE_DIRS}
    ${UV_INCLUDE_DIRS}
    ${LUVIT_INCLUDE_DIRS})

set(LUAPP_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/luapp)

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(LUAPP_TARGET_ARCH "x64")
else()
    set(LUAPP_TARGET_ARCH "x86")
endif()

if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
    set(LUAPP_PLATFORM_BIN "windows")
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    set(LUAPP_PLATFORM_BIN "linux")
elseif(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
    set(LUAPP_PLATFORM_BIN "darwin")
elseif(${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")
    set(LUAPP_PLATFORM_BIN "freebsd")
elseif(${CMAKE_SYSTEM_NAME} MATCHES "SunOS")
    set(LUAPP_PLATFORM_BIN "solaris")
else()
    message(FATAL_ERROR "Unsupported OS: ${CMAKE_SYSTEM_NAME}")
endif()

set(LUAPP_BINARY_NAME luapp_${LUAPP_PLATFORM_BIN}_${LUAPP_TARGET_ARCH})
add_executable(${LUAPP_BINARY_NAME} ${LUAPP_SOURCES})

target_link_libraries(${LUAPP_BINARY_NAME}
    ${UV_LIBRARIES}
    ${LUVIT_LIBRARIES}
    ${LUAJIT_LIBRARIES})

if(DEFINED INSTALL_RUNTIME_DIR)
    install(TARGETS
            ${LUAPP_BINARY_NAME}
            RUNTIME DESTINATION ${INSTALL_RUNTIME_DIR}
            LIBRARY DESTINATION ${INSTALL_LIBRARY_DIR}
            ARCHIVE DESTINATION ${INSTALL_ARCHIVE_DIR})
endif()

if(DEFINED INSTALL_LUA_DIR)
    install(FILES
            ${CMAKE_CURRENT_SOURCE_DIR}/luapp.lua
            DESTINATION ${INSTALL_LUA_DIR})
endif()
