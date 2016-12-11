# Static parameters
WORKSPACE=./
BOX_PLAYBOOK=$WORKSPACE/box_bootstrap.yml
BOX_NAME=sixteen
BOX_ADDRESS=178.62.233.174
BOX_USER=slavko
BOX_PWD=

prudentia ssh <<EOF
unregister $BOX_NAME
register
$BOX_PLAYBOOK
$BOX_NAME
$BOX_ADDRESS
$BOX_USER
$BOX_PWD
verbose 4
set box_address $BOX_ADDRESS
provision $BOX_NAME
EOF
