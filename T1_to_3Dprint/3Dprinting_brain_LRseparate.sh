#!/bin/bash
#3dprintyourbrain

# >>> PREREQUISITES:
#     Install FreeSurfer (v6.0.0), FSL, pymeshlab on Linux. 
# 
# >>> FOLDER STRUCTURE:
#		T1_to_3Dprint
#		--3Dprinting_brain.sh
#		--combine_mesh.py
#               --pymesh_smoothing.py
#               --scale_mesh.py
#		--sub-01 (or other folder name containing the T1 image)
#		  --input
#		    --struct.nii or struct.nii.gz
#
#     -> The final smoothed full brain .stl file = output/final_3Dbrain_smooth.stl
#                                  
# >>> INSTRUCTIONS:
#     * Create the folder structure so that you have: 
#       - a subject folder (e.g., sub-01) within the main folder (i.e., 3Dprintyourbrain) containing
#           - this script 3Dprinting_brain.sh
#           - the python pymeshlab scripts combine_mesh.py, smooth_mesh.py, scale_mesh.py
#           - subfolder input containing struct.nii or struct.nii.gz which is a T1 MPRAGE NifTI file.
#
#     * Type in the command terminal, WITHIN the directory where this script resides:
#       ./3Dprinting_brain.sh  $MAIN_DIR $subject
#       Two arguments: 
#                  1. $MAIN_DIR to the correct 3dbrain directory, e.g. "/media/josh/my_brains/3Dprint_brain/T1_to_3Dprint"
#                  2. $subject to the correct subject folder name, e.g., "sub-01"
#       => example: ./3Dprinting_brain.sh "/mnt/c/Users/Josh/Documents/Research/MRI/3Dprint_brain/T1_to_3Dprint" "Josh"


# REMARK: Adapted from https://github.com/miykael/3dprintyourbrain
#         Originally developped at BrainHackGhent2018 (https://brainhackghent.github.io/#3Dprint),
#         by Sofie Van Den Bossche, James Deraeve, Thibault Sanders and Robin De Pauw.



#==========================================================================================
# 0. Setup parameters
#==========================================================================================
#Specify if you want to run even if file already exists
export force_run=(0) #0 = dont run if file already exists, 1 = force all except recon-all (freesurfer)
export force_recon=(0) #0 = dont run if file recon already computed, 1 = force to run recon-all

# Specify if only cortex or including subcortical structures (subcortical structures include brainstem, cerebellum etc.)
export structure=(1) # 1 = only cortex, 2 = cortex + subcortical structures

# Specify the desired length of 3D brain (length = distance along saggital axis)
export scale=(1) #if 0 -> no scaling; if 1 -> scaling to specified length
export length=(100) # define in mm



#==========================================================================================
# 1. Specify variables
#==========================================================================================

# Main folder for the whole project
export MAIN_DIR=$1

# Name of the subject
export subject=$2

# Path to the structural image (input folder)
cd $MAIN_DIR/${subject}/input/
if [ -z "$(find . -maxdepth 1 -name '*struct.nii.gz*')" ]; then
    gzip struct.nii
fi
export subjT1=$MAIN_DIR/${subject}/input/struct.nii.gz

# Path to the subject (output folder)
export SUBJECTS_DIR=$MAIN_DIR/${subject}/output


#==========================================================================================
#2. Create Surface Model with FreeSurfer
#==========================================================================================

if [ ! -f $SUBJECTS_DIR/surf/lh.pial ] ||  [ ! -f $SUBJECTS_DIR/surf/rh.pial ] || [ $force_recon -eq 1 ]; then

	mkdir -p $SUBJECTS_DIR/mri/orig
	mri_convert ${subjT1} $SUBJECTS_DIR/mri/orig/001.mgz
	recon-all -subjid "output" -all -time -log logfile -nuintensitycor-3T -sd "$MAIN_DIR/${subject}/" -parallel
fi

#==========================================================================================
#3. Create 3D Model of Cortical (LEFT and RIGHT separate) and Subcortical Areas
#==========================================================================================

# CORTICAL
# Convert output of step (2) to stl-format SEPERATE FOR LEFT AND RIGHT

# LEFT
if [ ! -f $SUBJECTS_DIR/cortical_LEFT.stl ] || [ $force_run -eq 1 ]; then

	mris_convert $SUBJECTS_DIR/surf/lh.pial $SUBJECTS_DIR/cortical_LEFT.stl
fi

# RIGHT
if [ ! -f $SUBJECTS_DIR/cortical_RIGHT.stl ] || [ $force_run -eq 1 ]; then

	mris_convert $SUBJECTS_DIR/surf/rh.pial $SUBJECTS_DIR/cortical_RIGHT.stl
fi



# SUBCORTICAL
if [ ! -f $SUBJECTS_DIR/subcortical.stl ] || [ $force_run -eq 1 ]; then

	mkdir -p $SUBJECTS_DIR/subcortical
	# First, convert aseg.mgz into NIfTI format
	mri_convert $SUBJECTS_DIR/mri/aseg.mgz $SUBJECTS_DIR/subcortical/subcortical.nii

	# Second, binarize all areas that you're not interested and inverse the binarization
	if [ $structure -eq 1 ];then

		# only corpus callosum (otherwise hemispheres are not attached)		 
		mri_binarize --i $SUBJECTS_DIR/subcortical/subcortical.nii \
					 --match 7 8 16 28 46 47 60 2 3 24 31 41 42 63 72 77 51 52 13 12 43 50 4 11 26 58 49 10 17 18 53 54 44 5 80 14 15 30 62 \
					 --inv \
					 --o $SUBJECTS_DIR/subcortical/bin.nii
					 
	elif [ $structure -eq 2 ];then

		# all subcortical structures
		mri_binarize --i $SUBJECTS_DIR/subcortical/subcortical.nii \
					 --match 2 3 24 31 41 42 63 72 77 51 52 13 12 43 50 4 11 26 58 49 10 17 18 53 54 44 5 80 14 15 30 62 \
					 --inv \
					 --o $SUBJECTS_DIR/subcortical/bin.nii
				 
	fi			 
				 
	# Third, multiply the original aseg.mgz file with the binarized files
	fslmaths $SUBJECTS_DIR/subcortical/subcortical.nii \
			 -mul $SUBJECTS_DIR/subcortical/bin.nii \
			 $SUBJECTS_DIR/subcortical/subcortical.nii.gz

	# Fourth, copy original file to create a temporary file
	cp $SUBJECTS_DIR/subcortical/subcortical.nii.gz $SUBJECTS_DIR/subcortical/subcortical_tmp.nii.gz

	# Fifth, unzip this file
	gunzip -f $SUBJECTS_DIR/subcortical/subcortical_tmp.nii.gz

	# Sixth, check all areas of interest for wholes and fill them out if necessary
	# only corpus callosum
	if [ $structure -eq 1 ];then			 
		for i in 251 252 253 254 255
		do
			mri_pretess $SUBJECTS_DIR/subcortical/subcortical_tmp.nii \
			$i \
			$SUBJECTS_DIR/mri/norm.mgz \
			$SUBJECTS_DIR/subcortical/subcortical_tmp.nii
		done
	# all subcortical structures
	elif [ $structure -eq 2 ];then
		for i in 7 8 16 28 46 47 60 251 252 253 254 255
		do
			mri_pretess $SUBJECTS_DIR/subcortical/subcortical_tmp.nii \
			$i \
			$SUBJECTS_DIR/mri/norm.mgz \
			$SUBJECTS_DIR/subcortical/subcortical_tmp.nii
		done
	fi

	# Seventh, binarize the whole volume
	fslmaths $SUBJECTS_DIR/subcortical/subcortical_tmp.nii -bin $SUBJECTS_DIR/subcortical/subcortical_bin.nii

	# Eighth, create a surface model of the binarized volume with mri_tessellate
	mri_tessellate $SUBJECTS_DIR/subcortical/subcortical_bin.nii.gz 1 $SUBJECTS_DIR/subcortical/subcortical

	# Ninth, convert binary surface output into stl format
	mris_convert $SUBJECTS_DIR/subcortical/subcortical $SUBJECTS_DIR/subcortical.stl
fi



#==========================================================================================
#4. Divide in Half the Subcortial 3D Model
#==========================================================================================

if [ ! -f $SUBJECTS_DIR/final_3Dbrain_raw.stl ] || [ $force_run -eq 1 ]; then

        python "$MAIN_DIR/divide_mesh.py" "$SUBJECTS_DIR/subcortical.stl" "$SUBJECTS_DIR/subcortical_LEFT.stl" "$SUBJECTS_DIR/subcortical_RIGHT.stl"

fi



#==========================================================================================
#5. Combine Cortical and Subcortial 3D Models
#==========================================================================================

# LEFT
if [ ! -f $SUBJECTS_DIR/final_3Dbrain_raw_LEFT.stl ] || [ $force_run -eq 1 ]; then

        python "$MAIN_DIR/combine_mesh.py" "$SUBJECTS_DIR/subcortical_LEFT.stl" "$SUBJECTS_DIR/cortical_LEFT.stl" "$SUBJECTS_DIR/final_3Dbrain_raw_LEFT.stl"

fi


# RIGHT
if [ ! -f $SUBJECTS_DIR/final_3Dbrain_raw_RIGHT.stl ] || [ $force_run -eq 1 ]; then

        python "$MAIN_DIR/combine_mesh.py" "$SUBJECTS_DIR/subcortical_RIGHT.stl" "$SUBJECTS_DIR/cortical_RIGHT.stl" "$SUBJECTS_DIR/final_3Dbrain_raw_RIGHT.stl"

fi



#==========================================================================================
#6. ScaleDependent Laplacian Smoothing, create a smoother surface: pymeshlab
#==========================================================================================

# LEFT
if [ ! -f $SUBJECTS_DIR/final_3Dbrain_LEFT.stl ] || [ $force_run -eq 1 ]; then

        python "$MAIN_DIR/pymesh_smoothing.py" "$SUBJECTS_DIR/final_3Dbrain_raw_LEFT.stl" "$SUBJECTS_DIR/final_3Dbrain_LEFT.stl"

fi

# RIGHT
if [ ! -f $SUBJECTS_DIR/final_3Dbrain_LEFT.stl ] || [ $force_run -eq 1 ]; then

        python "$MAIN_DIR/pymesh_smoothing.py" "$SUBJECTS_DIR/final_3Dbrain_raw_RIGHT.stl" "$SUBJECTS_DIR/final_3Dbrain_RIGHT.stl"

fi



#==========================================================================================
#7. Scale to desired length
#==========================================================================================

if [ $scale -eq 1 ];then

	#LEFT
	if [ ! -f $SUBJECTS_DIR/final_3Dbrain_${length}mm_LEFT.stl ] || [ $force_run -eq 1 ]; then

                python "$MAIN_DIR/scale_mesh.py" "$SUBJECTS_DIR/final_3Dbrain_LEFT.stl" "$SUBJECTS_DIR/final_3Dbrain_${length}mm_LEFT.stl" $length
		
	fi

	# RIGHT
	if [ ! -f $SUBJECTS_DIR/final_3Dbrain_${length}mm_RIGHT.stl ] || [ $force_run -eq 1 ]; then

                python "$MAIN_DIR/scale_mesh.py" "$SUBJECTS_DIR/final_3Dbrain_RIGHT.stl" "$SUBJECTS_DIR/final_3Dbrain_${length}mm_RIGHT.stl" $length
		
	fi
fi


