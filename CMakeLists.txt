cmake_minimum_required(VERSION 3.13...3.31)
project(oac-tree-bundle VERSION 1.0.0)

option(COA_NO_PLUGINS "Do not build/install oac-tree plugins" OFF)
option(COA_NO_GUI "Do not build/install oac-tree GUI" OFF)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake/module)

include(configuration)

add_local_module(sup-dto)

add_local_module(sup-utils)

add_local_module(sup-di
  DEPENDS sup-utils)

add_local_module(sup-protocol
  DEPENDS sup-dto sup-utils sup-di)

add_local_module(sup-epics
  DEPENDS sup-protocol)

add_local_module(oac-tree
  DEPENDS sup-dto sup-utils)

add_local_module(oac-tree-server
  DEPENDS oac-tree sup-epics)


if (NOT COA_NO_PLUGINS)
add_local_module(oac-tree-control
  DEPENDS oac-tree)

add_local_module(oac-tree-epics
  DEPENDS oac-tree sup-epics)

add_local_module(sup-mathexpr)

add_local_module(oac-tree-mathexpr
  DEPENDS oac-tree sup-mathexpr)
endif()

if (NOT COA_NO_GUI)
add_local_module(sup-gui-extra)

add_local_module(sup-mvvm)

add_local_module(sup-gui-core
  DEPENDS sup-gui-extra sup-mvvm sup-dto)

add_local_module(oac-tree-gui
  DEPENDS oac-tree oac-tree-server sup-gui-core sup-epics)
endif()
