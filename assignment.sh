#!/usr/bin/env bash

# TODO Write down your name and studentnumber of the author(s)
# Jimmy Tran (1052827)
# Joel Verveer (1062069)

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
        sudo apt-get autoremove -y
        if [ $? -ne 0 ]; then
            handle_error "Error: failed to autoremove packages"
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
    installation_directory=$HOME$INSTALL_DIR

        sub_dirs=("minecraft" "spigotserver")
        for dir in "${sub_dirs[@]}"; do
            if [ ! -d "$installation_directory/$dir" ]; then
                echo "$dir does not exist in the apps directory. Creating..."
                mkdir "$installation_directory/$dir"
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
            wget -P $installation_directory/minecraft $minecraft_url
            if [ $? -ne 0 ]; then
                rollback_minecraft
            fi
            sudo gdebi -n $installation_directory/minecraft/Minecraft.deb
            if [ $? -ne 0 ]; then
                rollback_minecraft
            fi
            ;;
        spigotserver)
            install_dir="$installation_directory/spigotserver"

            # Create the installation directory if it doesn't exist
            if [ ! -d "$install_dir" ]; then
                echo "Creating installation directory at $install_dir"
                mkdir -p "$install_dir"
                if [ $? -ne 0 ]; then
                    rollback_spigotserver
                    handle_error "Failed to create installation directory at $install_dir"
                fi
            fi

            # Download BuildTools.jar to the installation directory
            wget -P "$install_dir" "$buildtools_url"
            if [ $? -ne 0 ]; then
                rollback_spigotserver
                handle_error "Failed to download BuildTools"
            fi

            current_dir=$(pwd)
            # Save the current working directory and change to the installation directory
            cd "$install_dir" > /dev/null
            if [ $? -ne 0 ]; then
                rollback_spigotserver
                handle_error "Failed to change directory to $install_dir"
            fi

            java -jar "BuildTools.jar" --final-name spigot.jar
            if [ $? -ne 0 ]; then
                rollback_spigotserver
                handle_error "Failed to execute BuildTools"
            fi

            # Return to the previous working directory
            cd "$current_dir" > /dev/null
            if [ $? -ne 0 ]; then
                rollback_spigotserver
                handle_error "Failed to return to the previous working directory"
            fi

            # TODO SPIGOTSERVER
            # Define the source path to spigotstart.sh
            source_path="spigotstart.sh"

            # Check if the file exists
            if [ ! -f "$source_path" ]; then
                rollback_spigotserver
                handle_error "spigotstart.sh file not found at $source_path"
            fi

            # Copy spigotstart.sh to the installation directory
            cp "$source_path" "$install_dir/spigotstart.sh"
            if [ $? -ne 0 ]; then
                rollback_spigotserver
                handle_error "Failed to copy spigotstart.sh to $install_dir"
            fi

            # Provide the user with execute permission for the script
            chmod +x "$install_dir/spigotstart.sh"
            if [ $? -ne 0 ]; then
                rollback_spigotserver
                handle_error "Failed to provide execute permission for spigotstart.sh"
            fi

            current_dir=$(pwd)
            cd "$install_dir"

            # this will print an error because EULA is not true
            ./spigotstart.sh

            cd "$current_dir"

            # fix the error by setting EULA = true
            echo "Accepting EULA"
            echo "eula=true" > "$install_dir/eula.txt"
            if [ $? -ne 0 ]; then
                handle_error "Unable to accept eula."
            fi


            # Create the spigot service
            create_spigotservice

            # Configure the spigot server
            configure_spigotserver

            ;;
        *)
            handle_error "Invalid package: $package_to_install"
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
    if ! sudo ufw --version > /dev/null; then
        echo "ufw is not installed. Installing..."
        install_with_apt ufw
        if [ $? -ne 0 ]; then
            rollback_spigotserver
            handle_error "Failed to install ufw"
        fi
    fi
    
    sudo ufw enable
    if [ $? -ne 0 ]; then
        rollback_spigotserver
        handle_error "Failed to enable ufw"
    fi
    # TODO allow SSH port with ufw allow OpenSSH
        # use ufw to allow the port that is specified in dev.conf for the Spigot server to accept connections
    sudo ufw allow OpenSSH
    if [ $? -ne 0 ]; then
        rollback_spigotserver
        handle_error "Failed to allow OpenSSH"
    fi

    sudo ufw allow $SPIGOTSERVER_PORT
    if [ $? -ne 0 ]; then
        rollback_spigotserver
        handle_error "Failed to allow Spigot server port"
    fi

    # TODO configure spigotserver to run creative gamemode instead of survival
        # this can be done by running the sed command on the (automatically generated) file server.properties
        # (https://minecraft.fandom.com/wiki/Server.properties)
        # with the argument 's/\(gamemode=\)survival/\1creative/'
    server_properties_file="${HOME}$INSTALL_DIR/spigotserver/server.properties"

    # Modify server.properties file to set gamemode to creative
    if [ -f "$server_properties_file" ]; then
        sed -i 's/\(gamemode=\)survival/\1creative/' "$server_properties_file"
        if [ $? -ne 0 ]; then
            rollback_spigotserver
            handle_error "Failed to configure gamemode in server.properties"
        fi
    else
        handle_error "server.properties file not found at $server_properties_file"
    fi
    # TODO restart the spigot service
    sudo systemctl restart spigot
    if [ $? -ne 0 ]; then
        rollback_spigotserver
        handle_error "Failed to restart Spigot service"
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
        rollback_spigotserver
        handle_error "Failed to copy spigot.service"
    fi
    # TODO reload the service daemon (systemctl daemon-reload)
    sudo systemctl daemon-reload
    if [ $? -ne 0 ]; then
        rollback_spigotserver
        handle_error "Failed to reload the service daemon"
    fi
    # TODO enable the service using systemctl
    sudo systemctl enable spigot
    if [ $? -ne 0 ]; then
        rollback_spigotserver
        handle_error "Failed to enable spigot.service"
    fi

    sudo systemctl start spigot
    if [ $? -ne 0 ]; then
        rollback_spigotserver
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
    # Check if the error argument is empty
    if [ -z "$error" ]; then
        echo "Error: No error message provided"
    else
      # TODO print a specific error message
      echo "Error: $error"
    fi
    # TODO exit this function with an integer value!=0
    exit 1
}


# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function rollback_minecraft() {
    # Do NOT remove next line!
    echo "function rollback_minecraft"

    # Check if Minecraft Launcher is installed before trying to remove it
    if dpkg -l | grep -q minecraft-launcher; then
        # Uninstall Minecraft
        sudo apt remove -y minecraft-launcher
        if [ $? -ne 0 ]; then
            handle_error "Failed to remove Minecraft Launcher"
        fi
    fi

    # Check if the downloaded Minecraft package exists before trying to remove it
    if [ -f $HOME$INSTALL_DIR/minecraft/Minecraft.deb ]; then
        # Remove the downloaded Minecraft package
        rm -f $HOME$INSTALL_DIR/minecraft/Minecraft.deb
        if [ $? -ne 0 ]; then
            handle_error "Failed to remove Minecraft.deb"
        fi
    fi

    # Check if the Minecraft directory exists before trying to remove it
    if [ -d $HOME$INSTALL_DIR/minecraft ]; then
        # Remove the Minecraft directory
        rm -rf $HOME$INSTALL_DIR/minecraft
        if [ $? -ne 0 ]; then
            handle_error "Failed to remove Minecraft directory"
        fi
    fi
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function rollback_spigotserver {
    # Do NOT remove next line!
    echo "function rollback_spigotserver"

    # Stop the Spigot service
    sudo systemctl stop spigot.service
    if [ $? -ne 0 ]; then
        handle_error "Failed to stop Spigot service"
    fi

    # Disable the Spigot service
    if [ -f "/etc/systemd/system/spigot.service" ]; then
        sudo systemctl disable spigot.service
        if [ $? -ne 0 ]; then
            handle_error "Failed to disable Spigot service"
        fi
        sudo rm -rf "/etc/systemd/system/spigot.service"
        if [ $? -ne 0 ]; then
            handle_error "Failed to remove spigot.service file"
        fi
        sudo systemctl daemon-reload
        if [ $? -ne 0 ]; then
            handle_error "Failed to reload system daemon"
        fi
    fi

    # rollback for ufw commands
    sudo ufw disable
    if [ $? -ne 0 ]; then
        handle_error "Failed to disable ufw"
    fi
    sudo ufw delete allow "$SPIGOTSERVER_PORT"
    if [ $? -ne 0 ]; then
        handle_error "Failed to delete allow $SPIGOTSERVER_PORT"
    fi
    sudo ufw delete allow OpenSSH
    if [ $? -ne 0 ]; then
        handle_error "Failed to delete allow OpenSSH"
    fi
    # Remove the spigotserver directory
    if [ -d "$HOME$INSTALL_DIR/spigotserver" ]; then
        rm -rf $HOME/apps/spigotserver
        if [ $? -ne 0 ]; then
            handle_error "Failed to remove spigotserver directory"

        fi
    fi

}


# UNINSTALL

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_minecraft {
    # Do NOT remove next line!
    echo "function uninstall_minecraft"

    # TODO remove the directory containing minecraft
    if [ -d "$HOME/MinecraftLauncher.1000" ]; then
        echo "Found MinecraftLauncher folder trying to delete it.."
        rm -rf $HOME/MinecraftLauncher.1000
        if [ $? -ne 0 ]; then
            handle_error "Failed to remove MinecraftLauncher folder"
        fi
    fi

    if [ -d ~/.minecraft ]; then
        echo "Found the .minecraft folder"
        rm -rf ~/.minecraft
        if [ $? -ne 0 ]; then
            handle_error "Failed to delete .minecraft"
        fi
    fi

    # TODO if something goes wrong then call function handle_error
    if dpkg -l | grep -q minecraft-launcher; then
        echo "Minecraft-launcher package is installed"
        sudo apt remove -y minecraft-launcher
        if [ $? -ne 0 ]; then
            handle_error "Failed to remove Minecraft launcher"
        fi
    fi
    # Remove the directory containing Minecraft
    if [ -d "$HOME$INSTALL_DIR/minecraft" ]; then
        echo "Found Minecraft folder trying to delete it.."
        rm -rf $HOME$INSTALL_DIR/minecraft
        if [ $? -ne 0 ]; then
            handle_error "Failed to remove Minecraft directory"
        fi
    fi

}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_spigotserver() {
    # Do NOT remove next line!
    echo "uninstall_spigotserver"

    # Define the installation directory for the Spigot server
    install_dir="${HOME}$INSTALL_DIR/spigotserver"

    # Remove the directory containing the Spigot server
    if [ -d "$install_dir" ]; then
        echo "Removing Spigot server directory: $install_dir"
        rm -rf "$install_dir"
        if [ $? -ne 0 ]; then
            handle_error "Failed to remove Spigot server directory at $install_dir"
        fi
    else
        echo "Spigot server directory not found at $install_dir"
    fi

    # Uninstall the Spigot service by calling the uninstall_spigotservice function
    uninstall_spigotservice
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_spigotservice {
    # Do NOT remove next line!
    echo "uninstall_spigotservice"

    sudo systemctl stop spigot
    if [ $? -ne 0 ]; then
        handle_error "Failed to stop spigot.service"
    fi

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

    sudo systemctl daemon-reload
    if [ $? -ne 0 ]; then
        handle_error "Failed to reload the service daemon"
    fi
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
    dependencies=("gdebi" "wget" "make" "curl" "ufw" "openjdk-17-jre" "git")
    for dep in "${dependencies[@]}"; do
        # check if dependency exists
        if command -v "$dep" > /dev/null 2>&1; then
            echo "Uninstalling $dep..."
            sudo apt-get remove -y "$dep"
            if [ $? -ne 0 ]; then
                handle_error "Failed to uninstall $dep"
            fi
        else
            echo "$dep is not installed, skipping..."
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

    # Delete previous log file for launcher so there will be only one launcher_log.txt when starting mc
    # Check if the launcher_log.txt file exists
    if [ -f ~/.minecraft/launcher_log.txt ]; then
        # Delete the launcher_log.txt file
        find ~/.minecraft -type f -name 'launcher_log.txt' -delete
    else
        echo "No launcher_log.txt file found"
    fi

    # Start minecraft
    # TODO(done) Start minecraft
    if ! command -v minecraft-launcher &> /dev/null; then
        handle_error "minecraft-launcher command not found"
    fi

    minecraft-launcher > /dev/null 2>&1 &
    minecraft_pid=$!

    # Wait for a moment to allow Minecraft to start
    sleep 10

    # Check if Minecraft started successfully
    if ! ps -p $minecraft_pid > /dev/null; then
        handle_error "Failed to start Minecraft"
    fi
    echo "Minecraft launcher started successfully"

    # Check if minecraft is working correctly
    latest_log=$(ls -rt ~/.minecraft/launcher_log.txt | head -n 1)
    if [ -z "$latest_log" ]; then
        echo "No log file found for the launcher"
    else
        if grep -q "Error" "$latest_log"; then
            if pgrep -f "minecraft-launcher" > /dev/null; then
                echo "Killing Minecraft launcher process"
                kill $minecraft_pid
                if [ $? -ne 0 ]; then
                    handle_error "Failed to kill Minecraft launcher process & MInecraft started with an error."
                fi
                else
                    echo "Minecraft launcher process not found"
                fi
            handle_error "Minecraft started with an error"
        else
            echo "Minecraft started with no errors"
        fi
    fi

    # Stop minecraft after testing
    if pgrep -f "minecraft-launcher" > /dev/null; then
        echo "Killing Minecraft launcher process"
        kill $minecraft_pid
        if [ $? -ne 0 ]; then
            handle_error "Failed to kill Minecraft launcher process"
        fi
    else
        echo "Minecraft launcher process not found"
    fi

}

function test_spigotserver() {
    # Do NOT remove next line!
    echo "function test_spigotserver"

    # define variables
    service_name="spigot.service"
    install_dir="$HOME$INSTALL_DIR/spigotserver"
    spigotserver_port=$SPIGOTSERVER_PORT

    # TODO Start the spigotserver
    echo "Starting the Spigot server..."
    cd "$install_dir"
    if [ $? -ne 0 ]; then
        handle_error "Failed to navigate to install dir"
    fi
    java -jar spigot.jar -nogui > /dev/null &
    spigot_pid=$!
    echo "Waiting for the startup"
    sleep 15

    # TODO Check if spigotserver is working correctly
        # e.g. by checking if the API responds
        # if you need curl or aNOTher tool, you have to install it first
    curl -s "localhost:$spigotserver_port"
    curl_result="$?"
    if [[ ! "$curl_result" == "52" ]]; then
        if ps -ef | grep $spigot_pid | grep -v grep > /dev/null; then
            kill -9 "$spigot_pid"
        fi
        handle_error "Spigot does not seem to be working correctly"
    fi

    # TODO Stop the spigotserver after testing

    echo "Stopping the Spigot server..."
    sudo systemctl stop "$service_name"
    if [ $? -ne 0 ]; then
        echo "Failed to stop the Spigot server normally"

        # use the kill signal only if the spigotserver canNOT be stopped normally
        pid=$(pgrep -f spigot)
        if [ -n "$pid" ]; then
            echo "Forcing Spigot server to stop using kill signal..."
            sudo kill "$pid"
            if [ $? -ne 0 ]; then
                handle_error "Failed to kill Spigot server process"
            fi
        fi
    fi

}

function setup() {
    # Do NOT remove next line!
    echo "function setup"

    # Define the dependencies
    dependencies=("gdebi" "wget" "make" "curl" "openjdk-17-jre" "git")

    # Check and install dependencies
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" > /dev/null 2>&1; then
            echo "$dep is not installed. Installing..."
            # Install the dependency using apt
            install_with_apt $dep
            if [ $? -ne 0 ]; then
                handle_error "Failed to install $dep"
            fi
        else
            echo "$dep is already installed"
        fi
    done

    # Define the installation directory and necessary files
    install_dir="$HOME$INSTALL_DIR"
    sub_dirs=("minecraft" "spigotserver")

    # Check and create the installation directory
    if [ ! -d "$install_dir" ]; then
        echo "Installation directory does not exist. Creating..."
        mkdir -p "$install_dir"
        if [ $? -ne 0 ]; then
            handle_error "Failed to create installation directory"
        fi
    fi

    # Check and create the necessary subdirectories
    for dir in "${sub_dirs[@]}"; do
        if [ ! -d "$install_dir/$dir" ]; then
            echo "$dir does not exist in the installation directory. Creating..."
            mkdir -p "$install_dir/$dir"
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
                    install_package $arg1
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
                    install_package $arg1
                    ;;
                --test)
                    test_spigotserver
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
