#!/bin/bash
######################################################################
# sap_netweaver_single_node.sh
# The script will help to setup cloud infrastructure and install SAP NetWeaver software 
# Author: Alibaba Cloud, SAP Product & Solution Team
#####################################################################
#==================================================================
# Environments
QUICKSTART_SAP_MOUDLE='sap-netweaver'
QUICKSTART_SAP_MOUDLE_VERSION='1.0.4'
QUICKSTART_ROOT_DIR=$(cd $(dirname "$0" ) && pwd )
QUICKSTART_SAP_SCRIPT_DIR="${QUICKSTART_ROOT_DIR}"
QUICKSTART_FUNCTIONS_SCRIPT_PATH="${QUICKSTART_SAP_SCRIPT_DIR}/functions.sh"
QUICKSTART_LATEST_STEP=6

INFO=`cat <<EOF
    Please input Step number
    Index | Action              | Description
    -----------------------------------------------
    1     | auto install        | Automatic setup cloud infrastructure and SAP NetWeaver software
    2     | manull install      | Setup cloud infrastructure and install SAP NetWeaver software step by step
    3     | Exit                |
EOF
`
STEP_INFO=`cat <<EOF
    Please input Step number
    Index | Action             | Description
    -----------------------------------------------
    1     | add host           | Add hostname into hosts file
    2     | mkdisk             | Create swap,physical volumes,volume groups,logical volumes,file systems
    3     | download media     | Download SAP NetWeaver software
    4     | extraction media   | Extraction SAP NetWeaver software
    5     | install NetWeaver  | Install SAP NetWeaver 7.4SR2 or NetWeaver 7.5 software
    6     | install packages   | Install additional packages and metrics collector
    7     | Exit               |
EOF
`

PARAMS=(
    HANASID
    HANAInstanceNumber
    HANAHostName
    HANAPrivateIpAddress
    SAPSID
    ASCSInstanceNumber
    PASInstanceNumber
    SapmntSize
    UsrsapSize
    NWSwapDiskSize
    DiskIdSapmnt
    DiskIdUsrSap
    DiskIdSwap
    FQDN
    MediaPath
    NWSapSysGid
    NWSapSidAdmUid
    ApplicationVersion
)

#==================================================================
#==================================================================
# Functions
#Define check_params function
#check_params
function check_params(){
    check_para MasterPass ${RE_PASSWORD}
    check_para HANASID ${RE_SID}
    check_para HANAInstanceNumber ${RE_INSTANCE_NUMBER}
    check_para HANAHostName ${RE_HOSTNAME}
    check_para HANAPrivateIpAddress ${RE_IP}

    check_para SAPSID ${RE_SID}
    check_para ASCSInstanceNumber ${RE_INSTANCE_NUMBER}
    check_para PASInstanceNumber ${RE_INSTANCE_NUMBER}
    check_para UsrsapSize ${RE_DISK}
    check_para SapmntSize ${RE_DISK}
    [[ -n "${NWSwapDiskSize}" ]] && check_para NWSwapDiskSize ${RE_DISK}

    check_para FQDN '(?!-)[a-zA-Z0-9-.]*(?<!-)'
    check_para MediaPath "^(oss|http|https)://[\\S\\w]+([\\S\\w])+$"
    check_para NWSapSidAdmUid "(^\\d+$)"
    check_para NWSapSysGid '^(?!1001$)\d+$'
    check_para ApplicationVersion '^NetWeaver (7.4SR2|7.5)$'
}

#Define init_variable function
#init_variable 
function init_variable(){
    SAP_INSTALL_TEMPLATE_PATH="${QUICKSTART_SAP_SCRIPT_DIR}/NetWeaver_single_node_install_template.params"
    MediaPath_SWPM="http://sap-automation-${QUICKSTART_SAP_REGION}.oss-${QUICKSTART_SAP_REGION}.aliyuncs.com/alibabacloud-quickstart/packages/SWPM1.0sp29.zip"
    PASHostname=$(hostname)
    ASCSHostname=$(hostname)

    case "$ApplicationVersion" in
        "NetWeaver 7.4SR2")
            SAPINST_EXECUTE_PRODUCT_ID="NW_ABAP_OneHost:NW740SR2.HDB.PI"
            NW_VERSION="NW740SR2"
            ;;
        "NetWeaver 7.5")
            SAPINST_EXECUTE_PRODUCT_ID="NW_ABAP_OneHost:NW750.HDB.ABAP"
            NW_VERSION="NW750"
            ;;
    esac

    TAR_NAME_SW=$(expr "${MediaPath_SWPM}" : '.*/\(.*\(zip\|ZIP\|tar\.gz\|tgz\|tar\.bz2\|tar\)\).*')
}

#Define add_host function
#add_host
function add_host() {
    info_log "Start to add hosts file"
    config_host "${ECSIpAddress} ${ECSHostname} ${ECSHostname}.${FQDN}"
    config_host "${HANAPrivateIpAddress} ${HANAHostName}"
}

#Define mkdisk function
#mkdisk
function mkdisk() {
    info_log "Start to create swap,physical volumes,volume group,logical volumes,file systems"
    check_disks $DiskIdSapmnt $DiskIdUsrSap $DiskIdSwap || return 1

    disk_id_usr_sap="/dev/${DiskIdUsrSap}"
    disk_size_usr_sap="${UsrsapSize}"
    disk_id_sapmnt="/dev/${DiskIdSapmnt}"
    disk_size_sapmnt="${SapmntSize}"
    disk_id_swap="/dev/${DiskIdSwap}"

    mk_swap ${disk_id_swap}

    pvcreate ${disk_id_usr_sap} ${disk_id_sapmnt} || return 1 
    vgcreate sapvg ${disk_id_usr_sap} ${disk_id_sapmnt} || return 1
    create_lv ${disk_size_sapmnt} sapmntlv sapvg 
    create_lv ${disk_size_usr_sap} usrsaplv sapvg "free"
    mkfs.xfs -f /dev/sapvg/sapmntlv || return 1
    mkfs.xfs -f /dev/sapvg/usrsaplv || return 1 
    mkdir -p /sapmnt /usr/sap
    $(grep -q /dev/sapvg/sapmntlv ${ETC_FSTAB_PATH}) || echo "/dev/sapvg/sapmntlv        /sapmnt  xfs defaults        0 0" >> ${ETC_FSTAB_PATH}
    $(grep -q /dev/sapvg/usrsaplv ${ETC_FSTAB_PATH}) || echo "/dev/sapvg/usrsaplv        /usr/sap  xfs defaults       0 0" >> ${ETC_FSTAB_PATH}

    mount -a
    check_filesystem || return 1
    info_log "Swap,physical volumes,volume group,logical volumes,file systems have been created successful"
}

#Define check_filesystem function
function check_filesystem() {
    info_log "Start to check SAP file systems"
    df -h | grep -q "/usr/sap" || { error_log "/usr/sap mounted failed"; return 1; }
    df -h | grep -q "/sapmnt" || { error_log "/sapmnt mounted failed"; return 1; }
    info_log "Both SAP relevant file systems have been mounted successful"
}

#Define NetWeaver function
#install_NetWeaver
function install_NetWeaver() {
    wait_HANA_ECS "${HANAPrivateIpAddress}" "${HANAInstanceNumber}" || return 1
    info_log "Start to install NetWeaver"
    sapinst_path=${QUICKSTART_SAP_EXTRACTION_DIR}"/${TAR_NAME_SW%.*}/"
    HANA_Client_Path=`find $QUICKSTART_SAP_EXTRACTION_DIR -regex .*SAP_HANA_CLIENT | tail -1`"/"
    Export_Path=`find $QUICKSTART_SAP_EXTRACTION_DIR -regex .*DATA_UNITS/EXP1`
    Export_Path="${Export_Path%EXP1}"
    MediaPath=${QUICKSTART_SAP_DOWNLOAD_DIR}"/"
    
    cat << EOF > ${SAP_INSTALL_TEMPLATE_PATH}
    NW_HDB_DB.abapSchemaName = SAPABAP1
    NW_HDB_DB.abapSchemaPassword = ${MasterPass}
    NW_ABAP_Import_Dialog.dbCodepage = 4103
    NW_ABAP_Import_Dialog.migmonJobNum = 40
    NW_ABAP_Import_Dialog.migmonLoadArgs = -c 100000 -rowstorelist ≈/${NW_VERSION}/HDB/INSTALL/STD/ABAP/rowstorelist.txt
    NW_CI_Instance.ascsInstanceNumber = ${ASCSInstanceNumber}
    NW_CI_Instance.ascsVirtualHostname = ${ASCSHostname}
    NW_CI_Instance.ciInstanceNumber = ${PASInstanceNumber}
    NW_CI_Instance.ciVirtualHostname = ${PASHostname}
    NW_CI_Instance.scsVirtualHostname = 
    NW_CI_Instance_ABAP_Reports.executeReportsForDepooling = true
    NW_GetMasterPassword.masterPwd = ${MasterPass}
    NW_GetSidNoProfiles.sid = ${SAPSID}
    NW_HDB_DBClient.clientPathStrategy = LOCAL
    NW_HDB_getDBInfo.dbhost = ${HANAHostName}
    NW_HDB_getDBInfo.dbsid = ${HANASID}
    NW_HDB_getDBInfo.instanceNumber = ${HANAInstanceNumber}
    NW_HDB_getDBInfo.systemDbPassword = ${MasterPass}
    NW_HDB_getDBInfo.systemPassword = ${MasterPass}
    NW_getFQDN.FQDN = ${FQDN}
    NW_getLoadType.loadType = SAP
    archives.downloadBasket = ${MediaPath}
    hanadb.landscape.reorg.useParameterFile = DONOTUSEFILE
    hdb.create.dbacockpit.user = true
    nwUsers.sapsysGID = ${NWSapSysGid}
    nwUsers.sidAdmUID = ${NWSapSidAdmUid}
    nwUsers.sidadmPassword = ${MasterPass}
    storageBasedCopy.hdb.instanceNumber = ${HANAInstanceNumber}
    storageBasedCopy.hdb.systemPassword = ${MasterPass}
    SAPINST.CD.PACKAGE.KERNEL = 
    SAPINST.CD.PACKAGE.LOAD = ${Export_Path}
    SAPINST.CD.PACKAGE.RDBMS = ${HANA_Client_Path}
EOF
    cd "${sapinst_path}" && ./sapinst SAPINST_INPUT_PARAMETERS_URL="${SAP_INSTALL_TEMPLATE_PATH}" SAPINST_EXECUTE_PRODUCT_ID="${SAPINST_EXECUTE_PRODUCT_ID}" SAPINST_SKIP_DIALOGS=true SAPINST_START_GUISERVER=false  >/dev/null || return 1
    validation || return 1
    info_log "Finished NetWeaver single node installation"
}

#Define validation function
#validation
function validation() {
    info_log "Start to check SAP NetWeaver running status"
    SID=$(echo "$SAPSID" |tr '[:upper:]' '[:lower:]')
    SIDADM=$(echo $SID\adm)
    su - ${SIDADM} -c "sapcontrol -nr ${ASCSInstanceNumber} -function GetProcessList" > /dev/null 2>&1
    msgserver=$?
    su - ${SIDADM} -c "sapcontrol -nr ${PASInstanceNumber} -function GetProcessList" > /dev/null 2>&1
    disp=$?
    if [ ${msgserver} == '3' -a ${disp} == '3' ];
    then
        info_log "SAP NetWeaver is running"
        return 0
    else
        error_log "SAP NetWeaver status is unknown"
        return 1
    fi
}

# Define setup function
# run step
function run(){
    case "$1" in
        1)
            add_host
            ;;
        2)
            mkdisk || return 1
            ;;
        3)
            mkdir -p "${QUICKSTART_SAP_DOWNLOAD_DIR}"
            download_medias "${MediaPath}" || return 1
            download "${MediaPath_SWPM}" "${TAR_NAME_SW}" || return 1
            ;;
        4)
            HANA_Client_SAR_Path=`find $QUICKSTART_SAP_EXTRACTION_DIR -regex .*IMDB_CLIENT.*.SAR | tail -1`
            sar_extraction "${HANA_Client_SAR_Path}" "${QUICKSTART_SAP_EXTRACTION_DIR}"|| return 1
            auto_extraction "${QUICKSTART_SAP_DOWNLOAD_DIR}" || return 1
            ;;
        5)
            install_NetWeaver || return 1
            ;;
        6)
            single_node_packages
            NW_post
            ;;
        *)
            error_log "Can't match Mark value,please check whether modify the Mark file"
            exit 1
            ;;
    esac
}


#==================================================================
#==================================================================
#Implementation
if [[ -s "${QUICKSTART_FUNCTIONS_SCRIPT_PATH}" ]]
then
    source "${QUICKSTART_FUNCTIONS_SCRIPT_PATH}"
    if [[ $? -ne 0 ]]
    then
        echo "Import file(${QUICKSTART_FUNCTIONS_SCRIPT_PATH}) error!"
    fi
else
    echo "Missing required file ${QUICKSTART_FUNCTIONS_SCRIPT_PATH}!"
    exit 1
fi

install $@ || EXIT