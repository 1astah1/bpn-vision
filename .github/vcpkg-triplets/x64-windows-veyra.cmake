# Veyra links everything statically with the static CRT (CMAKE_MSVC_RUNTIME_LIBRARY MultiThreaded),
# except FFmpeg, which the packages ship as DLLs (avcodec-63.dll ...).
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE static)
set(VCPKG_LIBRARY_LINKAGE static)
if(PORT STREQUAL "ffmpeg")
  set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()
