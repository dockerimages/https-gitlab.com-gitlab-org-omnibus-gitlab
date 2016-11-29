#!/bin/env bash
# packagecloud_upload.sh
# Upload packages to packagecloud after built.
# - We're splitting this out because we need to split off the sl/ol repos per
#   gitlab-omnibus !892 . These will be the same package, just uploaded to all
#   related distribution repositories.

# - We set LC_ALL below because package_cloud is picky about the locale
export LC_ALL='en_US.UTF-8'
export ERRTMP=`mktemp`

if [ $# -ne 3 ]; then
    echo "FAILURE: Invalid number of arguments. Got $#, '$@'"
    exit 1;
fi

PACKAGECLOUD_USER=$1
PACKAGECLOUD_REPO=$2
PACKAGECLOUD_OS=$3

declare -A OS

OS[0]="${PACKAGECLOUD_OS}"
if [[ "${PACKAGECLOUD_OS}" =~ "el/" ]]; then
    OS[1]="${OS[0]/el/scientific}"
    OS[2]="${OS[0]/el/ol}"
fi


runPackageCloud ()
{
    location=$1
    pacakge=$2

    RETRY_LIMIT=3
    retry=0

    while [ $retry < $RETRY_LIMIT ];
    do
        if [ $retry -gt 0 ]; then
            sleep 1;
        fi

        retry=$( expr $retry + 1 )
        echo "Trying #$RETRY at uploading to packagecloud"
        bin/package_cloud push $location $package --url=https://packages.gitlab.com 2>$ERRTMP
        result=$?
        if [ $result -eq 1 ]; then
            # Check the error log for an error in 5xx series.
            # We care about: 500, 502, 503, 504
            # Expected: "restclient/abstract_response.rb:48:in `return!': 504 Gateway Timeout (RestClient::GatewayTimeout)"
            error=`head -n1 $ERRTMP`
            regex='return.{3} ([1-5][0-9]{2}) (.*) (RestClient::'
            if [[ $error =~ $regex ]]; then
                # HTTP error code
                code=${BASH_REMATCH[1]}
                message=${BASH_REMATCH[2]}
                echo "HTTP ERROR: $code $message"
                if [ $code -ge 500 -a $code -le 504 ]; then
                    # server side error, retry in 1 second
                    echo "HTTP $code error, retrying"
                else
                    # don't retry on non-5xx errors
                    retry=$code
                fi
            else
                # true failure, return failure.
                echo "Unknown failure. See backtrace below:"
                cat $ERRTMP
                retry=1000
            fi
        else
            # SUCCESS!
            retry=9001
        fi
    done

    if [ $retry -gt 9000 ]; then
        retry=0
    elif [ $retry -eq 1000 ]; then
        retry=1
    fi
    return $retry
}

for distro in "${OS[@]}" ; do
    location="${PACKAGECLOUD_USER}/${PACKAGECLOUD_REPO}/${distro}"
    # Here we loop on the output of find, in the off chance that we accidentally
    # get more than one file. This _should_ never be the case, but in the off
    # chance that it occurs, we'll output a warning, and then attempt upload anyways
    count=0
    for package in `find pkg -name '*.rpm' -o -name '*.deb'`; do
        count=$(expr $count + 1)
        if [ $count -gt 1 ]; then
            echo "WARNING: multiple packages detected!"
        fi
        echo "Uploading '$package' to packagecloud at '$location'"
        runPackageUpload  $location $package
        result=$?
        if [  $result - gt 0 ]; then
            exit $result;
        fi
        done;
done;

# remove error log temp file
rm $ERRTMP
