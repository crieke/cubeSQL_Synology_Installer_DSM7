#!/bin/bash
whoami > /tmp/wai.txt
currentDir="$(dirname "$0")"
preVerPath="$(${currentDir}/../scripts/getsharelocation cubeSQL)"
/bin/cat > /tmp/wizard.php <<EOF
<?php
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

# Check if Migration step for DSM6 should be shown. This should only appear, if 
#   - no cubeSQL.ini file has been found
#   - cubeSQL shared folder has been identified
#   - no additional cubeSQL folder (introduced in DSM7 install) is available or it can't be accessed due to privileges.

if ( !file_exists("/var/packages/cubeSQL/etc/cubeSQL.ini") && is_dir("$preVerPath") && !is_dir("$preVerPath/cubeSQL")) {
    # Previous DSM6 data structure identified. Append Migration Step
    array_push(\$WIZARD, \$STEP2);
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
