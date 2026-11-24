# Installs the staged modules and generates oac-tree-path.sh.

install(DIRECTORY ${OAC_TREE_STAGE_PREFIX}/ DESTINATION . USE_SOURCE_PERMISSIONS)

install(CODE "
  set(OAC_TREE_CONFIGURED_PREFIX \"${OAC_TREE_INSTALL_PREFIX}\")
  set(OAC_TREE_PATH_TEMPLATE \"${CMAKE_CURRENT_LIST_DIR}/oac-tree-path.sh.in\")
  set(OAC_TREE_BUNDLE_BIN_DIR \"${CMAKE_INSTALL_BINDIR}\")
  set(OAC_TREE_BUNDLE_LIB_DIR \"${CMAKE_INSTALL_LIBDIR}\")
")

install(CODE [[
  get_filename_component(OAC_TREE_BUNDLE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}" ABSOLUTE)
  if(NOT OAC_TREE_BUNDLE_INSTALL_DIR STREQUAL OAC_TREE_CONFIGURED_PREFIX)
    message(WARNING "Installing to ${OAC_TREE_BUNDLE_INSTALL_DIR}, but modules were built for "
      "${OAC_TREE_CONFIGURED_PREFIX}. Set CMAKE_INSTALL_PREFIX at configure time instead.")
  endif()
  set(path_script "$ENV{DESTDIR}${OAC_TREE_BUNDLE_INSTALL_DIR}/${OAC_TREE_BUNDLE_BIN_DIR}/oac-tree-path.sh")
  message(STATUS "Installing: ${path_script}")
  configure_file("${OAC_TREE_PATH_TEMPLATE}" "${path_script}" @ONLY)
]])
