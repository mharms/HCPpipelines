#!/bin/bash

#
# # Compile_MATLAB_code.sh
#
# Compile the MATLAB code necessary for running Resting State Stats
#
# ## Copyright Notice
#
# Copyright (C) 2019 The Connectome Coordination Facility (CCF)
#
# ## Author(s)
#
# * Timothy B. Brown, Neuroinformatics Research Group, Washington University in St. Louis
#
# ## Product
#
# [Human Connectome Project](https://www.humanconnectome.org) (HCP) Pipelines
#
# ## License
#
# See the [LICENSE](https://github.com/Washington-University/HCPpipelines/blob/master/LICENSE.md) file
#


# NOTE: while the matlab interpreter is happy to follow symlinks found on the matlab path, the matlab compiler
# not only does not follow them, it also remembers that they exist and refuses to allow anything with the same
# name found in a later -I option to be used.  @gifti used to be a symlink, requiring the compilation to
# include the real location of the @gifti folder, before a folder that contains an @gifti symlink
# (since the -I option *appends* folders to the search path, in the order listed).

# This problem is now avoided by putting a copy of the @gifti folder directly into the cifti-legacy folder, so
# that no symlinks are involved, and @gifti will always be available if cifti-legacy is being used.


# ------------------------------------------------------------------------------
# Compile the RestingStateStats MATLAB function
# ------------------------------------------------------------------------------
compile_RestingStateStats()
{
	local app_name=RestingStateStats
	local output_directory=Compiled_${app_name}

	pushd ${HCPPIPEDIR}/RestingStateStats/scripts > /dev/null
	log_Msg "Working in ${PWD}"

	log_Msg "Creating output directory: ${output_directory}"
	mkdir -p ${output_directory}
	
	log_Msg "Compiling ${app_name} application"
	${MATLAB_HOME}/bin/mcc -m -v ${app_name}.m \
				  -I ${HCPPIPEDIR}/global/matlab \
				  -I ${HCPCIFTIRWDIR} \
				  -I ${HCPPIPEDIR}/global/fsl/etc/matlab \
				  -d ${output_directory}
	
	popd > /dev/null
}

# ------------------------------------------------------------------------------
#  Main processing of script.
# ------------------------------------------------------------------------------
main()
{
	compile_RestingStateStats
}

# ------------------------------------------------------------------------------
#  "Global" processing - everything above here should be in a function
# ------------------------------------------------------------------------------

# Verify that HCPPIPEDIR environment variable is set
if [ -z "${HCPPIPEDIR}" ]; then
	script_name=$(basename "${0}")
	echo "${script_name}: ABORTING: HCPPIPEDIR environment variable must be set"
	exit 1
fi

# Load function libraries
source "${HCPPIPEDIR}/global/scripts/debug.shlib" "$@" # Debugging functions; also sources log.shlib

# Verify required environment variables are set and log value
log_Check_Env_Var HCPPIPEDIR
log_Check_Env_Var MATLAB_HOME
log_Check_Env_Var HCPCIFTIRWDIR

# Invoke the main processing
main "$@"

