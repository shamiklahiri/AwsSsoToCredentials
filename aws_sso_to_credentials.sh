#!/bin/bash

## OPTIONS DEFAULT
# aws SSO endpoint
endpoint=""
# specify default region
region="eu-west-1"
profile="default"
skip_reconfigure="false"
backup_credentials="false"

usage() { echo "Usage: $0 -e 'https://some.awsapps.com/start\#/' [-r 'eu-west-1'] [-p 'nn-oa-d'] [-s] [-b]" 1>&2; exit 1; }

while getopts ":e:r:p:sb" o; do
    case "${o}" in
        e)
            endpoint=${OPTARG}
            ;;
        r)
            region=${OPTARG}
            ;;
        p)
            profile=${OPTARG}
            ;;
        s)
            skip_reconfigure="true"
            ;;
        b)
            backup_credentials="true"
            ;;
        *)
            usage
            ;;
    esac
done

echo "===== Options applied ========"
echo "endpoint=${endpoint}"
echo "region=${region}"
echo "profile=${profile}"
echo "skip-reconfigure=${skip_reconfigure}"
echo "backup-credentials=${backup_credentials}"
echo "===== Options End ========"

if [ -z ${endpoint} ]; then
  echo "!!! SCRIPT FAILED !!! Endpoint cannot be empty."
  usage
  exit 1
fi

if [ ${skip_reconfigure} == "false" ]; then
  # if sso is not configured yet or if you want to switch accounts/roles, try following
  aws configure sso --endpoint-url "${endpoint}" --region ${region} --profile ${profile}
fi

# first login with aws sso with following command
aws sso login --endpoint-url "${endpoint}" --region ${region} --profile ${profile}

AWS_CREDENTIALS_PATH="${HOME}/.aws/credentials"

if [ ${backup_credentials} == "true" ]; then
  if [ -f ${AWS_CREDENTIALS_PATH} ]; then
          echo "backing up existing credentials"
    cp -rf ${AWS_CREDENTIALS_PATH} "${AWS_CREDENTIALS_PATH}-"$(date +"%s")
  fi
fi

eval "$(aws configure export-credentials --profile $profile --format env)"

if [ -z ${AWS_SESSION_TOKEN} ]; then
  echo "!!! SCRIPT FAILED !!! Check above log and retry different options. Try configuring sso profile for the profile mentioned ( without '-s' option)."
  exit 1
fi

echo "[${profile}]" > ${AWS_CREDENTIALS_PATH}

echo "aws_access_key_id = ${AWS_ACCESS_KEY_ID}" >> ${AWS_CREDENTIALS_PATH}
echo "aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}" >> ${AWS_CREDENTIALS_PATH}
echo "aws_session_token = ${AWS_SESSION_TOKEN}" >> ${AWS_CREDENTIALS_PATH}

echo "credentials updated"

