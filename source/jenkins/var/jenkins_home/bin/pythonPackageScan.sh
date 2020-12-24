#!/bin/bash
tmp_dir=$(mktemp -d -t ci-XXXXXXXXXX)
tmp_env_file=$(mktemp -p ${tmp_dir} en-XXXXXXXXXX)
for i in "$@"
do
case $i in
    -p=*|--package=*)
    PACKAGE="${i#*=}"
	echo "PACKAGE=\"${PACKAGE}\"" >> ${tmp_env_file}
    shift # past argument=value
    ;;
    -d=*|--dependencies=*)
    LIBPACKS="${i#*=}"
	echo "LIBPACKS=\"${LIBPACKS}\"" >> ${tmp_env_file}
    shift # past argument=value
    ;;
    -s=*|--scanpath=*)
    SCANPATH="${i#*=}"
	echo "SCANPATH=\"${SCANPATH}\"" >> ${tmp_env_file}
    shift # past argument=value
    ;;
    -o=*|--options=*)
    OPTIONS="${i#*=}"
	echo "OPTIONS=\"${OPTIONS}\"" >> ${tmp_env_file}
    shift # past argument=value
    ;;
    -e*|--erroroutput*)
    ANYOUPUTASERROR="TRUE"
	echo "ANYOUPUTASERROR=\"${ANYOUPUTASERROR}\"" >> ${tmp_env_file}
    shift # past argument=value
    ;;
    *)
       echo "unknown option:"
	   echo "usage ${0} -p|--package=pythonscanpackagename -d|--dependencies=packagedependencies -s|--scanpath=scanpath -o|--options=scanoptions -i|--ignoreout"
       exit -1	   
    ;;
esac
done
#create a temporary directory to set up virtualenv to 
build_dir=$(pwd)
#temporary switch to temporary directory to create virtualenv to install the package
cd ${tmp_dir}
virtualenv venv
source ${tmp_dir}/venv/bin/activate
source ${tmp_env_file}
#get the package dependencies for this test and install them
DEPPACKAGES=$(echo ${LIBPACKS} | sed -e 's/;/ /g')
${tmp_dir}/venv/bin/pip3 install ${PACKAGE} ${DEPPACKAGES} >/dev/null
${tmp_dir}/venv/bin/python3 $tmp_dir/venv/lib/python3.6/site-packages/${PACKAGE} ${OPTIONS} ${SCANPATH} 2>${tmp_dir}/${PACKAGE}Error.log 1>${tmp_dir}/${PACKAGE}Out.log
PACKAGEExit=$?
echo "dumping ${PACKAGE} Error:"
cat ${tmp_dir}/${PACKAGE}Error.log
echo "***************************************************"
echo "dumping ${PACKAGE} Out:"
cat ${tmp_dir}/${PACKAGE}Out.log
echo "***************************************************"
##if we had anything in std error then write it out
if [ -s ${tmp_dir}/${PACKAGE}Error.log ]; then PACKAGEExit=-2; fi  
##if any output is to be treated as error  then our return code is -1 as we have some output
if [[ ! -z ${ANYOUPUTASERROR} && -s ${tmp_dir}/${PACKAGE}Out.log ]]; then PACKAGEExit=-1; fi  
deactivate
rm -rf ${tmp_dir}
exit ${PACKAGEExit}
