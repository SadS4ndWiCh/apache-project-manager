#!/bin/bash

strcontains() {
    TEXT=$1
    STRING=$2

    if [[ $TEXT == *"$STRING"* ]]; then
        echo 1
        exit
    fi

    echo 0
}

issiterunning() {
    SITE=$1

    echo $(strcontains "$(a2query -s 2>/dev/null)" "$SITE")
}

isprojectexists() {
    PROJECT_CONF_FILE="$APACHE_SITES_ROOT/$1.conf"

    if [ -e $PROJECT_CONF_FILE ]; then
        echo 1
        exit
    fi

    echo 0
}

currentrunningproject() {
    for PROJECT in $(ls $APACHE_SITES_ROOT); do
        PROJECT_NAME=$(echo $PROJECT | sed 's/\.conf$//')

        if [ $(issiterunning $PROJECT_NAME) -eq 1 ]; then
            echo $PROJECT_NAME
            exit
        fi
    done
}

stopproject() {
    PROJECT_NAME=$1

    sudo a2dissite "$PROJECT_NAME" -q
}

startproject() {
    PROJECT_NAME=$1

    sudo a2ensite "$PROJECT_NAME" -q
}

APACHE_SITES_ROOT="/etc/apache2/sites-available"
APACHE_SITES_DEFAULT_CONF="/etc/apache2/sites-available/000-default.conf"
APACHE_PROJECT_ROOT="/var/www"

if [ $# -eq 0 ]; then
    echo "Invalid"
    exit
fi

if [ $1 = "create" ]; then
    if [ $# -eq 1 ]; then
        echo "Valid command:"
        echo "$0 create <project name>"
        exit
    fi

    PROJECT_FOLDER="$APACHE_PROJECT_ROOT/$2"
    PROJECT_CONF_FILE="$APACHE_SITES_ROOT/$2.conf"

    sudo cp $APACHE_SITES_DEFAULT_CONF $PROJECT_CONF_FILE
    sudo chown -R $USER:$USER $PROJECT_CONF_FILE
    mkdir $PROJECT_FOLDER

    sudo echo "<VirtualHost *:80>
    ServerName $2
    ServerAlias $2

    DocumentRoot $PROJECT_FOLDER
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" >$PROJECT_CONF_FILE

    echo "Project \"$2\" successful created"

elif [ $1 = "delete" ]; then
    if [ $# -eq 1 ]; then
        echo "Valid command:"
        echo "$0 delete <project name>"
        exit
    fi

    if [ $(isprojectexists $2) -eq 0 ]; then
        echo "Does not exists \"$2\" project"
        exit
    fi

    read -p "Are you sure do you want delete \"$2\" project? (y/N): " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit
    fi
    echo

    CURRENT_RUNNING_PROJECT=$(currentrunningproject)

    if [ $CURRENT_RUNNING_PROJECT == $2 ]; then
        stopproject $2 &>/dev/null
    fi

    PROJECT_FOLDER="$APACHE_PROJECT_ROOT/$2"
    PROJECT_CONF_FILE="$APACHE_SITES_ROOT/$2.conf"

    sudo rm -fr $PROJECT_FOLDER $PROJECT_CONF_FILE

    echo "Project \"$2\" successful deleted"

elif [ $1 = "list" ]; then
    echo "Projects:"
    echo
    for PROJECT in $(ls $APACHE_SITES_ROOT); do
        PROJECT_NAME=$(echo $PROJECT | sed 's/\.conf$//')

        if [ $(issiterunning $PROJECT_NAME) -eq 1 ]; then
            echo "$PROJECT_NAME: <RUNNING>"
        else
            echo "$PROJECT_NAME"
        fi
    done

elif [ $1 = "start" ]; then
    if [ $# -eq 1 ]; then
        echo "Valid command:"
        echo "$0 start <project name>"
    fi

    if [ $(isprojectexists $2) -eq 0 ]; then
        echo "Does not exists \"$2\" project"
        exit
    fi

    CURRENT_RUNNING_PROJECT=$(currentrunningproject)

    if [ -n $CURRENT_RUNNING_PROJECT ]; then
        stopproject $CURRENT_RUNNING_PROJECT &>/dev/null
    fi

    startproject "$2" -q &>/dev/null
    sudo service apache2 restart

    echo "Project \"$2\" successful started"

elif [ $1 = "stop" ]; then
    if [ $# -eq 1 ]; then
        echo "Valid command:"
        echo "$0 stop <project name>"
    fi

    if [ $(isprojectexists $2) -eq 0 ]; then
        echo "Does not exists \"$2\" project"
        exit
    fi

    CURRENT_RUNNING_PROJECT=$(currentrunningproject)

    if [ ! -n $CURRENT_RUNNING_PROJECT ]; then
        echo "No one project are running"
        exit
    elif [ $CURRENT_RUNNING_PROJECT != $2 ]; then
        echo "Project \"$2\" isn't running"
        exit
    fi

    stopproject $2 &>/dev/null
    sudo service apache2 restart

    echo "Project \"$2\" successful stoped"
fi
