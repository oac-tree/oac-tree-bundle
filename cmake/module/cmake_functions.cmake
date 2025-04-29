include(ExternalProject)

function(add_local_module module_name)
  cmake_parse_arguments(
    PARSE_ARGV 1 LOCAL_MODULE "" "" "DEPENDS")
  ExternalProject_Add(${module_name}
    SOURCE_DIR
      ${CMAKE_CURRENT_SOURCE_DIR}/modules/${module_name}
    CMAKE_ARGS
      -DCMAKE_INSTALL_PREFIX=${CMAKE_INSTALL_PREFIX}
      -DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
    DEPENDS
      ${LOCAL_MODULE_DEPENDS}
  )
endfunction()
