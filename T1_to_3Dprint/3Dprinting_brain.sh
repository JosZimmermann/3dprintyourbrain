#!/bin/bash
#3dprintyourbrain

# >>> PREREQUISITES:
#     Install FreeSurfer (v6.0.0), FSL, pymeshlab and admesh on Linux. 
#     command to install admesh: sudo apt-get install -y admesh 
# 
# >>> FOLDER STRUCTURE:
#		3dbrain
#		--3Dprinting_brain.sh
#		--smoothing.xml
#		--sub-01
#		  --input
#		    --struct.nii or struct.nii.gz
#
#     -> The final smoothed full brain .stl file = output/final_3Dbrain_smooth.stl
#                                  
# >>> INSTRUCTIONS:
#     * Create the folder structure so that you have: 
#       - a subject folder (e.g., sub-01) within the main folder (i.e., 3dbrain) containing
#           - this script 3Dprinting_brain.sh
#           - the smoothing.xml file
#           - subfolder input containing struct.nii or struct.nii.gz which is a T1 MPRAGE NifTI file.
#
#     * Type in the command terminal, WITHIN the directory where this script resides:
#       ./3Dprinting_brain.sh  $MAIN_DIR $subject $MESHLAB_DIR
#       Three arguments: 
#       !! Change: 1. $MAIN_DIR to the correct 3dbrain directory, e.g. "/media/sofie/my_brains/3dbrain"
#                  2. $subject to the correct subject folder name, e.g., "sub-01"
#                  3. $MESHLAB_DIR to the correct MeshLab directory 
#                     (containing meshlabserver), e.g. "/usr/bin/"
#       => example: ./3Dprinting_brain.sh "/mnt/c/Users/Josua/Documents/Research/Quednow/Data_analysis_EMIC/MRI/3Dprint_brain" "Josh" "/usr/bin/"

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
export scale=(0) #if 0 -> no scaling; if 1 -> scaling to specified length
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

# Path to meshlabserver 
export MESHLAB_DIR=$3


#==========================================================================================
#2. Create Surface Model with FreeSurfer
#==========================================================================================

if [ ! -f $SUBJECTS_DIR/surf/lh.pial ] ||  [ ! -f $SUBJECTS_DIR/surf/rh.pial ] || [ $force_recon -eq 1 ]; then

	mkdir -p $SUBJECTS_DIR/mri/orig
	mri_convert ${subjT1} $SUBJECTS_DIR/mri/orig/001.mgz
	recon-all -subjid "output" -all -time -log logfile -nuintensitycor-3T -sd "$MAIN_DIR/${subject}/" -parallel
fi

#==========================================================================================
#3. Create 3D Model of Cortical and Subcortical Areas
#==========================================================================================

# CORTICAL
# Convert output of step (2) to fsl-format
if [ ! -f $SUBJECTS_DIR/cortical.stl ] || [ $force_run -eq 1 ]; then

	mris_convert --combinesurfs $SUBJECTS_DIR/surf/lh.pial $SUBJECTS_DIR/surf/rh.pial \
             $SUBJECTS_DIR/cortical.stl
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
#4. Combine Cortical and Subcortial 3D Models
#==========================================================================================

if [ ! -f $SUBJECTS_DIR/final_3Dbrain_raw.stl ] || [ $force_run -eq 1 ]; then

	admesh --no-check --merge=$SUBJECTS_DIR/subcortical.stl --write-binary-stl=$SUBJECTS_DIR/final_3Dbrain_raw.stl $SUBJECTS_DIR/cortical.stl
fi

#==========================================================================================
#5. ScaleDependent Laplacian Smoothing, create a smoother surface: MeshLab
#==========================================================================================

if [ ! -f $SUBJECTS_DIR/final_3Dbrain.stl ] || [ $force_run -eq 1 ]; then

        python3 $MAIN_DIR/pymeshlab_smoothing.py $SUBJECTS_DIR/final_3Dbrain_raw.stl $SUBJECTS_DIR/final_3Dbrain.stl
	#$MESHLAB_DIR/meshlabserver -i $SUBJECTS_DIR/final_3Dbrain_raw.stl -o $SUBJECTS_DIR/final_3Dbrain.stl -s $MAIN_DIR/smoothing.mlx
fi

#==========================================================================================
#6. Scale to desired length
#==========================================================================================

if [ $scale -eq 1 ];then
	if [ ! -f $SUBJECTS_DIR/final_3Dbrain_${length}mm.stl ] || [ $force_run -eq 1 ]; then

		#get current length
		admesh --no-check $SUBJECTS_DIR/final_3Dbrain.stl > $SUBJECTS_DIR/mesh_info.txt
		ymax=$(awk '/Min Y/{ print $8 }' $SUBJECTS_DIR/mesh_info.txt)
		ymin_temp=$(awk '/Min Y/{ print $4 }' $SUBJECTS_DIR/mesh_info.txt)
		ymin=${ymin_temp::-1}
		length_temp=$(echo "$ymax - $ymin" | bc)
		
		#compute scale factor
		scale_factor=$(echo "$length / $length_temp" | bc -l)
		
		#scale 3D file
		admesh --no-check --scale=$scale_factor --write-binary-stl=$SUBJECTS_DIR/final_3Dbrain_${length}mm.stl $SUBJECTS_DIR/final_3Dbrain.stl
	fi
fi
