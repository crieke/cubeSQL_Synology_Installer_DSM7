#!/bin/bash
currentDir="$(dirname "$0")"
preVerPath="$(${currentDir}/../scripts/getsharelocation cubeSQL)"
JSON_URL="https://sqlabs.com/download/cubesql/synology.json"
ARCH=$(uname -m)
DOWNLOAD_LINKS=$(curl -s "$JSON_URL" | jq -c --arg v "$ARCH" '.[$v]')

if [ "${ARCH}" == "x86_64" ]; then
  CPU="64bit";
elif [ "${ARCH}" == "i686" ]; then
  CPU="32bit";
elif [ "${ARCH}" == "i386" ]; then
  CPU="32bit";
else
  CPU="unsupported"
fi
/bin/cat > /tmp/wizard.php <<EOF
<?php
\$preVerPath = "$preVerPath";

\$STEP1 = array(
    "step_title" => "Where should cubeSQL store its data?",
    "items" => [array(
        "type" => "combobox",
        "desc" => "Your databases and database exports will be stored and can be accessed there.<br>",
        "invalid_next_disabled_v2" => TRUE,
        "subitems" => [array(
            "key" => "WIZARD_DATABASE_DIR",
            "desc" => "cubeSQL database",
            "displayField" => "name",
            "defaultValue" => "Please select",
            "valueField" => "name",
            "forceSelection" => TRUE,
            "autoSelect" => FALSE,
            "title" => "cubeSQL databases",
            "editable" => TRUE,
            "api_store" => array(
                "api" => "SYNO.FileStation.List",
                "method" => "list_share",
                "version" => 2,
                "root" => "shares",
                "idProperty" => "name",
                "fields" => ["name"]
            ),
            "validator" => array(
                "fn" => "{var dbshare=arguments[0];var d=dbshare != \"homes\" && dbshare != \"home\" && dbshare != \"Please select\"; if (!d) return 'Please choose a different shared folder for your databases.';return true;}"
            )
        ),
            array(
            "key" => "WIZARD_HIDDEN_FIELD",
            "desc" => "This is a placeholder field. It is a workaround, as it seems the last combobox in the PKG-WIZARD always gets filled with the first entry.",
            "displayField" => "name",
            "defaultValue"=> "Nothing to select here.",
            "valueField" => "name",
            "autoSelect" => false,
            "forceSelection" => true,
            "title" => "PLACEHOLDER",
            "editable" => false,
            "hidden" => true,
            "api_store" => array(
                "api" => "SYNO.FileStation.List",
                "method" => "list_share",
                "version" => 2,
                "root" => "shares",
                "idProperty" => "name",
                "fields" => ["name"]
            )
        )]
    )]
);
\$STEP2 = array(    
    "step_title" => "Specify cubeSQL version to install",
    "items" => [array(
        "type" => "combobox",
        "desc" => "You can specify the version of cubeSQL to install in the dropdown menu.<br>",
        "invalid_next_disabled_v2" => true,
        "subitems" => [array(
            "key" => "WIZARD_DL_URL",
            "desc" => "Version",
            "displayField" => "displayText",
            "defaultValue" => "Please select",
            "valueField" => "url",
            "autoSelect" => FALSE,
            "mode" => "local",
            "store" => array(
                "xtype" => "arraystore",
                "fields" => ["displayText", "url"],
                "data" => json_decode('$DOWNLOAD_LINKS', true)
            ),
            "validator" => array(
                "fn" => "{var cubesqlver=arguments[0]; var d=cubesqlver != \"Please select\"; if (!d) return 'Please a cubeSQL version to install.';return true;}"    
            ),
            "forceSelection" => TRUE,
            "editable" => FALSE
        ),array(
            "key" => "WIZARD_HIDDEN_FIELD",
            "desc" => "This is a placeholder field. It is a workaround, as it seems the last combobox in the PKG-WIZARD always gets filled with the first entry.",
            "displayField" => "name",
            "defaultValue" => "Nothing to select here.",
            "valueField" => "name",
            "autoSelect" => false,
            "forceSelection" => true,
            "title" => "PLACEHOLDER",
            "editable" => false,
            "hidden" => true,
            "api_store" => array(
                "api" => "SYNO.FileStation.List",
                "method" => "list_share",
                "version" => 2,
                "root" => "shares",
                "idProperty" => "name",
                "fields" => ["name"]
            )
        )]
    )]
);
\$STEP3 = array(
    "step_title" => "Migrate your DSM6 cubeSQL data?",
    "items" => [array(
        "type" => "multiselect",
        "desc" => "On previous DSM6 installs, cubeSQL had a fixed data folder for its databases and backups. cubeSQL was also running as root user, which is not allowed in DSM7. When you choose to migrate your DSM6 data, your DSM6 cubeSQL data will be copied into a new 'cubeSQL' folder on your specified data storage.<br>This will only work, if your specified shared folder does not already have a folder called 'cubeSQL'.",
        "subitems" => [array(
            "key" => "WIZARD_MIGRATE_DB",
            "desc" => "Migrate data from cubeSQL (DSM6)"
        )]
    )]
);
\$WIZARD = [];
if ( !file_exists("/var/packages/cubeSQL/etc/cubeSQL.ini") ) {
    # Storage location already set.
    array_push(\$WIZARD, \$STEP1);
}
array_push(\$WIZARD, \$STEP2);

if ( is_dir("\$preVerPath/databases") && is_dir("\$preVerPath/settings")) {
    # Previous DSM6 data structure identified. Append Migration Step
    array_push(\$WIZARD, \$STEP3);
}

echo json_encode(\$WIZARD);
?>
EOF

WIZARD_STEPS=$(/usr/bin/php -n /tmp/wizard.php)
if [ ${#WIZARD_STEPS} -gt 5 ]; then
    echo $WIZARD_STEPS > $SYNOPKG_TEMP_LOGFILE
fi
  rm /tmp/wizard.php
exit 0
