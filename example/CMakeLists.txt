cmake_minimum_required(VERSION 3.20)
project(HelloWorld)

set(CMAKE_CXX_STANDARD 23)

include(FetchContent)

FetchContent_Declare(
    wxWidgets
    GIT_REPOSITORY https://github.com/wxWidgets/wxWidgets.git
    GIT_TAG        v3.2.9
    GIT_SHALLOW    TRUE
)

set(wxBUILD_SHARED OFF)
set(wxBUILD_TESTS OFF)
set(wxBUILD_SAMPLES OFF)
set(wxBUILD_DEMOS OFF)
set(wxBUILD_DOCS OFF)
set(wxUSE_PNG "builtin")
set(wxUSE_STC OFF)
set(wxUSE_JPEG OFF)
set(wxUSE_LIBTIFF OFF)
set(wxUSE_ZLIB "builtin")
set(wxUSE_SVG OFF)
set(wxUSE_ARTPROVIDER_TANGO OFF)

message(STATUS "Fetching wxWidgets, this may take some time...")

# Exclude wxwidgets from the install phase:
FetchContent_GetProperties(wxWidgets)
if(NOT wxWidgets_POPULATED)
    FetchContent_Populate(wxWidgets)
    add_subdirectory(${wxwidgets_SOURCE_DIR} ${wxwidgets_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

if(APPLE)
    set(MACOSX_BUNDLE_BUNDLE_NAME "HelloWorld")
    set(MACOSX_BUNDLE_GUI_IDENTIFIER "nl.newhouse.nhcrossbuild.helloworld")
    add_executable(HelloWorld MACOSX_BUNDLE main.cpp)
    add_custom_command(TARGET HelloWorld POST_BUILD COMMAND ${NH_RCODESIGN} sign
        --entitlements-xml-file "${CMAKE_SOURCE_DIR}/helloworld.xcent"
        --code-signature-flags "runtime"
        # For actual distribution, you would need to sign with a valid developer certificate:
        # --p12-file "/your/certificate.p12" 
        # --p12-password-file "/your/password.txt"
        "HelloWorld.app")
    # And you would need to create a DMG file and notarize that. Notarization can also be done using rcodesign:
    # add_custom_command(TARGET HelloWorld POST_BUILD COMMAND ${NH_RCODESIGN} notary-submit --api-key-file "key.txt" --staple "yourdmgfile.dmg")
elseif(WIN32)
    add_executable(HelloWorld WIN32 main.cpp)
else()
    add_executable(HelloWorld main.cpp)
endif()

target_link_libraries(HelloWorld PRIVATE wx::core wx::base)

if(APPLE)
    install(TARGETS HelloWorld BUNDLE DESTINATION .)
else()
    install(TARGETS HelloWorld RUNTIME DESTINATION bin)
endif()
