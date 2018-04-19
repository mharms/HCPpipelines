#!/bin/bash

set -e # If any commands exit with non-zero value, this script exits

# ------------------------------------------------------------------------------
#  Verify HCPPIPEDIR environment variable is set
# ------------------------------------------------------------------------------

if [ -z "${HCPPIPEDIR}" ]; then
	script_name=$(basename "${0}")
	echo "${script_name}: ABORTING: HCPPIPEDIR environment variable must be set"
	exit 1
fi

# ------------------------------------------------------------------------------
#  Load function libraries
# ------------------------------------------------------------------------------

source ${HCPPIPEDIR}/global/scripts/log.shlib # Logging related functions
log_Msg "HCPPIPEDIR: ${HCPPIPEDIR}"

# ------------------------------------------------------------------------------
#  Verify other needed environment variables are set
# ------------------------------------------------------------------------------

if [ -z "${MSMBINDIR}" ]; then
	log_Err_Abort "MSMBINDIR environment variable must be set"
fi
log_Msg "MSMBINDIR: ${MSMBINDIR}"

if [ -z "${MSMCONFIGDIR}" ]; then
	log_Err_Abort "MSMCONFIGDIR environment variable must be set"
fi
log_Msg "MSMCONFIGDIR: ${MSMCONFIGDIR}"

if [ -z "${CARET7DIR}" ]; then
	log_Err_Abort "CARET7DIR environment variable must be set"
fi
log_Msg "CARET7DIR: ${CARET7DIR}"

# ------------------------------------------------------------------------------
#  Gather and show positional parameters
# ------------------------------------------------------------------------------

log_Msg "START"

StudyFolder="$1"
log_Msg "StudyFolder: ${StudyFolder}"

Subject="$2"
log_Msg "Subject: ${Subject}"

T1wFolder="$3"
log_Msg "T1wFolder: ${T1wFolder}"

AtlasSpaceFolder="$4"
log_Msg "AtlasSpaceFolder: ${AtlasSpaceFolder}"

NativeFolder="$5"
log_Msg "NativeFolder: ${NativeFolder}"

FreeSurferFolder="$6"
log_Msg "FreeSurferFolder: ${FreeSurferFolder}"

FreeSurferInput="$7"
log_Msg "FreeSurferInput: ${FreeSurferInput}"

T1wImage="$8"
log_Msg "T1wImage: ${T1wImage}"

T2wImage="$9"
log_Msg "T2wImage: ${T2wImage}"

SurfaceAtlasDIR="${10}"
log_Msg "SurfaceAtlasDIR: ${SurfaceAtlasDIR}"

HighResMesh="${11}"
log_Msg "HighResMesh: ${HighResMesh}"

LowResMeshes="${12}"
log_Msg "LowResMeshes: ${LowResMeshes}"

AtlasTransform="${13}"
log_Msg "AtlasTransform: ${AtlasTransform}"

InverseAtlasTransform="${14}"
log_Msg "InverseAtlasTransform: ${InverseAtlasTransform}"

AtlasSpaceT1wImage="${15}"
log_Msg "AtlasSpaceT1wImage: ${AtlasSpaceT1wImage}"

AtlasSpaceT2wImage="${16}"
log_Msg "AtlasSpaceT2wImage: ${AtlasSpaceT2wImage}"

T1wImageBrainMask="${17}"
log_Msg "T1wImageBrainMask: ${T1wImageBrainMask}"

FreeSurferLabels="${18}"
log_Msg "FreeSurferLabels: ${FreeSurferLabels}"

GrayordinatesSpaceDIR="${19}"
log_Msg "GrayordinatesSpaceDIR: ${GrayordinatesSpaceDIR}"

GrayordinatesResolutions="${20}"
log_Msg "GrayordinatesResolutions: ${GrayordinatesResolutions}"

SubcorticalGrayLabels="${21}"
log_Msg "SubcorticalGrayLabels: ${SubcorticalGrayLabels}"

RegName="${22}"
log_Msg "RegName: ${RegName}"

InflateExtraScale="${23}"
log_Msg "InflateExtraScale: ${InflateExtraScale}"

LowResMeshes=${LowResMeshes//@/ }
log_Msg "LowResMeshes: ${LowResMeshes}"

GrayordinatesResolutions=${GrayordinatesResolutions//@/ }
log_Msg "GrayordinatesResolutions: ${GrayordinatesResolutions}"

#Make some folders for this and later scripts
if [ ! -e "$T1wFolder"/"$NativeFolder" ] ; then
	mkdir -p "$T1wFolder"/"$NativeFolder"
fi
if [ ! -e "$AtlasSpaceFolder"/ROIs ] ; then
	mkdir -p "$AtlasSpaceFolder"/ROIs
fi
if [ ! -e "$AtlasSpaceFolder"/Results ] ; then
	mkdir "$AtlasSpaceFolder"/Results
fi
if [ ! -e "$AtlasSpaceFolder"/"$NativeFolder" ] ; then
	mkdir "$AtlasSpaceFolder"/"$NativeFolder"
fi
if [ ! -e "$AtlasSpaceFolder"/fsaverage ] ; then
	mkdir "$AtlasSpaceFolder"/fsaverage
fi
for LowResMesh in ${LowResMeshes} ; do
	if [ ! -e "$AtlasSpaceFolder"/fsaverage_LR"$LowResMesh"k ] ; then
		mkdir "$AtlasSpaceFolder"/fsaverage_LR"$LowResMesh"k
	fi
	if [ ! -e "$T1wFolder"/fsaverage_LR"$LowResMesh"k ] ; then
		mkdir "$T1wFolder"/fsaverage_LR"$LowResMesh"k
	fi
done

#Find c_ras offset between FreeSurfer surface and volume and generate matrix to transform surfaces
MatrixX=$(mri_info "$FreeSurferFolder"/mri/brain.finalsurfs.mgz | grep "c_r" | cut -d "=" -f 5 | sed s/" "/""/g)
MatrixY=$(mri_info "$FreeSurferFolder"/mri/brain.finalsurfs.mgz | grep "c_a" | cut -d "=" -f 5 | sed s/" "/""/g)
MatrixZ=$(mri_info "$FreeSurferFolder"/mri/brain.finalsurfs.mgz | grep "c_s" | cut -d "=" -f 5 | sed s/" "/""/g)
echo "1 0 0 ""$MatrixX" > "$FreeSurferFolder"/mri/c_ras.mat
echo "0 1 0 ""$MatrixY" >> "$FreeSurferFolder"/mri/c_ras.mat
echo "0 0 1 ""$MatrixZ" >> "$FreeSurferFolder"/mri/c_ras.mat
echo "0 0 0 1" >> "$FreeSurferFolder"/mri/c_ras.mat

#Convert FreeSurfer Volumes
for Image in wmparc aparc.a2009s+aseg aparc+aseg ; do
	if [ -e "$FreeSurferFolder"/mri/"$Image".mgz ] ; then
		mri_convert -rt nearest -rl "$T1wFolder"/"$T1wImage".nii.gz "$FreeSurferFolder"/mri/"$Image".mgz "$T1wFolder"/"$Image"_1mm.nii.gz
		applywarp --rel --interp=nn -i "$T1wFolder"/"$Image"_1mm.nii.gz -r "$AtlasSpaceFolder"/"$AtlasSpaceT1wImage" --premat=$FSLDIR/etc/flirtsch/ident.mat -o "$T1wFolder"/"$Image".nii.gz
		applywarp --rel --interp=nn -i "$T1wFolder"/"$Image"_1mm.nii.gz -r "$AtlasSpaceFolder"/"$AtlasSpaceT1wImage" -w "$AtlasTransform" -o "$AtlasSpaceFolder"/"$Image".nii.gz
		${CARET7DIR}/wb_command -volume-label-import "$T1wFolder"/"$Image".nii.gz "$FreeSurferLabels" "$T1wFolder"/"$Image".nii.gz -drop-unused-labels
		${CARET7DIR}/wb_command -volume-label-import "$AtlasSpaceFolder"/"$Image".nii.gz "$FreeSurferLabels" "$AtlasSpaceFolder"/"$Image".nii.gz -drop-unused-labels
	fi
done

#Create FreeSurfer Brain Mask
fslmaths "$T1wFolder"/wmparc_1mm.nii.gz -bin -dilD -dilD -dilD -ero -ero "$T1wFolder"/"$T1wImageBrainMask"_1mm.nii.gz
${CARET7DIR}/wb_command -volume-fill-holes "$T1wFolder"/"$T1wImageBrainMask"_1mm.nii.gz "$T1wFolder"/"$T1wImageBrainMask"_1mm.nii.gz
fslmaths "$T1wFolder"/"$T1wImageBrainMask"_1mm.nii.gz -bin "$T1wFolder"/"$T1wImageBrainMask"_1mm.nii.gz
applywarp --rel --interp=nn -i "$T1wFolder"/"$T1wImageBrainMask"_1mm.nii.gz -r "$AtlasSpaceFolder"/"$AtlasSpaceT1wImage" --premat=$FSLDIR/etc/flirtsch/ident.mat -o "$T1wFolder"/"$T1wImageBrainMask".nii.gz
applywarp --rel --interp=nn -i "$T1wFolder"/"$T1wImageBrainMask"_1mm.nii.gz -r "$AtlasSpaceFolder"/"$AtlasSpaceT1wImage" -w "$AtlasTransform" -o "$AtlasSpaceFolder"/"$T1wImageBrainMask".nii.gz

#Add volume files to spec files
${CARET7DIR}/wb_command -add-to-spec-file "$T1wFolder"/"$NativeFolder"/"$Subject".native.wb.spec INVALID "$T1wFolder"/"$T2wImage".nii.gz
${CARET7DIR}/wb_command -add-to-spec-file "$T1wFolder"/"$NativeFolder"/"$Subject".native.wb.spec INVALID "$T1wFolder"/"$T1wImage".nii.gz

${CARET7DIR}/wb_command -add-to-spec-file "$AtlasSpaceFolder"/"$NativeFolder"/"$Subject".native.wb.spec INVALID "$AtlasSpaceFolder"/"$AtlasSpaceT2wImage".nii.gz
${CARET7DIR}/wb_command -add-to-spec-file "$AtlasSpaceFolder"/"$NativeFolder"/"$Subject".native.wb.spec INVALID "$AtlasSpaceFolder"/"$AtlasSpaceT1wImage".nii.gz

${CARET7DIR}/wb_command -add-to-spec-file "$AtlasSpaceFolder"/"$Subject"."$HighResMesh"k_fs_LR.wb.spec INVALID "$AtlasSpaceFolder"/"$AtlasSpaceT2wImage".nii.gz
${CARET7DIR}/wb_command -add-to-spec-file "$AtlasSpaceFolder"/"$Subject"."$HighResMesh"k_fs_LR.wb.spec INVALID "$AtlasSpaceFolder"/"$AtlasSpaceT1wImage".nii.gz

for LowResMesh in ${LowResMeshes} ; do
	${CARET7DIR}/wb_command -add-to-spec-file "$AtlasSpaceFolder"/fsaverage_LR"$LowResMesh"k/"$Subject"."$LowResMesh"k_fs_LR.wb.spec INVALID "$AtlasSpaceFolder"/"$AtlasSpaceT2wImage".nii.gz
	${CARET7DIR}/wb_command -add-to-spec-file "$AtlasSpaceFolder"/fsaverage_LR"$LowResMesh"k/"$Subject"."$LowResMesh"k_fs_LR.wb.spec INVALID "$AtlasSpaceFolder"/"$AtlasSpaceT1wImage".nii.gz

	${CARET7DIR}/wb_command -add-to-spec-file "$T1wFolder"/fsaverage_LR"$LowResMesh"k/"$Subject"."$LowResMesh"k_fs_LR.wb.spec INVALID "$T1wFolder"/"$T2wImage".nii.gz
	${CARET7DIR}/wb_command -add-to-spec-file "$T1wFolder"/fsaverage_LR"$LowResMesh"k/"$Subject"."$LowResMesh"k_fs_LR.wb.spec INVALID "$T1wFolder"/"$T1wImage".nii.gz
done

#Import Subcortical ROIs
for GrayordinatesResolution in ${GrayordinatesResolutions} ; do
	cp "$GrayordinatesSpaceDIR"/Atlas_ROIs."$GrayordinatesResolution".nii.gz "$AtlasSpaceFolder"/ROIs/Atlas_ROIs."$GrayordinatesResolution".nii.gz
	applywarp --interp=nn -i "$AtlasSpaceFolder"/wmparc.nii.gz -r "$AtlasSpaceFolder"/ROIs/Atlas_ROIs."$GrayordinatesResolution".nii.gz -o "$AtlasSpaceFolder"/ROIs/wmparc."$GrayordinatesResolution".nii.gz
	${CARET7DIR}/wb_command -volume-label-import "$AtlasSpaceFolder"/ROIs/wmparc."$GrayordinatesResolution".nii.gz "$FreeSurferLabels" "$AtlasSpaceFolder"/ROIs/wmparc."$GrayordinatesResolution".nii.gz -drop-unused-labels
	applywarp --interp=nn -i "$SurfaceAtlasDIR"/Avgwmparc.nii.gz -r "$AtlasSpaceFolder"/ROIs/Atlas_ROIs."$GrayordinatesResolution".nii.gz -o "$AtlasSpaceFolder"/ROIs/Atlas_wmparc."$GrayordinatesResolution".nii.gz
	${CARET7DIR}/wb_command -volume-label-import "$AtlasSpaceFolder"/ROIs/Atlas_wmparc."$GrayordinatesResolution".nii.gz "$FreeSurferLabels" "$AtlasSpaceFolder"/ROIs/Atlas_wmparc."$GrayordinatesResolution".nii.gz -drop-unused-labels
	${CARET7DIR}/wb_command -volume-label-import "$AtlasSpaceFolder"/ROIs/wmparc."$GrayordinatesResolution".nii.gz ${SubcorticalGrayLabels} "$AtlasSpaceFolder"/ROIs/ROIs."$GrayordinatesResolution".nii.gz -discard-others
	applywarp --interp=spline -i "$AtlasSpaceFolder"/"$AtlasSpaceT2wImage".nii.gz -r "$AtlasSpaceFolder"/ROIs/Atlas_ROIs."$GrayordinatesResolution".nii.gz -o "$AtlasSpaceFolder"/"$AtlasSpaceT2wImage"."$GrayordinatesResolution".nii.gz
	applywarp --interp=spline -i "$AtlasSpaceFolder"/"$AtlasSpaceT1wImage".nii.gz -r "$AtlasSpaceFolder"/ROIs/Atlas_ROIs."$GrayordinatesResolution".nii.gz -o "$AtlasSpaceFolder"/"$AtlasSpaceT1wImage"."$GrayordinatesResolution".nii.gz
done

#Loop through left and right hemispheres
for Hemisphere in L R ; do
	#Set a bunch of different ways of saying left and right
	if [ $Hemisphere = "L" ] ; then
		hemisphere="l"
		Structure="CORTEX_LEFT"
	elif [ $Hemisphere = "R" ] ; then
		hemisphere="r"
		Structure="CORTEX_RIGHT"
	fi

	### ------ BEGIN section on Native Mesh Processing ------
	#Convert and volumetrically register white and pial surfaces making linear and nonlinear copies, add each to the appropriate spec file
	Types="ANATOMICAL@GRAY_WHITE ANATOMICAL@PIAL"
	i=1
	for Surface in white pial ; do
		Type=$(echo "$Types" | cut -d " " -f $i)
		Secondary=$(echo "$Type" | cut -d "@" -f 2)
		Type=$(echo "$Type" | cut -d "@" -f 1)
		if [ ! $Secondary = $Type ] ; then
			Secondary=$(echo " -surface-secondary-type ""$Secondary")
		else
			Secondary=""
		fi

		# Set up some variables for very common strings
		AtlasNativeSubj="$AtlasSpaceFolder"/"$NativeFolder"/"$Subject"
		AtlasNativeSubjHemi="$AtlasSpaceFolder"/"$NativeFolder"/"$Subject"."$Hemisphere"
		AtlasSubjHemi="$AtlasSpaceFolder"/"$Subject"."$Hemisphere"
		T1wNativeSubjHemi="$T1wFolder"/"$NativeFolder"/"$Subject"."$Hemisphere"
		
		mris_convert "$FreeSurferFolder"/surf/"$hemisphere"h."$Surface" ${T1wNativeSubjHemi}."$Surface".native.surf.gii
		${CARET7DIR}/wb_command -set-structure ${T1wNativeSubjHemi}."$Surface".native.surf.gii ${Structure} -surface-type $Type$Secondary
		${CARET7DIR}/wb_command -surface-apply-affine ${T1wNativeSubjHemi}."$Surface".native.surf.gii "$FreeSurferFolder"/mri/c_ras.mat ${T1wNativeSubjHemi}."$Surface".native.surf.gii
		${CARET7DIR}/wb_command -add-to-spec-file "$T1wFolder"/"$NativeFolder"/"$Subject".native.wb.spec $Structure ${T1wNativeSubjHemi}."$Surface".native.surf.gii
		${CARET7DIR}/wb_command -surface-apply-warpfield ${T1wNativeSubjHemi}."$Surface".native.surf.gii "$InverseAtlasTransform".nii.gz ${AtlasNativeSubjHemi}."$Surface".native.surf.gii -fnirt "$AtlasTransform".nii.gz
		${CARET7DIR}/wb_command -add-to-spec-file ${AtlasNativeSubj}.native.wb.spec $Structure ${AtlasNativeSubjHemi}."$Surface".native.surf.gii
		i=$(( i+1 ))
	done

	#Create midthickness by averaging white and pial surfaces and use it to make inflated surfacess
	for Folder in "$T1wFolder" "$AtlasSpaceFolder" ; do

		FolderNativeSubj="$Folder"/"$NativeFolder"/"$Subject"
		FolderNativeSubjHemi="$Folder"/"$NativeFolder"/"$Subject"."$Hemisphere"
		
		${CARET7DIR}/wb_command -surface-average ${FolderNativeSubjHemi}.midthickness.native.surf.gii -surf ${FolderNativeSubjHemi}.white.native.surf.gii -surf ${FolderNativeSubjHemi}.pial.native.surf.gii
		${CARET7DIR}/wb_command -set-structure ${FolderNativeSubjHemi}.midthickness.native.surf.gii ${Structure} -surface-type ANATOMICAL -surface-secondary-type MIDTHICKNESS
		${CARET7DIR}/wb_command -add-to-spec-file ${FolderNativeSubj}.native.wb.spec $Structure ${FolderNativeSubjHemi}.midthickness.native.surf.gii

		#get number of vertices from native file
		NativeVerts=$(${CARET7DIR}/wb_command -file-information ${FolderNativeSubjHemi}.midthickness.native.surf.gii | grep 'Number of Vertices:' | cut -f2 -d: | tr -d '[:space:]')

		#HCP fsaverage_LR32k used -iterations-scale 0.75. Compute new param value for native mesh density
		NativeInflationScale=$(echo "scale=4; $InflateExtraScale * 0.75 * $NativeVerts / 32492" | bc -l)

		${CARET7DIR}/wb_command -surface-generate-inflated ${FolderNativeSubjHemi}.midthickness.native.surf.gii ${FolderNativeSubjHemi}.inflated.native.surf.gii ${FolderNativeSubjHemi}.very_inflated.native.surf.gii -iterations-scale $NativeInflationScale
		${CARET7DIR}/wb_command -add-to-spec-file ${FolderNativeSubj}.native.wb.spec $Structure ${FolderNativeSubjHemi}.inflated.native.surf.gii
		${CARET7DIR}/wb_command -add-to-spec-file ${FolderNativeSubj}.native.wb.spec $Structure ${FolderNativeSubjHemi}.very_inflated.native.surf.gii
	done

	#Convert original and registered spherical surfaces and add them to the nonlinear spec file
	for Surface in sphere.reg sphere ; do
		mris_convert "$FreeSurferFolder"/surf/"$hemisphere"h."$Surface" ${AtlasNativeSubjHemi}."$Surface".native.surf.gii
		${CARET7DIR}/wb_command -set-structure ${AtlasNativeSubjHemi}."$Surface".native.surf.gii ${Structure} -surface-type SPHERICAL
	done
	${CARET7DIR}/wb_command -add-to-spec-file ${AtlasNativeSubj}.native.wb.spec $Structure ${AtlasNativeSubjHemi}.sphere.native.surf.gii

	#Add more files to the spec file and convert other FreeSurfer surface data to metric/GIFTI including sulc, curv, and thickness.
	for Map in sulc@sulc@Sulc thickness@thickness@Thickness curv@curvature@Curvature ; do
		fsname=$(echo $Map | cut -d "@" -f 1)
		wbname=$(echo $Map | cut -d "@" -f 2)
		mapname=$(echo $Map | cut -d "@" -f 3)
		mris_convert -c "$FreeSurferFolder"/surf/"$hemisphere"h."$fsname" "$FreeSurferFolder"/surf/"$hemisphere"h.white ${AtlasNativeSubjHemi}."$wbname".native.shape.gii
		${CARET7DIR}/wb_command -set-structure ${AtlasNativeSubjHemi}."$wbname".native.shape.gii ${Structure}
		${CARET7DIR}/wb_command -metric-math "var * -1" ${AtlasNativeSubjHemi}."$wbname".native.shape.gii -var var ${AtlasNativeSubjHemi}."$wbname".native.shape.gii
		${CARET7DIR}/wb_command -set-map-names ${AtlasNativeSubjHemi}."$wbname".native.shape.gii -map 1 "$Subject"_"$Hemisphere"_"$mapname"
		${CARET7DIR}/wb_command -metric-palette ${AtlasNativeSubjHemi}."$wbname".native.shape.gii MODE_AUTO_SCALE_PERCENTAGE -pos-percent 2 98 -palette-name Gray_Interp -disp-pos true -disp-neg true -disp-zero true
	done
	#Thickness specific operations
	${CARET7DIR}/wb_command -metric-math "abs(thickness)" ${AtlasNativeSubjHemi}.thickness.native.shape.gii -var thickness ${AtlasNativeSubjHemi}.thickness.native.shape.gii
	${CARET7DIR}/wb_command -metric-palette ${AtlasNativeSubjHemi}.thickness.native.shape.gii MODE_AUTO_SCALE_PERCENTAGE -pos-percent 4 96 -interpolate true -palette-name videen_style -disp-pos true -disp-neg false -disp-zero false
	${CARET7DIR}/wb_command -metric-math "thickness > 0" ${AtlasNativeSubjHemi}.roi.native.shape.gii -var thickness ${AtlasNativeSubjHemi}.thickness.native.shape.gii
	${CARET7DIR}/wb_command -metric-fill-holes ${AtlasNativeSubjHemi}.midthickness.native.surf.gii ${AtlasNativeSubjHemi}.roi.native.shape.gii ${AtlasNativeSubjHemi}.roi.native.shape.gii
	${CARET7DIR}/wb_command -metric-remove-islands ${AtlasNativeSubjHemi}.midthickness.native.surf.gii ${AtlasNativeSubjHemi}.roi.native.shape.gii ${AtlasNativeSubjHemi}.roi.native.shape.gii
	${CARET7DIR}/wb_command -set-map-names ${AtlasNativeSubjHemi}.roi.native.shape.gii -map 1 ${Subject}_${Hemisphere}_ROI
	${CARET7DIR}/wb_command -metric-dilate ${AtlasNativeSubjHemi}.thickness.native.shape.gii ${AtlasNativeSubjHemi}.midthickness.native.surf.gii 10 ${AtlasNativeSubjHemi}.thickness.native.shape.gii -nearest
	${CARET7DIR}/wb_command -metric-dilate ${AtlasNativeSubjHemi}.curvature.native.shape.gii ${AtlasNativeSubjHemi}.midthickness.native.surf.gii 10 ${AtlasNativeSubjHemi}.curvature.native.shape.gii -nearest

	#Label operations
	for Map in aparc aparc.a2009s ; do #Remove BA because it doesn't convert properly
		if [ -e "$FreeSurferFolder"/label/"$hemisphere"h."$Map".annot ] ; then
			mris_convert --annot "$FreeSurferFolder"/label/"$hemisphere"h."$Map".annot "$FreeSurferFolder"/surf/"$hemisphere"h.white ${AtlasNativeSubjHemi}."$Map".native.label.gii
			${CARET7DIR}/wb_command -set-structure ${AtlasNativeSubjHemi}."$Map".native.label.gii $Structure
			${CARET7DIR}/wb_command -set-map-names ${AtlasNativeSubjHemi}."$Map".native.label.gii -map 1 "$Subject"_"$Hemisphere"_"$Map"
			${CARET7DIR}/wb_command -gifti-label-add-prefix ${AtlasNativeSubjHemi}."$Map".native.label.gii "${Hemisphere}_" ${AtlasNativeSubjHemi}."$Map".native.label.gii
		fi
	done
	### ------ END section on Native Mesh Processing ------

	### ------ BEGIN section specific to HighResMesh ------
	#Copy Atlas Files
	cp "$SurfaceAtlasDIR"/fs_"$Hemisphere"/fsaverage."$Hemisphere".sphere."$HighResMesh"k_fs_"$Hemisphere".surf.gii "$AtlasSpaceFolder"/fsaverage/"$Subject"."$Hemisphere".sphere."$HighResMesh"k_fs_"$Hemisphere".surf.gii
	cp "$SurfaceAtlasDIR"/fs_"$Hemisphere"/fs_"$Hemisphere"-to-fs_LR_fsaverage."$Hemisphere"_LR.spherical_std."$HighResMesh"k_fs_"$Hemisphere".surf.gii "$AtlasSpaceFolder"/fsaverage/"$Subject"."$Hemisphere".def_sphere."$HighResMesh"k_fs_"$Hemisphere".surf.gii
	cp "$SurfaceAtlasDIR"/fsaverage."$Hemisphere"_LR.spherical_std."$HighResMesh"k_fs_LR.surf.gii ${AtlasSubjHemi}.sphere."$HighResMesh"k_fs_LR.surf.gii
	${CARET7DIR}/wb_command -add-to-spec-file "$AtlasSpaceFolder"/"$Subject"."$HighResMesh"k_fs_LR.wb.spec $Structure ${AtlasSubjHemi}.sphere."$HighResMesh"k_fs_LR.surf.gii
	cp "$SurfaceAtlasDIR"/"$Hemisphere".atlasroi."$HighResMesh"k_fs_LR.shape.gii ${AtlasSubjHemi}.atlasroi."$HighResMesh"k_fs_LR.shape.gii
	cp "$SurfaceAtlasDIR"/"$Hemisphere".refsulc."$HighResMesh"k_fs_LR.shape.gii "$AtlasSpaceFolder"/${Subject}.${Hemisphere}.refsulc."$HighResMesh"k_fs_LR.shape.gii
	if [ -e "$SurfaceAtlasDIR"/colin.cerebral."$Hemisphere".flat."$HighResMesh"k_fs_LR.surf.gii ] ; then
		cp "$SurfaceAtlasDIR"/colin.cerebral."$Hemisphere".flat."$HighResMesh"k_fs_LR.surf.gii ${AtlasSubjHemi}.flat."$HighResMesh"k_fs_LR.surf.gii
		${CARET7DIR}/wb_command -add-to-spec-file "$AtlasSpaceFolder"/"$Subject"."$HighResMesh"k_fs_LR.wb.spec $Structure ${AtlasSubjHemi}.flat."$HighResMesh"k_fs_LR.surf.gii
	fi

	#Concatenate FS registration to FS --> FS_LR registration
	sphereIn=${AtlasNativeSubjHemi}.sphere.reg.native.surf.gii
	sphereProjectTo="$AtlasSpaceFolder"/fsaverage/"$Subject"."$Hemisphere".sphere."$HighResMesh"k_fs_"$Hemisphere".surf.gii
	sphereUnprojectFrom="$AtlasSpaceFolder"/fsaverage/"$Subject"."$Hemisphere".def_sphere."$HighResMesh"k_fs_"$Hemisphere".surf.gii
	sphereOut=${AtlasNativeSubjHemi}.sphere.reg.reg_LR.native.surf.gii
	${CARET7DIR}/wb_command -surface-sphere-project-unproject $sphereIn $sphereProjectTo $sphereUnprojectFrom $sphereOut

	#Make FreeSurfer Registration Areal Distortion Maps
	${CARET7DIR}/wb_command -surface-vertex-areas ${AtlasNativeSubjHemi}.sphere.native.surf.gii ${AtlasNativeSubjHemi}.sphere.native.shape.gii
	${CARET7DIR}/wb_command -surface-vertex-areas ${AtlasNativeSubjHemi}.sphere.reg.reg_LR.native.surf.gii ${AtlasNativeSubjHemi}.sphere.reg.reg_LR.native.shape.gii
	${CARET7DIR}/wb_command -metric-math "ln(spherereg / sphere) / ln(2)" ${AtlasNativeSubjHemi}.ArealDistortion_FS.native.shape.gii -var sphere ${AtlasNativeSubjHemi}.sphere.native.shape.gii -var spherereg ${AtlasNativeSubjHemi}.sphere.reg.reg_LR.native.shape.gii
	rm ${AtlasNativeSubjHemi}.sphere.native.shape.gii ${AtlasNativeSubjHemi}.sphere.reg.reg_LR.native.shape.gii
	${CARET7DIR}/wb_command -set-map-names ${AtlasNativeSubjHemi}.ArealDistortion_FS.native.shape.gii -map 1 ${Subject}_${Hemisphere}_Areal_Distortion_FS
	${CARET7DIR}/wb_command -metric-palette ${AtlasNativeSubjHemi}.ArealDistortion_FS.native.shape.gii MODE_AUTO_SCALE -palette-name ROY-BIG-BL -thresholding THRESHOLD_TYPE_NORMAL THRESHOLD_TEST_SHOW_OUTSIDE -1 1

	${CARET7DIR}/wb_command -surface-distortion ${AtlasNativeSubjHemi}.sphere.native.surf.gii ${AtlasNativeSubjHemi}.sphere.reg.reg_LR.native.surf.gii ${AtlasNativeSubjHemi}.EdgeDistortion_FS.native.shape.gii -edge-method

	${CARET7DIR}/wb_command -surface-distortion ${AtlasNativeSubjHemi}.sphere.native.surf.gii ${AtlasNativeSubjHemi}.sphere.reg.reg_LR.native.surf.gii ${AtlasNativeSubjHemi}.Strain_FS.native.shape.gii -local-affine-method
	${CARET7DIR}/wb_command -metric-merge ${AtlasNativeSubjHemi}.StrainJ_FS.native.shape.gii -metric ${AtlasNativeSubjHemi}.Strain_FS.native.shape.gii -column 1
	${CARET7DIR}/wb_command -metric-merge ${AtlasNativeSubjHemi}.StrainR_FS.native.shape.gii -metric ${AtlasNativeSubjHemi}.Strain_FS.native.shape.gii -column 2
	${CARET7DIR}/wb_command -metric-math "ln(var) / ln (2)" ${AtlasNativeSubjHemi}.StrainJ_FS.native.shape.gii -var var ${AtlasNativeSubjHemi}.StrainJ_FS.native.shape.gii
	${CARET7DIR}/wb_command -metric-math "ln(var) / ln (2)" ${AtlasNativeSubjHemi}.StrainR_FS.native.shape.gii -var var ${AtlasNativeSubjHemi}.StrainR_FS.native.shape.gii
	rm ${AtlasNativeSubjHemi}.Strain_FS.native.shape.gii

	#If desired, run MSMSulc folding-based registration to FS_LR initialized with FS affine
	if [ ${RegName} = "MSMSulc" ] ; then
		#Calculate Affine Transform and Apply
		if [ ! -e "$AtlasSpaceFolder"/"$NativeFolder"/MSMSulc ] ; then
			mkdir "$AtlasSpaceFolder"/"$NativeFolder"/MSMSulc
		fi
		${CARET7DIR}/wb_command -surface-affine-regression ${AtlasNativeSubjHemi}.sphere.native.surf.gii ${AtlasNativeSubjHemi}.sphere.reg.reg_LR.native.surf.gii "$AtlasSpaceFolder"/"$NativeFolder"/MSMSulc/${Hemisphere}.mat
		${CARET7DIR}/wb_command -surface-apply-affine ${AtlasNativeSubjHemi}.sphere.native.surf.gii "$AtlasSpaceFolder"/"$NativeFolder"/MSMSulc/${Hemisphere}.mat "$AtlasSpaceFolder"/"$NativeFolder"/MSMSulc/${Hemisphere}.sphere_rot.surf.gii
		${CARET7DIR}/wb_command -surface-modify-sphere "$AtlasSpaceFolder"/"$NativeFolder"/MSMSulc/${Hemisphere}.sphere_rot.surf.gii 100 "$AtlasSpaceFolder"/"$NativeFolder"/MSMSulc/${Hemisphere}.sphere_rot.surf.gii
		cp "$AtlasSpaceFolder"/"$NativeFolder"/MSMSulc/${Hemisphere}.sphere_rot.surf.gii ${AtlasNativeSubjHemi}.sphere.rot.native.surf.gii
		DIR=$(pwd)
		cd "$AtlasSpaceFolder"/"$NativeFolder"/MSMSulc
		#Register using FreeSurfer Sulc Folding Map Using MSM Algorithm Configured for Reduced Distortion
		#${MSMBINDIR}/msm --version
		#${MSMBINDIR}/msm --levels=4 --conf=${MSMCONFIGDIR}/allparameterssulcDRconf --inmesh=${AtlasNativeSubjHemi}.sphere.rot.native.surf.gii --trans=${AtlasNativeSubjHemi}.sphere.rot.native.surf.gii --refmesh=${AtlasSubjHemi}.sphere."$HighResMesh"k_fs_LR.surf.gii --indata=${AtlasNativeSubjHemi}.sulc.native.shape.gii --refdata=${AtlasSubjHemi}.refsulc."$HighResMesh"k_fs_LR.shape.gii --out="$AtlasSpaceFolder"/"$NativeFolder"/MSMSulc/${Hemisphere}. --verbose
		${MSMBINDIR}/msm --conf=${MSMCONFIGDIR}/MSMSulcStrainFinalconf --inmesh=${AtlasNativeSubjHemi}.sphere.rot.native.surf.gii --refmesh=${AtlasSubjHemi}.sphere."$HighResMesh"k_fs_LR.surf.gii --indata=${AtlasNativeSubjHemi}.sulc.native.shape.gii --refdata="$AtlasSpaceFolder"/${Subject}.${Hemisphere}.refsulc."$HighResMesh"k_fs_LR.shape.gii --out="$AtlasSpaceFolder"/"$NativeFolder"/MSMSulc/${Hemisphere}. --verbose
		cp ${MSMCONFIGDIR}/MSMSulcStrainFinalconf "$AtlasSpaceFolder"/"$NativeFolder"/MSMSulc/${Hemisphere}.logdir/conf
		cd $DIR
		#cp "$AtlasSpaceFolder"/"$NativeFolder"/MSMSulc/${Hemisphere}.HIGHRES_transformed.surf.gii ${AtlasNativeSubjHemi}.sphere.MSMSulc.native.surf.gii
		cp "$AtlasSpaceFolder"/"$NativeFolder"/MSMSulc/${Hemisphere}.sphere.reg.surf.gii ${AtlasNativeSubjHemi}.sphere.MSMSulc.native.surf.gii
		${CARET7DIR}/wb_command -set-structure "$AtlasSpaceFolder"/"$NativeFolder"/${Subject}.${Hemisphere}.sphere.MSMSulc.native.surf.gii ${Structure}

		#Make MSMSulc Registration Areal Distortion and Strain Maps
		${CARET7DIR}/wb_command -surface-vertex-areas ${AtlasNativeSubjHemi}.sphere.native.surf.gii ${AtlasNativeSubjHemi}.sphere.native.shape.gii
		${CARET7DIR}/wb_command -surface-vertex-areas ${AtlasNativeSubjHemi}.sphere.MSMSulc.native.surf.gii ${AtlasNativeSubjHemi}.sphere.MSMSulc.native.shape.gii
		${CARET7DIR}/wb_command -metric-math "ln(spherereg / sphere) / ln(2)" ${AtlasNativeSubjHemi}.ArealDistortion_MSMSulc.native.shape.gii -var sphere ${AtlasNativeSubjHemi}.sphere.native.shape.gii -var spherereg ${AtlasNativeSubjHemi}.sphere.MSMSulc.native.shape.gii
		rm ${AtlasNativeSubjHemi}.sphere.native.shape.gii ${AtlasNativeSubjHemi}.sphere.MSMSulc.native.shape.gii
		${CARET7DIR}/wb_command -set-map-names ${AtlasNativeSubjHemi}.ArealDistortion_MSMSulc.native.shape.gii -map 1 ${Subject}_${Hemisphere}_Areal_Distortion_MSMSulc
		${CARET7DIR}/wb_command -metric-palette ${AtlasNativeSubjHemi}.ArealDistortion_MSMSulc.native.shape.gii MODE_AUTO_SCALE -palette-name ROY-BIG-BL -thresholding THRESHOLD_TYPE_NORMAL THRESHOLD_TEST_SHOW_OUTSIDE -1 1

		${CARET7DIR}/wb_command -surface-distortion ${AtlasNativeSubjHemi}.sphere.native.surf.gii ${AtlasNativeSubjHemi}.sphere.MSMSulc.native.surf.gii ${AtlasNativeSubjHemi}.EdgeDistortion_MSMSulc.native.shape.gii -edge-method

		${CARET7DIR}/wb_command -surface-distortion ${AtlasNativeSubjHemi}.sphere.native.surf.gii ${AtlasNativeSubjHemi}.sphere.MSMSulc.native.surf.gii ${AtlasNativeSubjHemi}.Strain_MSMSulc.native.shape.gii -local-affine-method
		${CARET7DIR}/wb_command -metric-merge ${AtlasNativeSubjHemi}.StrainJ_MSMSulc.native.shape.gii -metric ${AtlasNativeSubjHemi}.Strain_MSMSulc.native.shape.gii -column 1
		${CARET7DIR}/wb_command -metric-merge ${AtlasNativeSubjHemi}.StrainR_MSMSulc.native.shape.gii -metric ${AtlasNativeSubjHemi}.Strain_MSMSulc.native.shape.gii -column 2
		${CARET7DIR}/wb_command -metric-math "ln(var) / ln (2)" ${AtlasNativeSubjHemi}.StrainJ_MSMSulc.native.shape.gii -var var ${AtlasNativeSubjHemi}.StrainJ_MSMSulc.native.shape.gii
		${CARET7DIR}/wb_command -metric-math "ln(var) / ln (2)" ${AtlasNativeSubjHemi}.StrainR_MSMSulc.native.shape.gii -var var ${AtlasNativeSubjHemi}.StrainR_MSMSulc.native.shape.gii
		rm ${AtlasNativeSubjHemi}.Strain_MSMSulc.native.shape.gii

		RegSphere=${AtlasNativeSubjHemi}.sphere.MSMSulc.native.surf.gii
	else  # Not using MSMSulc
		RegSphere=${AtlasNativeSubjHemi}.sphere.reg.reg_LR.native.surf.gii
	fi	## if [ ${RegName} = "MSMSulc" ] ; then

	#Ensure no zeros in atlas medial wall ROI
	${CARET7DIR}/wb_command -metric-resample ${AtlasSubjHemi}.atlasroi."$HighResMesh"k_fs_LR.shape.gii ${AtlasSubjHemi}.sphere."$HighResMesh"k_fs_LR.surf.gii ${RegSphere} BARYCENTRIC ${AtlasNativeSubjHemi}.atlasroi.native.shape.gii -largest
	${CARET7DIR}/wb_command -metric-math "(atlas + individual) > 0" ${AtlasNativeSubjHemi}.roi.native.shape.gii -var atlas ${AtlasNativeSubjHemi}.atlasroi.native.shape.gii -var individual ${AtlasNativeSubjHemi}.roi.native.shape.gii
	${CARET7DIR}/wb_command -metric-mask ${AtlasNativeSubjHemi}.thickness.native.shape.gii ${AtlasNativeSubjHemi}.roi.native.shape.gii ${AtlasNativeSubjHemi}.thickness.native.shape.gii
	${CARET7DIR}/wb_command -metric-mask ${AtlasNativeSubjHemi}.curvature.native.shape.gii ${AtlasNativeSubjHemi}.roi.native.shape.gii ${AtlasNativeSubjHemi}.curvature.native.shape.gii

	#Populate Highres fs_LR spec file.  Deform surfaces and other data according to native to folding-based registration selected above.  Regenerate inflated surfaces.
	for Surface in white midthickness pial ; do
		${CARET7DIR}/wb_command -surface-resample ${AtlasNativeSubjHemi}."$Surface".native.surf.gii ${RegSphere} ${AtlasSubjHemi}.sphere."$HighResMesh"k_fs_LR.surf.gii BARYCENTRIC ${AtlasSubjHemi}."$Surface"."$HighResMesh"k_fs_LR.surf.gii
		${CARET7DIR}/wb_command -add-to-spec-file "$AtlasSpaceFolder"/"$Subject"."$HighResMesh"k_fs_LR.wb.spec $Structure ${AtlasSubjHemi}."$Surface"."$HighResMesh"k_fs_LR.surf.gii
	done
	
	#HCP fsaverage_LR32k used -iterations-scale 0.75. Compute new param value for high res mesh density
	HighResInflationScale=$(echo "scale=4; $InflateExtraScale * 0.75 * $HighResMesh / 32" | bc -l)

	${CARET7DIR}/wb_command -surface-generate-inflated ${AtlasSubjHemi}.midthickness."$HighResMesh"k_fs_LR.surf.gii ${AtlasSubjHemi}.inflated."$HighResMesh"k_fs_LR.surf.gii ${AtlasSubjHemi}.very_inflated."$HighResMesh"k_fs_LR.surf.gii -iterations-scale $HighResInflationScale
	${CARET7DIR}/wb_command -add-to-spec-file "$AtlasSpaceFolder"/"$Subject"."$HighResMesh"k_fs_LR.wb.spec $Structure ${AtlasSubjHemi}.inflated."$HighResMesh"k_fs_LR.surf.gii
	${CARET7DIR}/wb_command -add-to-spec-file "$AtlasSpaceFolder"/"$Subject"."$HighResMesh"k_fs_LR.wb.spec $Structure ${AtlasSubjHemi}.very_inflated."$HighResMesh"k_fs_LR.surf.gii

	for Map in thickness curvature ; do
		${CARET7DIR}/wb_command -metric-resample ${AtlasNativeSubjHemi}."$Map".native.shape.gii ${RegSphere} ${AtlasSubjHemi}.sphere."$HighResMesh"k_fs_LR.surf.gii ADAP_BARY_AREA ${AtlasSubjHemi}."$Map"."$HighResMesh"k_fs_LR.shape.gii -area-surfs ${T1wNativeSubjHemi}.midthickness.native.surf.gii ${AtlasSubjHemi}.midthickness."$HighResMesh"k_fs_LR.surf.gii -current-roi ${AtlasNativeSubjHemi}.roi.native.shape.gii
		${CARET7DIR}/wb_command -metric-mask ${AtlasSubjHemi}."$Map"."$HighResMesh"k_fs_LR.shape.gii ${AtlasSubjHemi}.atlasroi."$HighResMesh"k_fs_LR.shape.gii ${AtlasSubjHemi}."$Map"."$HighResMesh"k_fs_LR.shape.gii
	done

	#MPH: Why can't the following resample of 'sulc' be part of the 'for' loop above (same as below where "sulc curvative thickness" are in a common 'for' loop)?
	${CARET7DIR}/wb_command -metric-resample ${AtlasNativeSubjHemi}.sulc.native.shape.gii ${RegSphere} ${AtlasSubjHemi}.sphere."$HighResMesh"k_fs_LR.surf.gii ADAP_BARY_AREA ${AtlasSubjHemi}.sulc."$HighResMesh"k_fs_LR.shape.gii -area-surfs ${T1wNativeSubjHemi}.midthickness.native.surf.gii ${AtlasSubjHemi}.midthickness."$HighResMesh"k_fs_LR.surf.gii

	# Add distortion/strain maps
	for Map in ArealDistortion EdgeDistortion StrainJ StrainR ; do
		${CARET7DIR}/wb_command -metric-resample ${AtlasNativeSubjHemi}."$Map"_FS.native.shape.gii ${RegSphere} ${AtlasSubjHemi}.sphere."$HighResMesh"k_fs_LR.surf.gii ADAP_BARY_AREA ${AtlasSubjHemi}."$Map"_FS."$HighResMesh"k_fs_LR.shape.gii -area-surfs ${T1wNativeSubjHemi}.midthickness.native.surf.gii ${AtlasSubjHemi}.midthickness."$HighResMesh"k_fs_LR.surf.gii
		if [ ${RegName} = "MSMSulc" ] ; then
			${CARET7DIR}/wb_command -metric-resample ${AtlasNativeSubjHemi}."$Map"_MSMSulc.native.shape.gii ${RegSphere} ${AtlasSubjHemi}.sphere."$HighResMesh"k_fs_LR.surf.gii ADAP_BARY_AREA ${AtlasSubjHemi}."$Map"_MSMSulc."$HighResMesh"k_fs_LR.shape.gii -area-surfs ${T1wNativeSubjHemi}.midthickness.native.surf.gii ${AtlasSubjHemi}.midthickness."$HighResMesh"k_fs_LR.surf.gii
		fi
	done

	# FS anatomical labels
	for Map in aparc aparc.a2009s ; do #Remove BA because it doesn't convert properly
		if [ -e "$FreeSurferFolder"/label/"$hemisphere"h."$Map".annot ] ; then
			${CARET7DIR}/wb_command -label-resample ${AtlasNativeSubjHemi}."$Map".native.label.gii ${RegSphere} ${AtlasSubjHemi}.sphere."$HighResMesh"k_fs_LR.surf.gii BARYCENTRIC ${AtlasSubjHemi}."$Map"."$HighResMesh"k_fs_LR.label.gii -largest
		fi
	done
	### ------ END section specific to HighResMesh ------

	### ------ BEGIN section specific to LowResMeshes ------
	for LowResMesh in ${LowResMeshes} ; do

		# Set up some variables for common strings
		AtlasFSLRSubj="$AtlasSpaceFolder"/fsaverage_LR"$LowResMesh"k/"$Subject"
		AtlasFSLRSubjHemi="$AtlasSpaceFolder"/fsaverage_LR"$LowResMesh"k/"$Subject"."$Hemisphere"
		T1wFSLRSubj="$T1wFolder"/fsaverage_LR"$LowResMesh"k/"$Subject"
		T1wFSLRSubjHemi="$T1wFolder"/fsaverage_LR"$LowResMesh"k/"$Subject"."$Hemisphere"
		
		#Copy Atlas Files
		cp "$SurfaceAtlasDIR"/"$Hemisphere".sphere."$LowResMesh"k_fs_LR.surf.gii ${AtlasFSLRSubjHemi}.sphere."$LowResMesh"k_fs_LR.surf.gii
		${CARET7DIR}/wb_command -add-to-spec-file ${AtlasFSLRSubj}."$LowResMesh"k_fs_LR.wb.spec $Structure ${AtlasFSLRSubjHemi}.sphere."$LowResMesh"k_fs_LR.surf.gii
		cp "$GrayordinatesSpaceDIR"/"$Hemisphere".atlasroi."$LowResMesh"k_fs_LR.shape.gii ${AtlasFSLRSubjHemi}.atlasroi."$LowResMesh"k_fs_LR.shape.gii
		if [ -e "$SurfaceAtlasDIR"/colin.cerebral."$Hemisphere".flat."$LowResMesh"k_fs_LR.surf.gii ] ; then
			cp "$SurfaceAtlasDIR"/colin.cerebral."$Hemisphere".flat."$LowResMesh"k_fs_LR.surf.gii ${AtlasFSLRSubjHemi}.flat."$LowResMesh"k_fs_LR.surf.gii
			${CARET7DIR}/wb_command -add-to-spec-file ${AtlasFSLRSubj}."$LowResMesh"k_fs_LR.wb.spec $Structure ${AtlasFSLRSubjHemi}.flat."$LowResMesh"k_fs_LR.surf.gii
		fi

		#Create downsampled fs_LR spec files.
		for Surface in white midthickness pial ; do
			${CARET7DIR}/wb_command -surface-resample ${AtlasNativeSubjHemi}."$Surface".native.surf.gii ${RegSphere} ${AtlasFSLRSubjHemi}.sphere."$LowResMesh"k_fs_LR.surf.gii BARYCENTRIC ${AtlasFSLRSubjHemi}."$Surface"."$LowResMesh"k_fs_LR.surf.gii
			${CARET7DIR}/wb_command -add-to-spec-file ${AtlasFSLRSubj}."$LowResMesh"k_fs_LR.wb.spec $Structure ${AtlasFSLRSubjHemi}."$Surface"."$LowResMesh"k_fs_LR.surf.gii
		done

		#HCP fsaverage_LR32k used -iterations-scale 0.75. Recalculate in case using a different mesh
		LowResInflationScale=$(echo "scale=4; $InflateExtraScale * 0.75 * $LowResMesh / 32" | bc -l)

		${CARET7DIR}/wb_command -surface-generate-inflated ${AtlasFSLRSubjHemi}.midthickness."$LowResMesh"k_fs_LR.surf.gii ${AtlasFSLRSubjHemi}.inflated."$LowResMesh"k_fs_LR.surf.gii ${AtlasFSLRSubjHemi}.very_inflated."$LowResMesh"k_fs_LR.surf.gii -iterations-scale "$LowResInflationScale"
		${CARET7DIR}/wb_command -add-to-spec-file ${AtlasFSLRSubj}."$LowResMesh"k_fs_LR.wb.spec $Structure ${AtlasFSLRSubjHemi}.inflated."$LowResMesh"k_fs_LR.surf.gii
		${CARET7DIR}/wb_command -add-to-spec-file ${AtlasFSLRSubj}."$LowResMesh"k_fs_LR.wb.spec $Structure ${AtlasFSLRSubjHemi}.very_inflated."$LowResMesh"k_fs_LR.surf.gii

		for Map in sulc thickness curvature ; do
			${CARET7DIR}/wb_command -metric-resample ${AtlasNativeSubjHemi}."$Map".native.shape.gii ${RegSphere} ${AtlasFSLRSubjHemi}.sphere."$LowResMesh"k_fs_LR.surf.gii ADAP_BARY_AREA ${AtlasFSLRSubjHemi}."$Map"."$LowResMesh"k_fs_LR.shape.gii -area-surfs ${T1wNativeSubjHemi}.midthickness.native.surf.gii ${AtlasFSLRSubjHemi}.midthickness."$LowResMesh"k_fs_LR.surf.gii -current-roi ${AtlasNativeSubjHemi}.roi.native.shape.gii
			${CARET7DIR}/wb_command -metric-mask ${AtlasFSLRSubjHemi}."$Map"."$LowResMesh"k_fs_LR.shape.gii ${AtlasFSLRSubjHemi}.atlasroi."$LowResMesh"k_fs_LR.shape.gii ${AtlasFSLRSubjHemi}."$Map"."$LowResMesh"k_fs_LR.shape.gii
		done

		#MPH: Why is this following resample here, when already part of the preceding 'for' loop?  (Should it not be in the above loop?)
		${CARET7DIR}/wb_command -metric-resample ${AtlasNativeSubjHemi}.sulc.native.shape.gii ${RegSphere} ${AtlasFSLRSubjHemi}.sphere."$LowResMesh"k_fs_LR.surf.gii ADAP_BARY_AREA ${AtlasFSLRSubjHemi}.sulc."$LowResMesh"k_fs_LR.shape.gii -area-surfs ${T1wNativeSubjHemi}.midthickness.native.surf.gii ${AtlasFSLRSubjHemi}.midthickness."$LowResMesh"k_fs_LR.surf.gii

		# Add distortion/strain maps
		for Map in ArealDistortion EdgeDistortion StrainJ StrainR ; do
			${CARET7DIR}/wb_command -metric-resample ${AtlasNativeSubjHemi}."$Map"_FS.native.shape.gii ${RegSphere} ${AtlasFSLRSubjHemi}.sphere."$LowResMesh"k_fs_LR.surf.gii ADAP_BARY_AREA ${AtlasFSLRSubjHemi}."$Map"_FS."$LowResMesh"k_fs_LR.shape.gii -area-surfs ${T1wNativeSubjHemi}.midthickness.native.surf.gii ${AtlasFSLRSubjHemi}.midthickness."$LowResMesh"k_fs_LR.surf.gii
			if [ ${RegName} = "MSMSulc" ] ; then
				${CARET7DIR}/wb_command -metric-resample ${AtlasNativeSubjHemi}."$Map"_MSMSulc.native.shape.gii ${RegSphere} ${AtlasFSLRSubjHemi}.sphere."$LowResMesh"k_fs_LR.surf.gii ADAP_BARY_AREA ${AtlasFSLRSubjHemi}."$Map"_MSMSulc."$LowResMesh"k_fs_LR.shape.gii -area-surfs ${T1wNativeSubjHemi}.midthickness.native.surf.gii ${AtlasFSLRSubjHemi}.midthickness."$LowResMesh"k_fs_LR.surf.gii
			fi
		done
	
		# FS anatomical labels
		for Map in aparc aparc.a2009s ; do #Remove BA because it doesn't convert properly
			if [ -e "$FreeSurferFolder"/label/"$hemisphere"h."$Map".annot ] ; then
				${CARET7DIR}/wb_command -label-resample ${AtlasNativeSubjHemi}."$Map".native.label.gii ${RegSphere} ${AtlasFSLRSubjHemi}.sphere."$LowResMesh"k_fs_LR.surf.gii BARYCENTRIC ${AtlasFSLRSubjHemi}."$Map"."$LowResMesh"k_fs_LR.label.gii -largest
			fi
		done

		#Create downsampled fs_LR spec file in structural space.
		for Surface in white midthickness pial ; do
			${CARET7DIR}/wb_command -surface-resample ${T1wNativeSubjHemi}."$Surface".native.surf.gii ${RegSphere} ${AtlasFSLRSubjHemi}.sphere."$LowResMesh"k_fs_LR.surf.gii BARYCENTRIC ${T1wFSLRSubjHemi}."$Surface"."$LowResMesh"k_fs_LR.surf.gii
			${CARET7DIR}/wb_command -add-to-spec-file ${T1wFSLRSubj}."$LowResMesh"k_fs_LR.wb.spec $Structure ${T1wFSLRSubjHemi}."$Surface"."$LowResMesh"k_fs_LR.surf.gii
		done

		#HCP fsaverage_LR32k used -iterations-scale 0.75. Recalculate in case using a different mesh
		LowResInflationScale=$(echo "scale=4; $InflateExtraScale * 0.75 * $LowResMesh / 32" | bc -l)

		${CARET7DIR}/wb_command -surface-generate-inflated ${T1wFSLRSubjHemi}.midthickness."$LowResMesh"k_fs_LR.surf.gii ${T1wFSLRSubjHemi}.inflated."$LowResMesh"k_fs_LR.surf.gii ${T1wFSLRSubjHemi}.very_inflated."$LowResMesh"k_fs_LR.surf.gii -iterations-scale "$LowResInflationScale"
		${CARET7DIR}/wb_command -add-to-spec-file ${T1wFSLRSubj}."$LowResMesh"k_fs_LR.wb.spec $Structure ${T1wFSLRSubjHemi}.inflated."$LowResMesh"k_fs_LR.surf.gii
		${CARET7DIR}/wb_command -add-to-spec-file ${T1wFSLRSubj}."$LowResMesh"k_fs_LR.wb.spec $Structure ${T1wFSLRSubjHemi}.very_inflated."$LowResMesh"k_fs_LR.surf.gii
		### ------ END section specific to LowResMeshes ------
		
	done ## for LowResMesh in ${LowResMeshes} ; do
	
done ## for Hemisphere in L R ; do

### ------ BEGIN section on creating CIFTI files ------
STRINGII=""
for LowResMesh in ${LowResMeshes} ; do
	STRINGII=$(echo "${STRINGII}${AtlasSpaceFolder}/fsaverage_LR${LowResMesh}k@${LowResMesh}k_fs_LR@atlasroi ")
done

for STRING in "$AtlasSpaceFolder"/"$NativeFolder"@native@roi "$AtlasSpaceFolder"@"$HighResMesh"k_fs_LR@atlasroi ${STRINGII} ; do
	Folder=$(echo $STRING | cut -d "@" -f 1)
	Mesh=$(echo $STRING | cut -d "@" -f 2)
	ROI=$(echo $STRING | cut -d "@" -f 3)

	FolderSubj="$Folder"/"$Subject"
	
	${CARET7DIR}/wb_command -cifti-create-dense-scalar ${FolderSubj}.sulc."$Mesh".dscalar.nii -left-metric ${FolderSubj}.L.sulc."$Mesh".shape.gii -right-metric ${FolderSubj}.R.sulc."$Mesh".shape.gii
	${CARET7DIR}/wb_command -set-map-names ${FolderSubj}.sulc."$Mesh".dscalar.nii -map 1 "${Subject}_Sulc"
	${CARET7DIR}/wb_command -cifti-palette ${FolderSubj}.sulc."$Mesh".dscalar.nii MODE_AUTO_SCALE_PERCENTAGE ${FolderSubj}.sulc."$Mesh".dscalar.nii -pos-percent 2 98 -palette-name Gray_Interp -disp-pos true -disp-neg true -disp-zero true

	${CARET7DIR}/wb_command -cifti-create-dense-scalar ${FolderSubj}.curvature."$Mesh".dscalar.nii -left-metric ${FolderSubj}.L.curvature."$Mesh".shape.gii -roi-left ${FolderSubj}.L."$ROI"."$Mesh".shape.gii -right-metric ${FolderSubj}.R.curvature."$Mesh".shape.gii -roi-right ${FolderSubj}.R."$ROI"."$Mesh".shape.gii
	${CARET7DIR}/wb_command -set-map-names ${FolderSubj}.curvature."$Mesh".dscalar.nii -map 1 "${Subject}_Curvature"
	${CARET7DIR}/wb_command -cifti-palette ${FolderSubj}.curvature."$Mesh".dscalar.nii MODE_AUTO_SCALE_PERCENTAGE ${FolderSubj}.curvature."$Mesh".dscalar.nii -pos-percent 2 98 -palette-name Gray_Interp -disp-pos true -disp-neg true -disp-zero true

	${CARET7DIR}/wb_command -cifti-create-dense-scalar ${FolderSubj}.thickness."$Mesh".dscalar.nii -left-metric ${FolderSubj}.L.thickness."$Mesh".shape.gii -roi-left ${FolderSubj}.L."$ROI"."$Mesh".shape.gii -right-metric ${FolderSubj}.R.thickness."$Mesh".shape.gii -roi-right ${FolderSubj}.R."$ROI"."$Mesh".shape.gii
	${CARET7DIR}/wb_command -set-map-names ${FolderSubj}.thickness."$Mesh".dscalar.nii -map 1 "${Subject}_Thickness"
	${CARET7DIR}/wb_command -cifti-palette ${FolderSubj}.thickness."$Mesh".dscalar.nii MODE_AUTO_SCALE_PERCENTAGE ${FolderSubj}.thickness."$Mesh".dscalar.nii -pos-percent 4 96 -interpolate true -palette-name videen_style -disp-pos true -disp-neg false -disp-zero false

	for Map in ArealDistortion EdgeDistortion StrainJ StrainR ; do
		${CARET7DIR}/wb_command -cifti-create-dense-scalar ${FolderSubj}."$Map"_FS."$Mesh".dscalar.nii -left-metric ${FolderSubj}.L."$Map"_FS."$Mesh".shape.gii -right-metric ${FolderSubj}.R."$Map"_FS."$Mesh".shape.gii
		${CARET7DIR}/wb_command -set-map-names ${FolderSubj}."$Map"_FS."$Mesh".dscalar.nii -map 1 "${Subject}_${Map}_FS"
		${CARET7DIR}/wb_command -cifti-palette ${FolderSubj}."$Map"_FS."$Mesh".dscalar.nii MODE_USER_SCALE ${FolderSubj}."$Map"_FS."$Mesh".dscalar.nii -pos-user 0 1 -neg-user 0 -1 -interpolate true -palette-name ROY-BIG-BL -disp-pos true -disp-neg true -disp-zero false

		if [ ${RegName} = "MSMSulc" ] ; then
			${CARET7DIR}/wb_command -cifti-create-dense-scalar ${FolderSubj}."$Map"_MSMSulc."$Mesh".dscalar.nii -left-metric ${FolderSubj}.L."$Map"_MSMSulc."$Mesh".shape.gii -right-metric ${FolderSubj}.R.ArealDistortion_MSMSulc."$Mesh".shape.gii
			${CARET7DIR}/wb_command -set-map-names ${FolderSubj}."$Map"_MSMSulc."$Mesh".dscalar.nii -map 1 "${Subject}_${Map}_MSMSulc"
			${CARET7DIR}/wb_command -cifti-palette ${FolderSubj}."$Map"_MSMSulc."$Mesh".dscalar.nii MODE_USER_SCALE ${FolderSubj}."$Map"_MSMSulc."$Mesh".dscalar.nii -pos-user 0 1 -neg-user 0 -1 -interpolate true -palette-name ROY-BIG-BL -disp-pos true -disp-neg true -disp-zero false
		fi
	done

	for Map in aparc aparc.a2009s ; do #Remove BA because it doesn't convert properly
		if [ -e ${FolderSubj}.L.${Map}."$Mesh".label.gii ] ; then
			${CARET7DIR}/wb_command -cifti-create-label ${FolderSubj}.${Map}."$Mesh".dlabel.nii -left-label ${FolderSubj}.L.${Map}."$Mesh".label.gii -roi-left ${FolderSubj}.L."$ROI"."$Mesh".shape.gii -right-label ${FolderSubj}.R.${Map}."$Mesh".label.gii -roi-right ${FolderSubj}.R."$ROI"."$Mesh".shape.gii
			${CARET7DIR}/wb_command -set-map-names ${FolderSubj}.${Map}."$Mesh".dlabel.nii -map 1 "$Subject"_${Map}
		fi
	done
done

STRINGII=""
for LowResMesh in ${LowResMeshes} ; do
	STRINGII=$(echo "${STRINGII}${AtlasSpaceFolder}/fsaverage_LR${LowResMesh}k@${AtlasSpaceFolder}/fsaverage_LR${LowResMesh}k@${LowResMesh}k_fs_LR ${T1wFolder}/fsaverage_LR${LowResMesh}k@${AtlasSpaceFolder}/fsaverage_LR${LowResMesh}k@${LowResMesh}k_fs_LR ")
done

#Add CIFTI Maps to Spec Files
for STRING in "$T1wFolder"/"$NativeFolder"@"$AtlasSpaceFolder"/"$NativeFolder"@native "$AtlasSpaceFolder"/"$NativeFolder"@"$AtlasSpaceFolder"/"$NativeFolder"@native "$AtlasSpaceFolder"@"$AtlasSpaceFolder"@"$HighResMesh"k_fs_LR ${STRINGII} ; do
	FolderI=$(echo $STRING | cut -d "@" -f 1)
	FolderII=$(echo $STRING | cut -d "@" -f 2)
	Mesh=$(echo $STRING | cut -d "@" -f 3)
	for STRINGII in sulc@dscalar thickness@dscalar curvature@dscalar aparc@dlabel aparc.a2009s@dlabel ; do #Remove BA@dlabel because it doesn't convert properly
		Map=$(echo $STRINGII | cut -d "@" -f 1)
		Ext=$(echo $STRINGII | cut -d "@" -f 2)
		if [ -e "$FolderII"/"$Subject"."$Map"."$Mesh"."$Ext".nii ] ; then
			${CARET7DIR}/wb_command -add-to-spec-file "$FolderI"/"$Subject"."$Mesh".wb.spec INVALID "$FolderII"/"$Subject"."$Map"."$Mesh"."$Ext".nii
		fi
	done
done
### ------ END section on creating CIFTI files ------

# Create midthickness Vertex Area (VA) maps
log_Msg "Create midthickness Vertex Area (VA) maps"

for LowResMesh in ${LowResMeshes} ; do

	log_Msg "Creating midthickness Vertex Area (VA) maps for LowResMesh: ${LowResMesh}"

	# DownSampleT1wFolder             - path to folder containing downsampled T1w files
	# midthickness_va_file            - path to non-normalized midthickness vertex area file
	# normalized_midthickness_va_file - path ot normalized midthickness vertex area file
	# surface_to_measure              - path to surface file on which to measure surface areas
	# output_metric                   - path to metric file generated by -surface-vertex-areas subcommand

	DownSampleT1wFolder=${T1wFolder}/fsaverage_LR${LowResMesh}k
	DownSampleFolder=${AtlasSpaceFolder}/fsaverage_LR${LowResMesh}k
	midthickness_va_file=${DownSampleT1wFolder}/${Subject}.midthickness_va.${LowResMesh}k_fs_LR.dscalar.nii
	normalized_midthickness_va_file=${DownSampleT1wFolder}/${Subject}.midthickness_va_norm.${LowResMesh}k_fs_LR.dscalar.nii

	for Hemisphere in L R ; do
		surface_to_measure=${DownSampleT1wFolder}/${Subject}.${Hemisphere}.midthickness.${LowResMesh}k_fs_LR.surf.gii
		output_metric=${DownSampleT1wFolder}/${Subject}.${Hemisphere}.midthickness_va.${LowResMesh}k_fs_LR.shape.gii
		${CARET7DIR}/wb_command -surface-vertex-areas ${surface_to_measure} ${output_metric}
	done

	# left_metric  - path to left hemisphere VA metric file
	# roi_left     - path to file of ROI vertices to use from left surface
	# right_metric - path to right hemisphere VA metric file
	# roi_right    - path to file of ROI vertices to use from right surface

	left_metric=${DownSampleT1wFolder}/${Subject}.L.midthickness_va.${LowResMesh}k_fs_LR.shape.gii
	roi_left=${DownSampleFolder}/${Subject}.L.atlasroi.${LowResMesh}k_fs_LR.shape.gii
	right_metric=${DownSampleT1wFolder}/${Subject}.R.midthickness_va.${LowResMesh}k_fs_LR.shape.gii
	roi_right=${DownSampleFolder}/${Subject}.R.atlasroi.${LowResMesh}k_fs_LR.shape.gii

	${CARET7DIR}/wb_command -cifti-create-dense-scalar ${midthickness_va_file} \
				-left-metric  ${left_metric} \
				-roi-left     ${roi_left} \
				-right-metric ${right_metric} \
				-roi-right    ${roi_right}

	# VAMean - mean of surface area accounted for for each vertex - used for normalization
	VAMean=$(${CARET7DIR}/wb_command -cifti-stats ${midthickness_va_file} -reduce MEAN)
	log_Msg "VAMean: ${VAMean}"

	${CARET7DIR}/wb_command -cifti-math "VA / ${VAMean}" ${normalized_midthickness_va_file} -var VA ${midthickness_va_file}

	log_Msg "Done creating midthickness Vertex Area (VA) maps for LowResMesh: ${LowResMesh}"

done

log_Msg "Done creating midthickness Vertex Area (VA) maps"

log_Msg "END"


