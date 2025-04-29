include(cmake_functions)

message(INFO "XXX ${CMAKE_INSTALL_PREFIX} YYY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")

message(INFO "${SUP_MVVM_PROJECT_DIR}")
configure_file(${CMAKE_CURRENT_LIST_DIR}/oac-tree-path.sh.in ${CMAKE_INSTALL_PREFIX}/bin/oac-tree-path.sh @ONLY)
