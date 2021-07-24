
#!/bin/bash
# --managed -m $MANAGEDRELEASE
# --username -u $USERNAME 
# --packageid -pid $PACKAGEID  i.e. 033blahblah
# --packagename -pn "$PackageName"  i.e. MyApp
# --packagedescription -pd "$PackageDescription"  i.e. MyApp description
# --packagereleasenotesurl -prnu "$PackageReleaseNotesUrl"  i.e. https://example.com/release-notes
# --packagepostinstallurl -ppiu "$PackagePostInstallUrl" i.e. https://example.com/post-install
# --newpackageversion -npv $NEWPACKAGEVERSION i.e. 1.1 or 1.1.0 etc


PackageName=''
PackageDescription=''
PackageReleaseNotesUrl=''
PackagePostInstallUrl=''

NEWPACKAGEVERSION=''
PACKAGEID=''
MANAGEDRELEASE=0 # 1 will be managed release 0 or any other will be beta release
USERNAME=''
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -npv|--newpackageversion)
    NEWPACKAGEVERSION="$2"
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

if [[ "$MANAGEDRELEASE" == 1 ]] ; then
echo 'Creating a managed release package'
packageVersionCreateRequestInfoJSON=$(sfdx force:package1:version:create -u $USERNAME --packageid $PACKAGEID --name "$PackageName" --description "$PackageDescription" -r "$PackageReleaseNotesUrl" -p "$PackagePostInstallUrl" --version $NEWPACKAGEVERSION --managedreleased --json)
else
echo 'Creating a beta release package'
packageVersionCreateRequestInfoJSON=$(sfdx force:package1:version:create -u $USERNAME --packageid $PACKAGEID --name "$PackageName" --description "$PackageDescription" -r "$PackageReleaseNotesUrl" -p "$PackagePostInstallUrl" --version $NEWPACKAGEVERSION --json)
fi
echo "Showing newly created package version info" &&
echo $packageVersionCreateRequestInfoJSON
packageVersionCreateRequestStatus=$( echo $packageVersionCreateRequestInfoJSON | jq -r '.status' )
echo "Package version request status: $packageVersionCreateRequestStatus"
if [[ "$packageVersionCreateRequestStatus" != 0 ]] ; then
    echo ====== ERROR: something went wrong! request to create version request failed. New package version is not generated. Exiting process=======
    exit 1
fi
packageVersionCreateRequestId=$( echo $packageVersionCreateRequestInfoJSON | jq -r '.result.Id' )

packageVersionCreateGetRequestStatusInfoJSON=$(sfdx force:package1:version:create:get -u $USERNAME -i $packageVersionCreateRequestId --json)
echo "Showing status of request of created package version" &&
echo $packageVersionCreateGetRequestStatusInfoJSON
packageVersionCreateGetRequestStatus=$( echo $packageVersionCreateGetRequestStatusInfoJSON | jq -r '.status' )
echo "Package version get request status: $packageVersionCreateGetRequestStatus"
if [[ "$packageVersionCreateGetRequestStatus" != 0 ]] ; then
    echo ====== ERROR: something went wrong! request to fetch version create request failed. Exiting process=======
    exit 1
fi

packageVersionCreateGetResultStatus=$( echo $packageVersionCreateGetRequestStatusInfoJSON | jq -r '.result.Status' )

echo "Package version result status: $packageVersionCreateGetResultStatus"
loopCount=1
while [[ $loopCount -le 15 ]] && [[ "$packageVersionCreateGetResultStatus" == "IN_PROGRESS" ]]
do
    if [[ "$packageVersionCreateGetResultStatus" == "SUCCESS" ]];then
        echo "Got success!!! breaking out of the loop"
        break       	   #Abandon the while loop.
    fi
    echo "Running request $x times"
    sleep 1m # Wait 1 minute.
    packageVersionCreateGetRequestStatusInfoJSON=$(sfdx force:package1:version:create:get -u $USERNAME -i $packageVersionCreateRequestId --json)
    echo "In loop - Showing status of request of created package version" &&
    echo $packageVersionCreateGetRequestStatusInfoJSON
    packageVersionCreateGetRequestStatus=$( echo $packageVersionCreateGetRequestStatusInfoJSON | jq -r '.status' )
    echo "In loop - Package version get request status: $packageVersionCreateGetRequestStatus"
    if [[ "$packageVersionCreateGetRequestStatus" != 0 ]] ; then
        echo ====== IN_LOOP_ERROR: something went wrong! request to fetch version create request failed. Exiting process=======
        exit 1
    fi

    packageVersionCreateGetResultStatus=$( echo $packageVersionCreateGetRequestStatusInfoJSON | jq -r '.result.Status' )
    echo "Package version result status: $packageVersionCreateGetResultStatus" 
      
    loopCount=$(( $loopCount + 1 ))
done