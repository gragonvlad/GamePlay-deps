# Ensure the directory exists
if( NOT IS_DIRECTORY ${BGFX_DIR} )
	message( SEND_ERROR "Could not load bgfx, directory does not exist. ${BGFX_DIR}" )
	return()
endif()

if(NOT APPLE)
	set(BGFX_AMALGAMATED_SOURCE ${BGFX_DIR}/src/amalgamated.cpp)
else()
	set(BGFX_AMALGAMATED_SOURCE ${BGFX_DIR}/src/amalgamated.mm)
endif()

# Grab the bgfx source files
file( GLOB BGFX_SOURCES ${BGFX_DIR}/src/*.cpp ${BGFX_DIR}/src/*.mm ${BGFX_DIR}/src/*.h ${BGFX_DIR}/include/bgfx/*.h ${BGFX_DIR}/include/bgfx/c99/*.h )
if(BGFX_AMALGAMATED)
	set(BGFX_NOBUILD ${BGFX_SOURCES})
	list(REMOVE_ITEM BGFX_NOBUILD ${BGFX_AMALGAMATED_SOURCE})
	foreach(BGFX_SRC ${BGFX_NOBUILD})
		set_source_files_properties( ${BGFX_SRC} PROPERTIES HEADER_FILE_ONLY ON )
	endforeach()
else()
	# Do not build using amalgamated sources
	set_source_files_properties( ${BGFX_DIR}/src/amalgamated.cpp PROPERTIES HEADER_FILE_ONLY ON )
	set_source_files_properties( ${BGFX_DIR}/src/amalgamated.mm PROPERTIES HEADER_FILE_ONLY ON )
endif()

# Create the bgfx target
add_library( bgfx ${BGFX_SOURCES} )

# Enable BGFX_CONFIG_DEBUG in Debug configuration
target_compile_definitions( bgfx PRIVATE "$<$<CONFIG:Debug>:BGFX_CONFIG_DEBUG=1>" )
if(BGFX_CONFIG_DEBUG)
	target_compile_definitions( bgfx PRIVATE BGFX_CONFIG_DEBUG=1)
endif()

# Special Visual Studio Flags
if( MSVC )
	target_compile_definitions( bgfx PRIVATE "_CRT_SECURE_NO_WARNINGS" )
endif()

# Includes
target_include_directories( bgfx PRIVATE ${BGFX_DIR}/3rdparty ${BGFX_DIR}/3rdparty/dxsdk/include ${BGFX_DIR}/3rdparty/khronos )
target_include_directories( bgfx PUBLIC ${BGFX_DIR}/include )

# bgfx depends on bx and bimg
target_link_libraries( bgfx PUBLIC bx bimg )

# ovr support
if( BGFX_USE_OVR )
	target_link_libraries( bgfx PUBLIC ovr )
endif()

# Frameworks required on OS X
if( APPLE )
	find_library( COCOA_LIBRARY Cocoa )
	find_library( METAL_LIBRARY Metal )
	find_library( QUARTZCORE_LIBRARY QuartzCore )
	mark_as_advanced( COCOA_LIBRARY )
	mark_as_advanced( METAL_LIBRARY )
	mark_as_advanced( QUARTZCORE_LIBRARY )
	target_link_libraries( bgfx PUBLIC ${COCOA_LIBRARY} ${METAL_LIBRARY} ${QUARTZCORE_LIBRARY} )
endif()

if( UNIX AND NOT APPLE )
	find_package(X11 REQUIRED)
	find_package(OpenGL REQUIRED)
	#The following commented libraries are linked by bx
	#find_package(Threads REQUIRED)
	#find_library(LIBRT_LIBRARIES rt)
	#find_library(LIBDL_LIBRARIES dl)
	target_link_libraries( bgfx PUBLIC ${X11_LIBRARIES} ${OPENGL_LIBRARIES})
endif()

# Exclude mm files if not on OS X
if( NOT APPLE )
	set_source_files_properties( ${BGFX_DIR}/src/glcontext_eagl.mm PROPERTIES HEADER_FILE_ONLY ON )
	set_source_files_properties( ${BGFX_DIR}/src/glcontext_nsgl.mm PROPERTIES HEADER_FILE_ONLY ON )
	set_source_files_properties( ${BGFX_DIR}/src/renderer_mtl.mm PROPERTIES HEADER_FILE_ONLY ON )
endif()

# Exclude glx context on non-unix
if( NOT UNIX OR APPLE )
	set_source_files_properties( ${BGFX_DIR}/src/glcontext_glx.cpp PROPERTIES HEADER_FILE_ONLY ON )
endif()

# Put in a "bgfx" folder in Visual Studio
set_target_properties( bgfx PROPERTIES FOLDER "bgfx" )

# Export debug build as "bgfxd"
set_target_properties( bgfx PROPERTIES OUTPUT_NAME_DEBUG "bgfxd" )
