# Clones all modules of a version list into a directory.
#
# Usage:
#   cmake -DOAC_TREE_VERSIONS=<1.6|develop|file> [-DDEST=<dir>] [-DKEEP_GIT=OFF]
#         [-DOAC_TREE_GIT_BASE_URL=<url>] -P scripts/fetch_sources.cmake
#
# DEST defaults to modules/ of the bundle. The bundle build uses modules/<name> when present.

cmake_minimum_required(VERSION 3.13)

get_filename_component(bundle_dir ${CMAKE_CURRENT_LIST_DIR}/.. ABSOLUTE)
list(APPEND CMAKE_MODULE_PATH ${bundle_dir}/cmake/module)
include(versions)

if(NOT OAC_TREE_VERSIONS)
  message(FATAL_ERROR "Set -DOAC_TREE_VERSIONS=<name or file>")
endif()
if(NOT DEST)
  set(DEST ${bundle_dir}/modules)
endif()
if(NOT DEFINED KEEP_GIT)
  set(KEEP_GIT ON)
endif()
if(NOT OAC_TREE_GIT_BASE_URL)
  set(OAC_TREE_GIT_BASE_URL https://github.com/oac-tree)
endif()

oac_tree_load_versions(${OAC_TREE_VERSIONS})
find_package(Git REQUIRED)

foreach(module ${OAC_TREE_ALL_MODULES})
  set(target_dir ${DEST}/${module})
  if(EXISTS ${target_dir})
    message(FATAL_ERROR "${target_dir} already exists")
  endif()
  set(tag ${OAC_TREE_GIT_TAG_${module}})
  message(STATUS "Fetching ${module} @ ${tag}")
  execute_process(
    COMMAND ${GIT_EXECUTABLE} -c advice.detachedHead=false clone --quiet --depth 1
            --branch ${tag} ${OAC_TREE_GIT_BASE_URL}/${module}.git ${target_dir}
    RESULT_VARIABLE result)
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "Failed to clone ${module} @ ${tag}")
  endif()
  if(NOT KEEP_GIT)
    file(REMOVE_RECURSE ${target_dir}/.git)
  endif()
endforeach()
