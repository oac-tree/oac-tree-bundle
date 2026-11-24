include(GNUInstallDirs)
include(versions)
include(cmake_functions)

# Modules are built for the final prefix and installed with DESTDIR into the stage directory.
get_filename_component(OAC_TREE_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX} ABSOLUTE BASE_DIR ${CMAKE_BINARY_DIR})
set(OAC_TREE_STAGE_DIR ${CMAKE_BINARY_DIR}/stage)
set(OAC_TREE_STAGE_PREFIX ${OAC_TREE_STAGE_DIR}${OAC_TREE_INSTALL_PREFIX})
set(OAC_TREE_PREFIX_PATH ${OAC_TREE_STAGE_PREFIX} ${CMAKE_PREFIX_PATH})

oac_tree_load_versions(${OAC_TREE_VERSIONS})
message(STATUS "Module versions: ${OAC_TREE_VERSIONS_FILE}")
message(STATUS "Install prefix: ${OAC_TREE_INSTALL_PREFIX}")
