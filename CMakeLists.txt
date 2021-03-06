cmake_minimum_required(VERSION 2.8.12)
project(protobuf-qml)
# Force link with full path
if(POLICY CMP0060)
  cmake_policy(SET CMP0060 NEW)
endif()
if(POLICY CMP0054)
  cmake_policy(SET CMP0054 NEW)
endif()

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake")

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)

include(CheckCXXCompilerFlag)
check_cxx_compiler_flag(-Wno-inconsistent-missing-override HAS_W_INCOSISTENT_MISSING_OVERRIDE)
if(HAS_W_INCOSISTENT_MISSING_OVERRIDE)
  # Generated code for Q_OBJECT fires too many of this
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wno-inconsistent-missing-override")
endif()

check_cxx_compiler_flag(-fdiagnostics-color HAS_DIAGNOSTICS_COLOR)
if(HAS_DIAGNOSTICS_COLOR)
  # Generated code for Q_OBJECT fires too many of this
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fdiagnostics-color")
endif()

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

find_package(Protobuf 3.0 REQUIRED CONFIG)
find_package(GRPC++)

include(CMakeDependentOption)
option(BUILD_COMPILER_PLUGIN "Build protoc compiler plugin" ON)
option(BUILD_PROTOBUF "Build Protocol Buffers QML module" ON)
cmake_dependent_option(BUILD_GRPC "Build gRPC QML module" ON
  "GRPC++_FOUND" OFF)
cmake_dependent_option(BUILD_GRPC_TEST_SERVER "Build gRPC test server" ON
  "GRPC++_FOUND" OFF)

if(BUILD_PROTOBUF OR BUILD_GRPC)
  find_package(Qt5WebSockets 5.8)
  find_package(Qt5Core COMPONENTS Private REQUIRED)
  find_package(Qt5Qml COMPONENTS Private REQUIRED)
  find_package(Qt5Quick COMPONENTS Private REQUIRED)
endif()

include_directories(SYSTEM ${PROTOBUF_INCLUDE_DIRS})
include_directories(compiler)

include_directories(SYSTEM
  ${Qt5Qml_PRIVATE_INCLUDE_DIRS})

set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<CONFIG:Debug>:QT_QML_DEBUG>)

if(BUILD_GRPC)
  include_directories(SYSTEM ${GRPC++_INCLUDE_DIRS})
endif()

function(copy TAG DEST)
  foreach(FIL ${ARGN})
    get_filename_component(FIL_ABS ${FIL} ABSOLUTE)
    get_filename_component(FIL_NAME ${FIL} NAME)
    set(DST ${DEST}/${FIL_NAME})
    add_custom_command(OUTPUT ${DST} DEPENDS ${FIL_ABS}
      COMMAND ${CMAKE_COMMAND} -E copy ${FIL_ABS} ${DST})
    add_custom_target("copy-${TAG}-${FIL_NAME}" ALL DEPENDS ${DST})
  endforeach()
endfunction()

function(protobuf_generate_lang PB_LANG PB_OUT)
  foreach(FIL ${ARGN})
    get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
    get_filename_component(FIL_WE ${FIL} NAME_WE)
    get_filename_component(FIL_DIR ${FIL} DIRECTORY)

    if(FIL_DIR)
      set(INCDIR "-I${FIL_DIR}")
    else()
      set(INCDIR "")
    endif()

    add_custom_target("protobuf_generate_${PB_LANG}_${FIL_WE}" ALL
      DEPENDS ${ABS_FIL} protoc-gen-qml
      COMMAND  protobuf::protoc
      --plugin=protoc-gen-qml=${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/protoc-gen-qml${CMAKE_EXECUTABLE_SUFFIX}
      ${INCDIR}
      --${PB_LANG}_out  ${PB_OUT} ${ABS_FIL})
  endforeach()
endfunction()

function(protobuf_generate_qml)
  protobuf_generate_lang(qml ${ARGV})
endfunction()

macro(protobuf_generate_cxx PB_VAR)
  foreach(FIL ${ARGN})
    get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
    get_filename_component(FIL_WE ${FIL} NAME_WE)
    get_filename_component(FIL_DIR ${ABS_FIL} DIRECTORY)

    if(FIL_DIR)
      set(INCDIR "-I${FIL_DIR}")
    else()
      set(INCDIR "")
    endif()

    set(_OUTPUT ${FIL_WE}.pb.cc ${FIL_WE}.pb.h)
    list(APPEND ${PB_VAR} ${_OUTPUT})

    add_custom_command(
      OUTPUT ${_OUTPUT}
      DEPENDS ${ABS_FIL}
      COMMAND  protobuf::protoc ${INCDIR}
      --cpp_out "." ${ABS_FIL}
      OUTPUT
      )
    add_custom_target(
      "protobuf_generate_cxx_${FIL_WE}" ALL
      DEPENDS ${_OUTPUT})
  endforeach()
endmacro()

if(NOT MSVC)
  if(CMAKE_VERSION VERSION_LESS 3.1.0)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++0x")
  endif()
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -Wno-unused-parameter")
endif()

function(PROTOBUF_QML_TARGET TARGET)
  if(NOT CMAKE_VERSION VERSION_LESS 3.1.0)
    set(CXX_FEATURES
      cxx_auto_type
      cxx_lambdas
      cxx_nullptr
      cxx_override
      cxx_range_for)
    target_compile_features(${TARGET} PUBLIC ${CXX_FEATURES})
  endif()
endfunction()

set(PROTOBUF_QML_TARGETS protobuf-qml protoc-gen-qml)

include_directories(lib)

if(BUILD_PROTOBUF)
  add_subdirectory(lib/protobuf)
endif()

if(BUILD_GRPC)
  add_subdirectory(lib/grpc)
endif()

if(BUILD_COMPILER_PLUGIN)
  add_subdirectory(compiler)
endif()

if(BUILD_PROTOBUF OR BUILD_GRPC)
  include(CTest)
  if(BUILD_TESTING OR BUILD_GRPC_TEST_SERVER)
    find_package(Qt5QuickTest REQUIRED)
    enable_testing()
    add_subdirectory(test)
  endif()

  add_subdirectory(examples/cpp)
  if(Qt5WebSockets_FOUND OR BUILD_FUTURE_EXAMPLES)
    add_subdirectory(examples/WebSockets)
  endif()
  if(BUILD_FUTURE_EXAMPLES)
    add_subdirectory(examples/XMLHttpRequest)
  endif()
endif()
