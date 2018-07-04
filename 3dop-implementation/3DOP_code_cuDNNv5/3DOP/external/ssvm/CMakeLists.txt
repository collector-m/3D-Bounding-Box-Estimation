# cmake file of the structSVMCP, by 
# Gellert Mattyus, DLR, email: gellert.mattyus@dlr.de

# This CMAKE file is intended to make it easier to integrate the structSVMCP with your own code or 3rd party libraries.
# It was tested in Ubuntu 12.04. For other OSs it might have to be adjusted.

# This is free software: you can redistribute it and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# This file is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along with Structured Prediction (SP).
# If not, see <http://www.gnu.org/licenses/>.

###########################

# find the dependencies
find_package( MPI REQUIRED ) ############## mpi always required

# the GUROBI_HOME environmental variable has to be set<Plug>(neosnippet_expand)
message(STATUS "$ENV{GUROBI_HOME}")
set(ENV{GUROBI_HOME} "~/pkgs/gurobi605/linux64")
message(STATUS "$ENV{GUROBI_HOME}/include")
message(STATUS "MPI compiler: ${MPI_CXX_COMPILER}")
set (CMAKE_CXX_COMPILER ${MPI_CXX_COMPILER})
SET( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} -fopenmp")
set(GUROBI_INCLUDE "$ENV{GUROBI_HOME}/include")
set(SUBPROJECT structSVMCP)
message(STATUS "configuring ${SUBPROJECT}")
#########################################
include_directories (${GUROBI_INCLUDE})
include_directories (${MPI_INCLUDE_PATH})
message(STATUS "MPI include path: ${MPI_INCLUDE_PATH}")
message(STATUS "GUROBI include path: ${GUROBI_INCLUDE}")

link_directories($ENV{GUROBI_HOME}/lib) # adds the gurobi lib directory to the library paths

#include_directories ("YOUR_OWN_CODE") # include to your own header files. !Set this according to your own project!
include_directories("/pkgs/eigen3")
set(EIGEN3_INCLUDE_DIR "/pkgs/eigen3")
set(CMAKE_MODULE_PATH "/pkgs/eigen3/cmake")
find_package(Eigen3 REQUIRED)
include_directories(EIGEN3_INCLUDE_DIR)


set (${SUBPROJECT}_srcs # the source files
		StructSVMCPnSlack.cpp)
set (${SUBPROJECT}_hrs # the header files
		Timer.h  TrainingSample.h)

message(STATUS "header files: ${${SUBPROJECT}_hrs}")
message(STATUS "source files: ${${SUBPROJECT}_srcs}")

		
add_executable(${SUBPROJECT} ${${SUBPROJECT}_srcs}  ${${SUBPROJECT}_hrs}) # we define it as an executable

# linking to libraries in your own project or 3rd party libraries
target_link_libraries("YOUR_OWN_LIBRARY") # !set this according to your own project!

target_link_libraries(${SUBPROJECT} gurobi_c++ gurobi60) # linking to the gurobi, you have to set the gurobi56 to your own gurobi version


#install (TARGETS ${SUBPROJECT} DESTINATION "SSVM") # uncomment this line to copy it during install
