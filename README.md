# Library deployment

This repository contains a supporting script for our libraries deployment. The document is using following constants:

- `${DEP_TOOL}` - path where you have cloned [this repository](https://github.com/wultra/library-deploy)
- `${REPO}` - path to repository, containing library you're going to deploy


## Prepare library for deployment

This part of documentation explains how to prepare a new library for deployment with using scripts from this repository. We're expecting
that library has stable build, so:

- You can really compile the library without errors
- In case of cocoapods, you have already valid `podspec` file
- In case of gradle, you have properly configured uploading to bintray.

### Prepare template files 

Template files are textual files with version placeholder. The deploy script is doing following operations for each such file:

- Checks whether template file exists
- Checks whether destination file exists
- Loads its content and replaces placeholder `%DEPLOY_VERSION%` with an actual version string
- Stores final string into destination file 

For swift projects, two files typically has to be updated with a new version:

- `YourLibrary.podspec` - a file declaring library for cocoapods dependency manager
- `Info.plist` - a info file created by Xcode.
- You can look into our [LimeCore library for examples](https://github.com/wultra/swift-lime-core/tree/develop/Deploy).

For gradle projects, one file has to be updated with a new version:

- `gradle.properties` - a file which typically contains a version of library
- You can look into our [passphrase-meter](https://github.com/wultra/passphrase-meter/tree/develop/Deploy) library for examples. 

For npm projects, one file has to be updated with a new version:

- `package.json` - a file which typically contains a version of library
- You can look into our [malwarelytics-cordova-plugin](https://github.com/wultra/malwarelytics-cordova-plugin/tree/develop/.deploy) library for examples. 
   
### Prepare `.limedeploy` file

`.limedeploy` contains information about library deployment and the file must be stored in the root of the repository:

```bash
$ cd ${REPO}
$ touch .limedeploy
$ open .limedeploy
```

Last command will open empty `.limedeploy` file in your preferred text editor. You can put following lines to the file 
(the file is regular bash script, so you should be familiar with bash syntax):

```bash
DEPLOY_POD_NAME='LimeCore'
DEPLOY_VERSIONING_FILES=( "Deploy/LimeCore.podspec,LimeCore.podspec" "Deploy/Info.plist,Source/Info.plist" )
DEPLOY_MODE='cocoapods'
```

Each line contains assignment to one global variable:

- `DEPLOY_POD_NAME` - contains name of cocoa pod, for example `LimeCore`
- `DEPLOY_VERSIONING_FILES` - contains array defining template files and destination versioning files. Each string in the array contains two, 
  comma separated relative paths: first file is a source template, second is path to actual versioning file.
- `DEPLOY_MODE` contains mode of deployment. Following modes are supported:
  - `cocoapods` - deployment with using `pod` tool
  - `gradle` - deployment with using `gradlew` tool
  - `npm` - deployment with using `npm` tool
  - `more` - for a complex deployments with multiple deployment targets at once

### `cocoapods` mode parameters

- `DEPLOY_POD_NAME` is required parameter, specifying which pod is going to be published

### `gradle` mode parameters

- `DEPLOY_LIB_NAME` is required parameter, specifying name of library. The name will be used for git tag comment, created for the new version.
- `DEPLOY_GRADLE_PARAMS` is required and specifying command line parameters for `gradle` for deployment task. For example: `clean build install bintrayUpload`
- `DEPLOY_GRADLE_PREPARE_PARAMS` is optional and specifying command line parameters for `gradle` for prepare task. If not specified, then `clean assembleRelease` is used.
- `DEPLOY_GRADLE_PATH` is optional and specifying path to `gradlew` wrapper script. If not specified, then path to repository is used.

### `npm` mode parameters
_No parameters available for this mode. `npm publish` is run in the repository._

### `more` mode parameters

- `DEPLOY_LIB_NAME` is required parameter, specifying name of library. The name will be used for git tag comment, created for the new version.
- `DEPLOY_MORE_TARGETS` is required parameters, specifying which other modes has to be executed. For example: `gradle cocoapods`



## Publish version

Before you publish a new version, make sure that:

- You can build this version of library without errors or warnings
- Your git status is clean. You can have not-pushed commits, but your repo must be clean and without uncommitted changes.

To publish a new version of build, simply type:
```bash
$ ${DEP_TOOL}/deploy-build.sh  ${REPO}  ${NEW_VERSION}
```

The script will perform following steps:

- **prepare** - prepares versioning files. This step is divided into several separate operations:

   1. All versioning files are prepared and committed to the local git repository
   2. A tag for new version is created.
   3. Build of the library is tested (for swift projects, this typically executes `pod lib lint`)

   The result is that your local git repository will contain a prepared versioning files, tag with version
   and finally, you can be sure, that it's possible to build this version of the library.

- **push** - pushes all changes to library's remote git repository

- **deploy** - deploys build to a public repository (for swift projects, it typically executes `pod trunk push`)

- **merge** - merges all changes to **master** branch

If you need to make custom changes, then you can perform each steps individually. Type `${DEP_TOOL}/deploy-build.sh -h` for details.
