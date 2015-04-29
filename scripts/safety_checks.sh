# Make sure monkii-multi-keypair.pem exists
if [ ! -f ~/.ssh/monkii-multi-keypair.pem ]; then
    echo ""
    echo "~/.ssh/monkii-multi-keypair.pem does not exist. Please add this file and then try again."
    echo ""
    exit
fi

# Make sure ssh config exists
if [ ! -f ~/.ssh/config ]; then
    echo ""
    echo "~/.ssh/config does not exist. Please add this file with an entry for chimchim and then try again."
    echo ""
    exit
fi

# Make sure lock not in place
LOCK_FILE="/tmp/${SITE_NAME}.lock"
if ssh chimchim stat $LOCK_FILE \> /dev/null 2\>\&1
  then
    echo "Lock in place. Quitting."
    exit
fi
