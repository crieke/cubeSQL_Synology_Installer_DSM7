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

\$DL_LINKS = json_decode('$DOWNLOAD_LINKS', true);
\$KEEP_ENTRY = array("Keep current version", "KEEP");
array_unshift(\$DL_LINKS, \$KEEP_ENTRY);


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
            "editable" => FALSE,
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
    "step_title" => "Keep current cubeSQL version?",
    "items" => [array(
        "type" => "combobox",
        "desc" => "You can either keep your installed version or change to a different cubeSQL version.",
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
                "data" => \$DL_LINKS
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
        "desc" => "The installation has detected a shared folder 'cubeSQL' on your diskstation. This was the default storage path for cubeSQL on DSM6 systems. If you migrate from DSM6 -> DSM7, you can tick the checkbox below, to migrate the data from your previous cubeSQL environment.<br><br><strong>Info:</strong> This migration is only supported, if you have selected 'cubeSQL' as your storage location in the previous step.",
        "subitems" => [array(
            "key" => "WIZARD_MIGRATE_DB",
            "desc" => "Migrate data from cubeSQL (DSM6)"
        )]
    )]
);
\$WIZARD = [];

# Check if cubeSQL.ini exists. Then a storage location is already been set.
if ( !file_exists("/var/packages/cubeSQL/etc/cubeSQL.ini") ) {
    # Storage location already set.
    array_push(\$WIZARD, \$STEP1);
}

# Ask for different cubeSQL version
array_push(\$WIZARD, \$STEP2);

# Check if Migration step for DSM6 should be shown. This should only appear, if
#   - no cubeSQL.ini file has been found
#   - cubeSQL shared folder has been identified
#   - no additional cubeSQL folder (introduced in DSM7 install) is available or it can't be accessed due to privileges.

if ( !file_exists("/var/packages/cubeSQL/etc/cubeSQL.ini") && is_dir("$preVerPath") && !is_dir("$preVerPath/cubeSQL")) {
    # Previous DSM6 data structure identified. Append Migration Step
    array_push(\$WIZARD, \$STEP3);
}

# In the json_encode() function all "/" in the url are transformed to "\/". the str_replace changes it back.
echo str_replace("\/", "/",json_encode(\$WIZARD));
?>
EOF

WIZARD_STEPS=$(/usr/bin/php -n /tmp/wizard.php)
if [ ${#WIZARD_STEPS} -gt 5 ]; then
    echo $WIZARD_STEPS > $SYNOPKG_TEMP_LOGFILE
fi
rm -f /tmp/wizard.php
exit 0
