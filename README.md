# EE to build apps

Ansible EE to build apps, with following dependencies:

* Skopeo
* Gradle
* Helm
* oc (OpenShift CLI)
* tss (Delinea Secret Server CLI)

To successfully build this EE, please use the `build_ee.sh` script.

```bash
./build_ee.sh 
Script to build an Ansible EE to install OpenShift

Syntax: build_ee.sh [-h|-a|-b|-d]
options:
-h   Print this Help.
-d   Download Openshift artifacts.
-b   Build EE.
-a   Download OpenShift artifacts and build EE.
```

If you can change the versions of the dependencies being installed in the EE,
please edit them in the `build_ee.sh` script.
