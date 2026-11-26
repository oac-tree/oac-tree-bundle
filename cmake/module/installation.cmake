# Installs the staged modules and generates oac-tree-path.sh.

# Copies build/stage/<prefix>/ to the install prefix.
install(DIRECTORY ${OAC_TREE_STAGE_PREFIX}/ DESTINATION . USE_SOURCE_PERMISSIONS)

# Passes configure-time values to the install script.
install(CODE "
  set(OAC_TREE_CONFIGURED_PREFIX \"${OAC_TREE_INSTALL_PREFIX}\")
  set(OAC_TREE_PATH_TEMPLATE \"${CMAKE_CURRENT_LIST_DIR}/oac-tree-path.sh.in\")
  set(OAC_TREE_BUNDLE_BIN_DIR \"${CMAKE_INSTALL_BINDIR}\")
  set(OAC_TREE_BUNDLE_LIB_DIR \"${CMAKE_INSTALL_LIBDIR}\")
")

# Runs at install time. Bracket syntax defers ${...} expansion, so CMAKE_INSTALL_PREFIX
# includes a --prefix override.
install(CODE [[
  get_filename_component(OAC_TREE_BUNDLE_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}" ABSOLUTE)

  # Compiled-in paths of modules point to the configured prefix.
  if(NOT OAC_TREE_BUNDLE_INSTALL_DIR STREQUAL OAC_TREE_CONFIGURED_PREFIX)
    message(WARNING "Installing to ${OAC_TREE_BUNDLE_INSTALL_DIR}, but modules were built for "
      "${OAC_TREE_CONFIGURED_PREFIX}. Set CMAKE_INSTALL_PREFIX at configure time instead.")
  endif()

  # Generates oac-tree-path.sh. @ONLY keeps the script's own ${...} variables.
  set(path_script "$ENV{DESTDIR}${OAC_TREE_BUNDLE_INSTALL_DIR}/${OAC_TREE_BUNDLE_BIN_DIR}/oac-tree-path.sh")
  message(STATUS "Installing: ${path_script}")
  configure_file("${OAC_TREE_PATH_TEMPLATE}" "${path_script}" @ONLY)
]])
