#!/bin/bash

APACHE_SITES_ROOT="/etc/apache2/sites-available"
APACHE_SITES_DEFAULT_CONF="/etc/apache2/sites-available/000-default.conf"
APACHE_PROJECT_ROOT="/var/www"

strcontains() {
    text=$1
    string=$2

    [[ $text == *"$string"* ]] && echo 1 || echo 0
}

issiterunning() {
    projectname=$1

    printf '%s\n' "$(strcontains "$(a2query -s 2>/dev/null)" "$projectname")"
}

isprojectexists() {
    proj_conf_file_path="$APACHE_SITES_ROOT/$1.conf"

    [[ -e $proj_conf_file_path ]] && echo 1 || echo 0
}

currentrunningproject() {
    for project in $APACHE_SITES_ROOT; do
        if [ "$(issiterunning "$project")" -eq 1 ]; then
            printf '%s\n' "$projectname"
            exit
        fi
    done
}

stopproject() {
    projectname=$1

    sudo a2dissite "$projectname" -q
}

startproject() {
    projectname=$1

    sudo a2ensite "$projectname" -q
}

restartapache() {
    sudo service apache2 restart
}

if [ $# -eq 0 ]; then
    echo "Welcome to the Apache Project Manager (APM)"
    echo
    echo "Commands:"
    echo "create <project name>: Create a project with the given name"
    echo "delete <project name>: Delete a specific project."
    echo "list: List all available projects and your current status."
    echo "start <project name>: Start a specific project."
    echo "stop <project name>: Stop a specific project."
    echo "restart: Restart the apache service."
    exit
fi

if [ "$1" = "create" ]; then
    if [ $# -eq 1 ]; then
        echo "Valid command:"
        echo "create <project name>"
        exit
    fi

    PROJECT_FOLDER="$APACHE_PROJECT_ROOT/$2"
    PROJECT_CONF_FILE="$APACHE_SITES_ROOT/$2.conf"

    sudo cp "$APACHE_SITES_DEFAULT_CONF" "$PROJECT_CONF_FILE"
    sudo chown -R "$USER":"$USER" "$PROJECT_CONF_FILE"
    mkdir "$PROJECT_FOLDER"

    echo "<VirtualHost *:80>
    ServerName $2
    ServerAlias $2

    DocumentRoot $PROJECT_FOLDER
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" | sudo tee "$PROJECT_CONF_FILE" >/dev/null

    echo "Project \"$2\" successful created"

elif [ "$1" = "delete" ]; then
    if [ $# -eq 1 ]; then
        echo "Valid command:"
        echo "delete <project name>"
        exit
    fi

    if [ "$(isprojectexists "$2")" -eq 0 ]; then
        echo "Does not exists \"$2\" project"
        exit
    fi

    read -p "Are you sure do you want delete \"$2\" project? (y/N): " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit
    fi
    echo

    CURRENT_RUNNING_PROJECT=$(currentrunningproject)

    if [ "$CURRENT_RUNNING_PROJECT" == "$2" ]; then
        stopproject "$2" &>/dev/null
    fi

    PROJECT_FOLDER="$APACHE_PROJECT_ROOT/$2"
    PROJECT_CONF_FILE="$APACHE_SITES_ROOT/$2.conf"

    sudo rm -fr "$PROJECT_FOLDER" "$PROJECT_CONF_FILE"

    echo "Project \"$2\" successful deleted"

elif [ "$1" = "list" ]; then
    echo "Projects:"
    echo
    for project in "$APACHE_SITES_ROOT"/*.conf; do
        filename=${project##*/}
        projectname=${filename%%.*}

        if [ "$(issiterunning "$projectname")" -eq 1 ]; then
            echo "$projectname: <RUNNING>"
        else
            echo "$projectname"
        fi
    done

elif [ "$1" = "start" ]; then
    if [ $# -eq 1 ]; then
        echo "Valid command:"
        echo "start <project name>"
    fi

    if [ "$(isprojectexists "$2")" -eq 0 ]; then
        echo "Does not exists \"$2\" project"
        exit
    fi

    CURRENT_RUNNING_PROJECT=$(currentrunningproject)

    if [ -n "$CURRENT_RUNNING_PROJECT" ]; then
        stopproject "$CURRENT_RUNNING_PROJECT" &>/dev/null
    fi

    startproject "$2" -q &>/dev/null
    restartapache

    echo "Project \"$2\" successful started"

elif [ "$1" = "stop" ]; then
    if [ $# -eq 1 ]; then
        echo "Valid command:"
        echo "stop <project name>"
    fi

    if [ "$(isprojectexists "$2")" -eq 0 ]; then
        echo "Does not exists \"$2\" project"
        exit
    fi

    CURRENT_RUNNING_PROJECT=$(currentrunningproject)

    if [ -z "$CURRENT_RUNNING_PROJECT" ]; then
        echo "No one project are running"
        exit
    elif [ "$CURRENT_RUNNING_PROJECT" != "$2" ]; then
        echo "Project \"$2\" isn't running"
        exit
    fi

    stopproject "$2" &>/dev/null
    restartapache

    echo "Project \"$2\" successful stoped"

elif [ "$1" = "restart" ]; then
    restartapache

    echo "Apache successful restarted"

else
    echo "The command \"$*\" does not exists"

fi
