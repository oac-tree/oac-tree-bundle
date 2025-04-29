include(GNUInstallDirs)
include(cmake_functions)

set(OAC_TREE_BUNDLE_INSTALL_DIR ${CMAKE_INSTALL_PREFIX})
set(OAC_TREE_BUNDLE_BIN_DIR ${CMAKE_INSTALL_BINDIR})
set(OAC_TREE_BUNDLE_LIB_DIR ${CMAKE_INSTALL_LIBDIR})
configure_file(${CMAKE_CURRENT_LIST_DIR}/oac-tree-path.sh.in ${CMAKE_INSTALL_PREFIX}/bin/oac-tree-path.sh @ONLY)
