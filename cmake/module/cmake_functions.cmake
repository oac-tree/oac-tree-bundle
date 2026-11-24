include(ExternalProject)

if(OAC_TREE_UPDATE)
  set(OAC_TREE_UPDATE_DISCONNECTED OFF)
else()
  set(OAC_TREE_UPDATE_DISCONNECTED ON)
endif()

#! Adds a module as an external project installed with DESTDIR=OAC_TREE_STAGE_DIR.
#! Source: OAC_TREE_SOURCE_DIR_<module>, then modules/<module>, then a git clone.
function(add_local_module module_name)
  cmake_parse_arguments(
    PARSE_ARGV 1 LOCAL_MODULE "" "" "DEPENDS")

  set(local_dir ${PROJECT_SOURCE_DIR}/modules/${module_name})
  if(OAC_TREE_SOURCE_DIR_${module_name})
    get_filename_component(source_dir ${OAC_TREE_SOURCE_DIR_${module_name}} ABSOLUTE)
    set(source_args SOURCE_DIR ${source_dir})
    set(origin "${source_dir}")
  elseif(EXISTS ${local_dir}/CMakeLists.txt)
    set(source_args SOURCE_DIR ${local_dir})
    set(origin "${local_dir}")
  else()
    if(NOT DEFINED OAC_TREE_GIT_TAG_${module_name})
      message(FATAL_ERROR "No version of ${module_name} in ${OAC_TREE_VERSIONS_FILE}")
    endif()
    set(git_tag ${OAC_TREE_GIT_TAG_${module_name}})
    set(source_args
      GIT_REPOSITORY ${OAC_TREE_GIT_BASE_URL}/${module_name}.git
      GIT_TAG ${git_tag}
      GIT_SHALLOW TRUE
      GIT_PROGRESS TRUE
      UPDATE_DISCONNECTED ${OAC_TREE_UPDATE_DISCONNECTED})
    set(origin "${OAC_TREE_GIT_BASE_URL}/${module_name}.git @ ${git_tag}")
  endif()
  message(STATUS "${module_name}: ${origin}")

  ExternalProject_Add(${module_name}
    ${source_args}
    CMAKE_ARGS
      -DCMAKE_INSTALL_PREFIX=${OAC_TREE_INSTALL_PREFIX}
      -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
      -DCOA_BUILD_TESTS=${COA_BUILD_TESTS}
    CMAKE_CACHE_ARGS
      -DCMAKE_PREFIX_PATH:STRING=${OAC_TREE_PREFIX_PATH}
      -DCMAKE_FIND_USE_PACKAGE_REGISTRY:BOOL=OFF
    INSTALL_COMMAND
      ${CMAKE_COMMAND} -E env DESTDIR=${OAC_TREE_STAGE_DIR}
      ${CMAKE_COMMAND} --build <BINARY_DIR> --target install
    DEPENDS
      ${LOCAL_MODULE_DEPENDS}
  )
endfunction()
