#!/usr/bin/env bash

export VERBOSE=1
export VERBOSE_MAKEFILE=1

# Create a temporary directory
TEST_DIR=$(mktemp -d)
echo "Working in $TEST_DIR"

# Create main.cpp
cat <<EOF > "$TEST_DIR/main.cpp"
#include <string>
#include <thread>
#include <stdio.h>

#if !defined(_MSC_VER)
#include <pthread.h>
#endif

#pragma clang diagnostic ignored "-Wint-to-pointer-cast"

// Add thread_local variables to test TLS initialization
thread_local int g_tlsCounter = 0;
thread_local int g_tlsValue = 42;

#if !defined(_MSC_VER)
// Test pthread directly (not just through std::thread)
pthread_mutex_t g_testMutex = PTHREAD_MUTEX_INITIALIZER;
pthread_key_t g_testKey;

void* pthread_test_func(void* arg) {
    // Test various pthread functions that were failing
    pthread_t self = pthread_self();
    pthread_mutex_lock(&g_testMutex);
    pthread_setspecific(g_testKey, (void*)(intptr_t)42);
    void* value = pthread_getspecific(g_testKey);
    pthread_mutex_unlock(&g_testMutex);
    
    // Just use variable to avoid unused warning
    (void)self;
    (void)value;
    
    return nullptr;
}
#endif

#if defined(__APPLE__)
#include <CoreFoundation/CoreFoundation.h>

void ShowMessage(const std::string& message) {
    // Access thread_local to ensure TLS is initialized
    g_tlsCounter++;
    g_tlsValue += static_cast<int>(g_tlsCounter);
    
    CFStringRef cfMessage = CFStringCreateWithCString(kCFAllocatorDefault, message.c_str(), kCFStringEncodingUTF8);
    CFShow(cfMessage);
    CFRelease(cfMessage);
}

int main() {
#if !defined(_MSC_VER)
    // Initialize pthread resources
    pthread_key_create(&g_testKey, nullptr);
    pthread_mutex_init(&g_testMutex, nullptr);

    // Test pthread directly
    pthread_t thread;
    pthread_create(&thread, nullptr, pthread_test_func, nullptr);
    pthread_join(thread, nullptr);
#endif

    std::string message = "Hello, macOS SDK!";
    std::thread worker([&]() { ShowMessage(message); });
    worker.join();

#if !defined(_MSC_VER)
    // Cleanup pthread resources
    pthread_key_delete(g_testKey);
    pthread_mutex_destroy(&g_testMutex);
#endif

    return 0;
}

#elif defined(_WIN32)
#include <windows.h>

void ShowMessage(const std::string& message) {
    // Access thread_local to ensure TLS is initialized
    g_tlsCounter++;
    g_tlsValue += static_cast<int>(g_tlsCounter);
    auto msg = (message+std::to_string(g_tlsValue));
    MessageBoxA(nullptr, msg.c_str(), "Hello", MB_OK | MB_ICONINFORMATION);
}

int WINAPI WinMain(HINSTANCE, HINSTANCE, LPSTR, int) {
#if !defined(_MSC_VER)
    // Initialize pthread resources
    pthread_key_create(&g_testKey, nullptr);
    pthread_mutex_init(&g_testMutex, nullptr);

    // Test pthread directly
    pthread_t thread;
    pthread_create(&thread, nullptr, pthread_test_func, nullptr);
    pthread_join(thread, nullptr);
#endif

    ShowMessage("WinMain");

    // std::string message = "Hello, Windows!";
    std::thread worker([&]() {
        __try {
            ShowMessage("__try");
            // Cause an actual exception (null pointer read)
            volatile int* p = (volatile int*)g_tlsCounter;
            int v = *p;
            std::string msg = "This message should not appear: | " + std::to_string(v);
            ShowMessage(msg);
        } __except (EXCEPTION_EXECUTE_HANDLER) {
            MessageBoxA(nullptr, "Caught SEH exception!", "Success", MB_OK | MB_ICONINFORMATION);
        }
    });
    worker.join();
    ShowMessage("Done");

#if !defined(_MSC_VER)
    // Cleanup pthread resources
    pthread_key_delete(g_testKey);
    pthread_mutex_destroy(&g_testMutex);
#endif

    return 0;
}

#else
#include <iostream>

void ShowMessage(const std::string& message) {
    // Access thread_local to ensure TLS is initialized
    g_tlsCounter++;
    g_tlsValue += static_cast<int>(g_tlsCounter);
    
    std::cout << message << std::endl;
}

int main() {
#if !defined(_MSC_VER)
    // Initialize pthread resources
    pthread_key_create(&g_testKey, nullptr);
    pthread_mutex_init(&g_testMutex, nullptr);

    // Test pthread directly
    pthread_t thread;
    pthread_create(&thread, nullptr, pthread_test_func, nullptr);
    pthread_join(thread, nullptr);
#endif

    std::string message = "Hello, World!";
    std::thread worker([&]() { ShowMessage(message); });
    worker.join();

#if !defined(_MSC_VER)
    // Cleanup pthread resources
    pthread_key_delete(g_testKey);
    pthread_mutex_destroy(&g_testMutex);
#endif

    return 0;
}
#endif
EOF

# Create a simple Windows resource file (included only for Windows builds)
cat <<'EOF' > "$TEST_DIR/app.rc"
#include <windows.h>

STRINGTABLE
BEGIN
    1 "Hello from resources"
END
EOF

# Create CMakeLists.txt
cat <<EOF > "$TEST_DIR/CMakeLists.txt"
cmake_minimum_required(VERSION 3.10)
project(HelloWorld)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Threads REQUIRED)

add_executable(HelloWorld main.cpp)

add_executable(SizedDeleteCheck sized_delete.cpp)

add_executable(SetjmpTest setjmp_test.c)

target_link_libraries(HelloWorld PRIVATE Threads::Threads)

if(WIN32)
    set_target_properties(HelloWorld PROPERTIES WIN32_EXECUTABLE YES)
    target_sources(HelloWorld PRIVATE app.rc)
    target_link_libraries(HelloWorld PRIVATE user32)
endif()

if(APPLE)
    target_link_libraries(HelloWorld PRIVATE "-framework CoreFoundation")
endif()
EOF

# Create a sized delete test source
cat <<'EOF' > "$TEST_DIR/sized_delete.cpp"
#include <cstddef>
#include <new>

int main() {
    void* p = ::operator new(16);
    ::operator delete(p, static_cast<std::size_t>(16));

    void* a = ::operator new[](16);
    ::operator delete[](a, static_cast<std::size_t>(16));

    return 0;
}
EOF

# Create a setjmp/longjmp test (reproduces the libjpeg-turbo issue)
cat <<'EOF' > "$TEST_DIR/setjmp_test.c"
#include <setjmp.h>
#include <stdio.h>
#include <string.h>

struct error_handler {
    jmp_buf setjmp_buffer;
    int error_code;
};

void might_fail(struct error_handler* handler, int should_fail) {
    if (should_fail) {
        handler->error_code = 42;
        longjmp(handler->setjmp_buffer, 1);
    }
}

int test_setjmp(int should_fail) {
    struct error_handler handler;
    memset(&handler, 0, sizeof(handler));
    
    if (setjmp(handler.setjmp_buffer)) {
        // Error path - longjmp returned here
        printf("Caught error: %d\n", handler.error_code);
        return handler.error_code;
    }
    
    // Normal path
    might_fail(&handler, should_fail);
    printf("Success - no error\n");
    return 0;
}

int main() {
    printf("Testing setjmp without error...\n");
    int result1 = test_setjmp(0);
    
    printf("Testing setjmp with error...\n");
    int result2 = test_setjmp(1);
    
    if (result1 == 0 && result2 == 42) {
        printf("All setjmp tests passed!\n");
        return 0;
    } else {
        printf("setjmp test failed!\n");
        return 1;
    }
}
EOF

# Function to test a toolchain
test_toolchain() {
    local NAME=$1
    local TOOLCHAIN_FILE=$2
    local EXTRA_ARGS=$3

    echo "------------------------------------------------"
    echo "Testing $NAME"
    if [ -z "$TOOLCHAIN_FILE" ]; then
        echo "Error: Toolchain file variable for $NAME is not set."
        return
    fi
    echo "Toolchain file: $TOOLCHAIN_FILE"

    BUILD_DIR="$TEST_DIR/build_$NAME"
    
    # Configure
    echo "Configuring..."
    local CMAKE_CMD=("cmake" "-S" "$TEST_DIR" "-B" "$BUILD_DIR" "-DCMAKE_TOOLCHAIN_FILE=$TOOLCHAIN_FILE")
    if [ -n "$EXTRA_ARGS" ]; then
        CMAKE_CMD+=("$EXTRA_ARGS")
    fi
    CMAKE_CMD+=("-G" "Ninja")

    "${CMAKE_CMD[@]}" > "$TEST_DIR/$NAME.log" 2>&1
    if [ $? -ne 0 ]; then
        echo "Configuration FAILED. Log:"
        cat "$TEST_DIR/$NAME.log"
        return
    fi

    # Build
    echo "Building..."
    cmake --build "$BUILD_DIR" >> "$TEST_DIR/$NAME.log" 2>&1
    if [ $? -ne 0 ]; then
        echo "Build FAILED. Log:"
        cat "$TEST_DIR/$NAME.log"
        return
    fi

    echo "SUCCESS"
}

# Run tests
test_toolchain "Linux" "$toolchainfile_linux"
test_toolchain "MacOS_Dual" "$toolchainfile_macos_dual"
test_toolchain "Windows_MinGW_x86_64" "$toolchainfile_windows_mingw_x86_64"
test_toolchain "Windows_MinGW_ARM64" "$toolchainfile_windows_mingw_aarch64"

echo "------------------------------------------------"
echo "Done. Work directory: $TEST_DIR"
