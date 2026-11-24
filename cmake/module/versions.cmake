# Loading of module version lists from versions/<name>.cmake.

get_filename_component(OAC_TREE_VERSIONS_DIR ${CMAKE_CURRENT_LIST_DIR}/../../versions ABSOLUTE)

#! Registers a module and its git tag or branch. Used in version list files.
macro(oac_tree_module name tag)
  list(APPEND OAC_TREE_ALL_MODULES ${name})
  set(OAC_TREE_GIT_TAG_${name} ${tag})
endmacro()

#! Loads a version list: a name in versions/ (e.g. 1.6, develop) or a path to a file.
#! Sets OAC_TREE_VERSIONS_FILE, OAC_TREE_ALL_MODULES and OAC_TREE_GIT_TAG_<module>.
macro(oac_tree_load_versions versions)
  if(EXISTS ${OAC_TREE_VERSIONS_DIR}/${versions}.cmake)
    set(OAC_TREE_VERSIONS_FILE ${OAC_TREE_VERSIONS_DIR}/${versions}.cmake)
  elseif(EXISTS ${versions} AND NOT IS_DIRECTORY ${versions})
    get_filename_component(OAC_TREE_VERSIONS_FILE ${versions} ABSOLUTE)
  else()
    file(GLOB _available RELATIVE ${OAC_TREE_VERSIONS_DIR} ${OAC_TREE_VERSIONS_DIR}/*.cmake)
    string(REPLACE ".cmake" "" _available "${_available}")
    list(JOIN _available ", " _available)
    message(FATAL_ERROR "Unknown versions '${versions}'. Available: ${_available}")
  endif()
  set(OAC_TREE_ALL_MODULES)
  include(${OAC_TREE_VERSIONS_FILE})
endmacro()
