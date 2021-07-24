#!/bin/bash
# sample cmd with required arguments
# sh generate-package.sh -pid <packagid> -u <username>
# example
# sh generate-package.sh -pid 033blahahaha -u packagingorg@example.com

# --username -u $USERNAME 
# --packageid -pid $PACKAGEID  i.e. 033blahblah
# --forceapprove -fa $FORCEAPPROVE i.e. to not prompt user for confirmation (with yes/no) to create package. It will just create it.
# --managed -m $MANAGEDRELEASE
# --packagename -pn "$PackageName"  i.e. MyApp
# --packagedescription -pd "$PackageDescription"  i.e. MyApp description
# --packagereleasenotesurl -prnu "$PackageReleaseNotesUrl"  i.e. https://example.com/release-notes
# --packagepostinstallurl -ppiu "$PackagePostInstallUrl" i.e. https://example.com/post-install
# --newpackageversion -npv $NEWPACKAGEVERSION i.e. 1.1 or 1.1.0 etc
PackageName='Trail App'
PackageDescription='Trail App Description'
PackageReleaseNotesUrl='https://example.com/release-notes'
PackagePostInstallUrl='https://example.com/post-install'

NEWPACKAGEVERSION=''
PACKAGEID=''
MANAGEDRELEASE=0 # 1 will be managed release 0 or any other will
FORCEAPPROVE=0 # 1 will be force approve the package creation and skip confirmation prompt before creating the new package
USERNAME=""
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -npv|--newpackageversion)
    NEWPACKAGEVERSION="$2"
    shift # past argument
    shift # past value
    ;;
    -fa|--forceapprove)
    FORCEAPPROVE="$2"
    shift # past argument
    shift # past value
    ;;
    -u|--username)
    USERNAME="$2"
    shift # past argument
    shift # past value
    ;;
    -m|--managed)
    MANAGEDRELEASE="$2"
    shift # past argument
    shift # past value
    ;;
    -pn|--packagename)
    PackageName="$2"
    shift # past argument
    shift # past value
    ;;
    -pd|--packagedescription)
    PackageDescription="$2"
    shift # past argument
    shift # past value
    ;;
    -prnu|--packagereleasenotesurl)
    PackageReleaseNotesUrl="$2"
    shift # past argument
    shift # past value
    ;;
    -ppiu|--packagepostinstallurl)
    PackagePostInstallUrl="$2"
    shift # past argument
    shift # past value
    ;;
    -pid|--packageid)
    PACKAGEID="$2"
    shift # past argument
    shift # past value
    ;;
esac
done

if [[ "$PACKAGEID" == '' ]] ; then
    echo ====== ERROR: PACKAGEID is not provided. Exiting process=======
    exit 1
fi

if [[ "$USERNAME" == '' ]] ; then
    echo ====== ERROR: USERNAME is not provided. Exiting process=======
    exit 1
fi

packageVersionListRequestInfoJSON=$(sfdx force:package1:version:list --packageid $PACKAGEID --json)
echo "Showing list of package versions"
echo $packageVersionListRequestInfoJSON
packageVersionListRequestStatus=$( echo $packageVersionListRequestInfoJSON | jq -r '.status' )
echo "Package version list request status: $packageVersionListRequestStatus"
if [[ "$packageVersionListRequestStatus" != 0 ]] ; then
    echo ====== ERROR: something went wrong! request to list version request failed. Exiting process=======
    exit 1
fi

packageVersionListResultArrayLastItemVersion=$( echo $packageVersionListRequestInfoJSON | jq .result[-1].Version)
latestVersionReleaseState=$( echo $packageVersionListRequestInfoJSON | jq .result[-1].ReleaseState)

echo 'Full version:'$packageVersionListResultArrayLastItemVersion
latestMajorAndMinorVersion=$(echo $packageVersionListResultArrayLastItemVersion | jq 'split(".")' | jq '.[:2]' | jq 'join(".")')
echo 'Latest Version:'$latestMajorAndMinorVersion
echo 'Latest Release state:'$latestVersionReleaseState
newVersion=$latestMajorAndMinorVersion
if [[ "$latestVersionReleaseState" != '"Beta"' ]]; then
    echo 'Incrementing the version number'
    newVersion=$(echo $latestMajorAndMinorVersion | jq 'split(".")' | jq 'map(tonumber)' | jq '.[1] += 1' | jq '.[:2]' | jq 'join(".")')
    echo 'New Version:'$newVersion
fi
# if last releasestate is beta then we don't increment because we cannot until we have managed release version with that number.

# let's assign the newly incremented version to NEWPACKAGEVERSION if it is empty

if [[ "$NEWPACKAGEVERSION" == '' ]] ; then
    echo ' NEWPACKAGEVERSION is not provided so going to use the one we queried'
    NEWPACKAGEVERSION=$newVersion
fi
NEWPACKAGEVERSION=$(echo $NEWPACKAGEVERSION | jq '.|tonumber')
echo 'NEWPACKAGEVERSION:'$NEWPACKAGEVERSION

if [[ "$FORCEAPPROVE" == 1 ]] ; then
    echo '====== We are going to create a new package without asking for comfirmation since --forcapprove argument is passed ======='
    sh create-package.sh -m $MANAGEDRELEASE -u "$USERNAME" -npv $NEWPACKAGEVERSION -pid $PACKAGEID -pn "$PackageName" -pd "$PackageDescription" -prnu "$PackageReleaseNotesUrl" -ppiu "$PackagePostInstallUrl" || exit 1;
    exit
fi

# Let's create new package with given arguments on selecting yes
echo "Do you wish to continue the installation with above version?"
select yn in "Yes" "No"; do
    case $yn in
        Yes ) sh create-package.sh -m $MANAGEDRELEASE -u "$USERNAME" -npv $NEWPACKAGEVERSION -pid $PACKAGEID -pn "$PackageName" -pd "$PackageDescription" -prnu "$PackageReleaseNotesUrl" -ppiu "$PackagePostInstallUrl"; break;;
        No ) exit;;
    esac
done