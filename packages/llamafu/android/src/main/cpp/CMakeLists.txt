cmake_minimum_required(VERSION 3.4.1)

project(llamafu)

# Set the path to the llama.cpp directory
if(NOT DEFINED LLAMA_CPP_DIR)
    if(DEFINED ENV{LLAMA_CPP_DIR})
        set(LLAMA_CPP_DIR $ENV{LLAMA_CPP_DIR})
    else()
        # Use the git submodule by default
        set(LLAMA_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../llama.cpp")
    endif()
endif()

# Verify that llama.cpp directory exists
if(NOT EXISTS "${LLAMA_CPP_DIR}/CMakeLists.txt")
    message(FATAL_ERROR "llama.cpp not found at ${LLAMA_CPP_DIR}. Please run 'git submodule update --init --recursive' to initialize the llama.cpp submodule.")
endif()

# Add the llama.cpp include directories
include_directories(
    ${LLAMA_CPP_DIR}
    ${LLAMA_CPP_DIR}/include
    ${LLAMA_CPP_DIR}/common
    ${LLAMA_CPP_DIR}/ggml/include
    ${LLAMA_CPP_DIR}/tools/mtmd
    ${LLAMA_CPP_DIR}/vendor
)

# Build llama.cpp as part of our build process
set(GGML_STATIC ON CACHE BOOL "" FORCE)
set(GGML_SHARED OFF CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(LLAMA_STATIC ON CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(GGML_LLAMAFILE OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_COMMON OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_TOOLS OFF CACHE BOOL "" FORCE)
set(LLAMA_CURL OFF CACHE BOOL "" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)

# Add llama.cpp subdirectory
add_subdirectory(${LLAMA_CPP_DIR} llama.cpp EXCLUDE_FROM_ALL)

# Find the built libraries
find_library(libllama llama ${LLAMA_CPP_DIR}/build)
find_library(libggml ggml ${LLAMA_CPP_DIR}/build)

# Create the llamafu library
add_library(
    llamafu
    SHARED
    llamafu.cpp
)

# For Android, we need to link android and log libraries
# For Linux host, we skip these
if (ANDROID)
    target_link_libraries(
        llamafu
        llama
        ggml
        android
        log
    )
else()
    target_link_libraries(
        llamafu
        llama
        ggml
    )
endif()

# Multimodal support source files from llama.cpp/tools/mtmd
target_sources(llamafu PRIVATE
    ${LLAMA_CPP_DIR}/tools/mtmd/clip.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/mtmd.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/mtmd-audio.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/mtmd-helper.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/cogvlm.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/conformer.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/glm4v.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/internvl.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/kimivl.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/llama4.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/llava.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/minicpmv.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/pixtral.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/qwen2vl.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/qwen3vl.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/siglip.cpp
    ${LLAMA_CPP_DIR}/tools/mtmd/models/whisper-enc.cpp
)

# Create a test program
add_executable(
    test_llamafu
    test_llamafu.cpp
)

target_link_libraries(
    test_llamafu
    llamafu
    llama
    ggml
)