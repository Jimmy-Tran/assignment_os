#!/usr/bin/env bash

# TODO Write down your name and studentnumber of the author(s)
# Jimmy Tran (1052827)

# Global variables
# TODO Define (only) the variables which require global scope

source dev.conf

# INSTALL

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function install_with_apt() {
    # Do NOT remove next line!
    echo "function install_with_apt"

    package=$1
    # TODO
        # add apt update to
        sudo apt-get update
        if [ $? -ne 0 ]; then
            handle_error "Error: failed to update apt sources list"
        fi
        # add apt command to install the package
        sudo apt-get install -y $package
        if [ $? -ne 0 ]; then
            handle_error "Error: failed to install $package failed"
        fi


    # TODO if something goes wrong then call function handle_error
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function install_package() {
    # Do NOT remove next line!
    echo "function install_package"
    package_to_install=$1
    # TODO read the arguments from $@
        # Make sure NOT to use empty argument values

        if [ -z $package_to_install ]; then
            handle_error "Error: package_to_install is empty"
        fi

    # TODO make sure the following dependencies have been installed
        # BuildTools (https://hub.spigotmc.org/jenkins/job/BuildTools/)
        # gdebi (https://manpages.debian.org/buster/gdebi-core/gdebi.1.en.html)
        # wget

    minecraft_url=$MINECRAFT_URL
    buildtools_url=$BUILDTOOLS_URL

        sub_dirs=("minecraft" "spigotserver")
        for dir in "${sub_dirs[@]}"; do
            if [ ! -d "tmp/apps/$dir" ]; then
                echo "$dir does nost exist in the apps directory. Creating..."
                mkdir "/tmp/apps/$dir"
                if [ $? -ne 0 ]; then
                    handle_error "Failed to create $dir directory"
                fi
            else
                echo "$dir already exists in the apps directory"
            fi
        done

    case $package_to_install in
        minecraft)
            # Download and install the Minecraft package
            wget -P tmp/apps/minecraft $minecraft_url
            if [ $? -ne 0 ]; then
                handle_error "Failed to download Minecraft"
            fi
            sudo gdebi -n tmp/apps/minecraft/Minecraft.deb
            if [ $? -ne 0 ]; then
                handle_error "Failed to install Minecraft"
            fi
            ;;
        spigotserver)
            # Download and execute the BuildTools.jar file to compile the Spigot server
            wget -P tmp/apps/spigotserver $buildtools_url
            if [ $? -ne 0 ]; then
                handle_error "Failed to download BuildTools"
            fi
            java -jar tmp/apps/spigotserver/BuildTools.jar
            if [ $? -ne 0 ]; then
                handle_error "Failed to execute BuildTools"
            fi
            # Create the Spigot service
            create_spigotservice
            ;;
        *)
            handle_error "Invalid package: $package_to_install"
            return 1
            ;;
    esac




    # TODO Install required packages with APT
        # add apt command to update apt sources list
        # add apt command to install the package

    # TODO General
        # the URLS needed to download installation files must be read automatically from dev.conf
        # the logic for downloading from a URL and installing the application with the installationfile with the proper installation tool
        # specific actions that need to be taken for a specific application during this process should be handled in a separate if-else or switch statement
        # every intermediate steps need to be handeld carefully. error handeling should be dealt with using handle_error() and/or rolleback()
        # if a file is downloaded but canNOT be installed, a rollback is needed to be able to start from scratch
        # create a specific installation folder for the current package
        # make sure to provide the user with sufficient permissions to this folder
        # make sure to handle every intermediate mistake and rollback if something goes wrong like permission erros and unreachble URL etc.

    # TODO application specific logic
    # based on the name of the application additional steps might be needed

        # TODO SPIGOTSERVER
        # Copy spigotstart.sh to ${HOME}/apps/spigotserver and provide the user with execute permission
        # spigotserver will be stored into ${HOME}/apps/spigotserver

        # TODO MINECRAFT
        # Download minecraft.deb and install it with gdebi

    # TODO if something goes wrong then call function handle_error

}


# CONFIGURATION

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function configure_spigotserver() {
    # Do NOT remove next line!
    echo "function configure_spigotserver"

    # TODO Configure Firewall
        # make sure ufw has been installed
        if ! dpkg -l | grep -q ufw; then
            echo "ufw is not installed. Installing..."
            install_with_apt ufw
            if [ $? -ne 0 ]; then
                handle_error "Failed to install ufw"
            fi
        fi
    # TODO allow SSH port with ufw allow OpenSSH
        # use ufw to allow the port that is specified in dev.conf for the Spigot server to accept connections
        # make sure ufw has been enabled
      sudo ufw allow OpenSSH
      if [ $? -ne 0 ]; then
          handle_error "Failed to allow OpenSSH"
      fi

          sudo ufw allow $SPIGOTSERVER_PORT
          if [ $? -ne 0 ]; then
              handle_error "Failed to allow Spigot server port"
          fi
              sudo ufw enable
              if [ $? -ne 0 ]; then
                  handle_error "Failed to enable ufw"
                  return 1
              fi
    # TODO configure spigotserver to run creative gamemode instead of survival
        # this can be done by running the sed command on the (automatically generated) file server.properties
        # (https://minecraft.fandom.com/wiki/Server.properties)
        # with the argument 's/\(gamemode=\)survival/\1creative/'
    sed -i 's/\(gamemode=\)survival/\1creative/' server.properties
    if [ $? -ne 0 ]; then
        handle_error "Failed to configure Spigot server gamemode"
        return 1
    fi
    # TODO restart the spigot service
    if [ $? -ne 0 ]; then
        handle_error "Failed to restart Spigot service"
        return 1
    fi
    # TODO if something goes wrong then call function handle_error

}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function create_spigotservice() {
    # Do NOT remove next line!
    echo "function create_spigotservice"

    # TODO copy spigot.service to /etc/systemd/system/spigot.service
    sudo cp spigot.service /etc/systemd/system/spigot.service
    if [ $? -ne 0 ]; then
        handle_error "Failed to copy spigot.service"
    fi
    # TODO reload the service daemon (systemctl daemon-reload)
    sudo systemctl daemon-reload
    if [ $? -ne 0 ]; then
        handle_error "Failed to reload the service daemon"
    fi
    # TODO enable the service using systemctl
      sudo systemctl enable spigot.service
      if [ $? -ne 0 ]; then
          handle_error "Failed to enable spigot.service"
      fi
    # TODO if something goes wrong then call function handle_error

}

# ERROR HANDLING

# TODO complete the implementation of this function
function handle_error() {
    # Do NOT remove next line!
    echo "function handle_error"

    # TODO read the arguments from $@
        # Make sure NOT to use empty argument values
    error=$1
    # TODO print a specific error message
    echo "Error: $error"
    # TODO exit this function with an integer value!=0
    exit 1
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function rollback_minecraft() {
    # Do NOT remove next line!
    echo "function rollback_minecraft"
    # Remove the downloaded Minecraft package
    rm -f apps/minecraft/Minecraft.deb
    if [ $? -ne 0 ]; then
        handle_error "Failed to remove Minecraft.deb"
        return 1
    fi

    # Remove the Minecraft directory
    rm -rf apps/minecraft
    if [ $? -ne 0 ]; then
        handle_error "Failed to remove Minecraft directory"
        return 1
    fi
    # TODO if something goes wrong then call function handle_error

}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function rollback_spigotserver {
    # Do NOT remove next line!
    echo "function rollback_spigotserver"

    # TODO if something goes wrong then call function handle_errorfunction rollback_spigotserver {
                                                                          # Do NOT remove next line!
                                                                          echo "function rollback_spigotserver"
                                                                          # Stop the Spigot service
    sudo systemctl stop spigot.service
                                                                          if [ $? -ne 0 ]; then
                                                                              handle_error "Failed to stop Spigot service"
                                                                          fi

                                                                          # Disable the Spigot service
                                                                          sudo systemctl disable spigot.service
                                                                          if [ $? -ne 0 ]; then
                                                                              handle_error "Failed to disable Spigot service"
                                                                          fi

                                                                          # Remove the BuildTools.jar file
                                                                          rm -f apps/spigotserver/BuildTools.jar
                                                                          if [ $? -ne 0 ]; then
                                                                              handle_error "Failed to remove BuildTools.jar"
                                                                          fi

                                                                          # Remove the spigotserver directory
                                                                          rm -rf apps/spigotserver
                                                                          if [ $? -ne 0 ]; then
                                                                              handle_error "Failed to remove spigotserver directory"

                                                                          fi
}


# UNINSTALL

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_minecraft {
    # Do NOT remove next line!
    echo "function uninstall_minecraft"

    # TODO remove the directory containing minecraft

    # TODO if something goes wrong then call function handle_error

    minecraft-launcher --clean
    # Remove the directory containing Minecraft
    rm -rf apps/minecraft
    if [ $? -ne 0 ]; then
        handle_error "Failed to remove Minecraft directory"
    fi

}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_spigotserver {
    # Do NOT remove next line!
    echo "uninstall_spigotserver"

    # TODO remove the directory containing spigotserver

    # TODO create a service by calling the function create_spigotservice

    # TODO if something goes wrong then call function handle_error

}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_spigotservice {
    # Do NOT remove next line!
    echo "uninstall_spigotservice"

    # TODO disable the spigotservice with systemctl disable
    sudo systemctl disable spigot.service
    if [ $? -ne 0 ]; then
        handle_error "Failed to disable spigot.service"
    fi
    # TODO delete /etc/systemd/system/spigot.service
    sudo rm -f /etc/systemd/system/spigot.service
    if [ $? -ne 0 ]; then
        handle_error "Failed to delete spigot.service"
    fi
    # TODO if something goes wrong then call function handle_error

}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function remove() {
    # Do NOT remove next line!
    echo "function remove"

    # Uninstall Minecraft
    uninstall_minecraft
    if [ $? -ne 0 ]; then
        handle_error "Failed to uninstall Minecraft"
    fi

    # Uninstall Spigot server
    uninstall_spigotserver
    if [ $? -ne 0 ]; then
        handle_error "Failed to uninstall Spigot server"
    fi

    # Remove other dependencies
    dependencies=("gdebi" "wget" "make" "curl" "ufw")
    for dep in "${dependencies[@]}"; do
        sudo apt-get remove -y $dep
        if [ $? -ne 0 ]; then
            handle_error "Failed to remove $dep"
        fi
    done

    # Autoremove remaining unnecessary packages
    sudo apt-get autoremove -y
    if [ $? -ne 0 ]; then
        handle_error "Failed to autoremove packages"

    fi
}


# TEST

# TODO complete the implementation of this function
function test_minecraft() {
    # Do NOT remove next line!
    echo "function test_minecraft"

    # TODO Start minecraft

    # TODO Check if minecraft is working correctly
        # e.g. by checking the logfile

    # TODO Stop minecraft after testing
        # use the kill signal only if minecraft canNOT be stopped normally

}

function test_spigotserver() {
    # Do NOT remove next line!
    echo "function test_spigotserver"

    # TODO Start the spigotserver

    # TODO Check if spigotserver is working correctly
        # e.g. by checking if the API responds
        # if you need curl or aNOTher tool, you have to install it first

    # TODO Stop the spigotserver after testing
        # use the kill signal only if the spigotserver canNOT be stopped normally

}

function setup() {
    # Do NOT remove next line!
    echo "function setup"

    # Define the dependencies
    dependencies=("gdebi" "wget" "make" "curl")

    # Check and install dependencies
    for dep in "${dependencies[@]}"; do
        if ! command -v "$p" > /dev/null 2>&1; then
            echo "$dep is not installed. Installing..."
            install_with_apt $dep
            if [ $? -ne 0 ]; then
                handle_error "Failed to install $dep"
            fi
        else
            echo "$dep is already installed"
        fi
    done

    # Define the installation directory and necessary files
    install_dir="/tmp/apps"
    sub_dirs=("minecraft" "spigotserver")

    # Check and create the installation directory
    if [ ! -d $install_dir ]; then
        echo "Installation directory does not exist. Creating..."
        mkdir $install_dir
        if [ $? -ne 0 ]; then
            handle_error "Failed to create installation directory"
        fi
    fi

    # Check and create the necessary subdirectories
    for dir in "${sub_dirs[@]}"; do
        if [ ! -d "$install_dir/$dir" ]; then
            echo "$dir does not exist in the installation directory. Creating..."
            mkdir "$install_dir/$dir"
            if [ $? -ne 0 ]; then
                handle_error "Failed to create $dir directory"
            fi
        else
            echo "$dir already exists in the installation directory"
        fi
    done
}

function main() {
    # Do NOT remove next line!
    echo "function main"

    # Read the arguments from $@
    # Make sure NOT to use empty argument values
    arg1=$1
    arb2=$2
    if [ -z $arg1 ]; then
        handle_error "Error: No action specified"
    fi

    # Use a case statement to execute the appropriate function
    case $arg1 in
        setup)
            # Creates the installation directory and installs all required dependencies
            setup
            ;;
        remove)
            # Removes installation directory and uninstalls all required dependencies
            remove
            ;;
        minecraft)
            # Specifies the one of the following actions for minecraft
            minecraft_action=$2
            case $minecraft_action in
                --install)
                    install_package
                    ;;
                --test)
                    test_minecraft
                    ;;
                --uninstall)
                    uninstall_minecraft
                    ;;
                *)
                    handle_error "Error: Invalid action for minecraft: $minecraft_action"

                    ;;
            esac
            ;;
        spigotserver)
            # Specifies the one of the following actions for spigot
            spigot_action=$2
            case $spigot_action in
                --install)
                    install_spigot
                    ;;
                --test)
                    test_spigot
                    ;;
                --uninstall)
                    uninstall_spigot
                    ;;
                *)
                    handle_error "Error: Invalid action for spigot: $spigot_action"
                    ;;
            esac
            ;;
        *)
            handle_error "Error: Invalid action: $action"
            ;;
    esac
}

main "$@"