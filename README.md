# Swift library deployment

This repository contains a supporting script for our swift libraries deployment. The document is using following constants:

- `${DEP_TOOL}` - path where you have cloned [this repository](https://github.com/wultra/swift-library-deploy)
- `${REPO}` - path to repository, containing library you're going to deploy


## Prepare library for deployment

This part of documentation explains how to prepare a new library for deployment with using scripts from this repository. We're expecting
that library has stable build, so:

- You can really compile the library without errors
- In case of cocoapods, you have already valid `podspec` file

### Prepare template files 

Template files are textual files with version placeholder. The deploy script is doing following operations for each such file:

- Checks whether template file exists
- Checks whether destination file exists
- Loads its content and replaces placeholder `%DEPLOY_VERSION%` with an actual version string
- Stores final string into destination file 

For swift projects, two files typically has to be updated with a new version:

- `YourLibrary.podspec` - a file declaring library for cocoapods dependency manager
- `Info.plist` - a info file created by Xcode.

You can look into our [LimeCore library for examples](https://github.com/wultra/swift-lime-core/tree/develop/Deploy).
   
### Prepare `.limedeploy` file

`.limedeploy` contains information about library deployment and the file must be stored in the root of the library:

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
DEPLOY_MODE='swift-cocoapods'
```

Each line contains assignment to one global variable:

- `DEPLOY_POD_NAME` - contains name of cocoa pod, for example `LimeCore`
- `DEPLOY_VERSIONING_FILES` - contains array defining template files and destination versioning files. Each string in the array contains two, 
  comma separated relative paths: first file is a source template, second is path to actual versioning file.
- `DEPLOY_MODE` contains mode of deployment. Currently only `swift-cocoapods` is supported.


## Publish version

Before you publish a new version, make sure that:

- You can build this version of library without errors or warnings
- Your git status is clean. You can have not-pushed commits, but your repo must be clean and without uncommitted changes.

To publish a new version of build, simply type:
```bash
$ ${DEP_TOOL}/lime-deploy-build.sh  ${REPO}  ${NEW_VERSION}
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

If you need to make custom changes, then you can perform each steps individually. Type `${DEP_TOOL}/lime-deploy-build.sh -h` for details.
