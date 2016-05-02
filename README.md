# 3D print your brain

So, you want to 3D print your own brain? The following is a step by step guide that will show you how you can 3D print a brain, all coming from a structural image (T1) like this:

![alt text](static/brain.png "Brain - T1 image")

**Note:** To create a 3D surface model of your brain we will use FreeSurfer and meshlab. Therefore you should make sure that those two softwares are already installed on your system.


1. Specify Variables
--------------------

Let's first specify all necessary variables that we need for this to work:

```bash
export EXPERIMENT_DIR=/users/mnotter/tmp
export SUBJECTS_DIR=$EXPERIMENT_DIR/freesurfer
export subjectName=sub001
```


![alt text](static/message_duplicates.png "some text")
![alt text](static/message_export.png "some text")
![alt text](static/cortical_rough.png "some text")
![alt text](static/laplacian_smooth.png "some text")
![alt text](static/cortical_smooth.png "some text")
![alt text](static/subcortical.png "some text")








