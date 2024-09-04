#!/bin/bash


while true; do
  CHOICE=$(whiptail --title "Main Menu" --menu "Choose an option:" 35 70 15 \
  "1" "Add User                   Add a user to the system            " \
  "2" "Modify Name                Modify an existing user             " \
  "3" "Delete User                Delete an existing user             " \
  "4" "Change Password            Change password for a user          " \
  "5" "List User Information      List informantion about user        " \
  "6" "Add Group                  Add group to the system             " \
  "7" "Modify Group               Modify an existing group            " \
  "8" "Delete Group               Delete  an existing group           " \
  "9" "Add User to Group          Add user to an existing group       " \
  "10" "List Users                 List All users on the system        " \
  "11" "List Groups                List All groups on the system       " \
  "12" "Enable User                Unlock the user account             " \
  "13" "Disable User               Lock the user account               " \
  "14" "About                      information about the program       " \
  "15" "Exit" 3>&1 1>&2 2>&3)

  exitstatus=$?
  if [ $exitstatus != 0 ]; then
    break
  fi

  case $CHOICE in
    1)
      while true; do
        USERNAME=$(whiptail --inputbox "Enter the username to add:" 8 39 --title "Add User" 3>&1 1>&2 2>&3)

        # Check if the user already exists
        if id -u "$USERNAME" >/dev/null 2>&1; then
          while true; do
            RANDOM_NUMBER=$(shuf -i 1-99 -n 1)
            NEW_USERNAME="${USERNAME}${RANDOM_NUMBER}"

            if ! id -u "$NEW_USERNAME" >/dev/null 2>&1; then
              break
            fi
          done

          whiptail --yesno "The username '$USERNAME' already exists. Would you like to use the username '${NEW_USERNAME}' instead?" 8 60 --title "User Exists"
          if [ $? -eq 0 ]; then
            USERNAME="${NEW_USERNAME}"
            break
          else
            break
          fi
        else
          break
        fi
      done

      if [ ! -z "$USERNAME" ]; then
        PASSWORD=$(whiptail --passwordbox "Enter a password for the new user:" 8 39 --title "Set Password" 3>&1 1>&2 2>&3)
        CONFIRM_PASSWORD=$(whiptail --passwordbox "Confirm the password:" 8 39 --title "Confirm Password" 3>&1 1>&2 2>&3)

        if [ "$PASSWORD" = "$CONFIRM_PASSWORD" ]; then
          OUTPUT=$(sudo useradd -m "$USERNAME" 2>&1)
          if [ $? -ne 0 ]; then
            whiptail --msgbox "$OUTPUT" 8 39 --title "Error"
          else
            echo "$USERNAME:$PASSWORD" | sudo chpasswd
            whiptail --msgbox "User '$USERNAME' added successfully!" 8 39 --title "Success"
          fi
        else
          whiptail --msgbox "Passwords do not match. User not added." 8 39 --title "Error"
        fi
      fi
      ;;
    2)  # Modify User Name
      USERNAME=$(whiptail --inputbox "Enter the username to modify:" 8 39 --title "Modify User" 3>&1 1>&2 2>&3)
      if id -u "$USERNAME" >/dev/null 2>&1; then
        NEW_USERNAME=$(whiptail --inputbox "Enter the new username:" 8 39 --title "Modify User Name" 3>&1 1>&2 2>&3)
        OUTPUT=$(sudo usermod -l "$NEW_USERNAME" "$USERNAME" 2>&1)
        if [ $? -ne 0 ]; then
          whiptail --msgbox "$OUTPUT" 8 39 --title "Error"
        else
          whiptail --msgbox "User '$USERNAME' renamed to '$NEW_USERNAME' successfully!" 8 39 --title "Success"
        fi
      else
        if (whiptail --yesno "User '$USERNAME' does not exist. Would you like to add this user?" 8 39 --title "User Not Found"); then
          # Ask for password and confirmation
          PASSWORD=$(whiptail --passwordbox "Enter password for the new user:" 8 39 --title "Set Password" 3>&1 1>&2 2>&3)
          CONFIRM_PASSWORD=$(whiptail --passwordbox "Confirm password:" 8 39 --title "Confirm Password" 3>&1 1>&2 2>&3)
          
          if [ "$PASSWORD" != "$CONFIRM_PASSWORD" ]; then
            whiptail --msgbox "Passwords do not match. User not added." 8 39 --title "Error"
          else
            OUTPUT=$(sudo useradd -m -p "$(openssl passwd -1 "$PASSWORD")" "$USERNAME" 2>&1)
            if [ $? -ne 0 ]; then
              whiptail --msgbox "$OUTPUT" 8 39 --title "Error"
            else
              whiptail --msgbox "User '$USERNAME' added successfully!" 8 39 --title "Success"
            fi
          fi
        fi
      fi
      ;;

    3)
      USERNAME=$(whiptail --inputbox "Enter the username to delete:" 8 39 --title "Delete User" 3>&1 1>&2 2>&3)
      OUTPUT=$(sudo userdel "$USERNAME" 2>&1)
      if [ $? -ne 0 ]; then
        whiptail --msgbox "$OUTPUT" 8 39 --title "Error"
      else
        whiptail --msgbox "User '$USERNAME' deleted successfully!" 8 39 --title "Success"
      fi
      ;;
    4)
      USERNAME=$(whiptail --inputbox "Enter the username to change password:" 8 39 --title "Change User Password" 3>&1 1>&2 2>&3)
      if id -u "$USERNAME" >/dev/null 2>&1; then
        PASSWORD=$(whiptail --passwordbox "Enter the new password for user '$USERNAME':" 8 39 --title "Set Password" 3>&1 1>&2 2>&3)
        CONFIRM_PASSWORD=$(whiptail --passwordbox "Confirm the new password:" 8 39 --title "Confirm Password" 3>&1 1>&2 2>&3)

        if [ "$PASSWORD" = "$CONFIRM_PASSWORD" ]; then
          OUTPUT=$(echo "$USERNAME:$PASSWORD" | sudo chpasswd 2>&1)
          if [ $? -ne 0 ]; then
            whiptail --msgbox "$OUTPUT" 8 39 --title "Error"
          else
            whiptail --msgbox "Password for user '$USERNAME' changed successfully!" 8 39 --title "Success"
          fi
        else
          whiptail --msgbox "Passwords do not match. Password not changed." 8 39 --title "Error"
        fi
      else
        whiptail --msgbox "User '$USERNAME' does not exist!" 8 39 --title "Error"
      fi
      ;;
   
    5)
      USERNAME=$(whiptail --inputbox "Enter the username to list information:" 8 39 --title "List Specific User Information" 3>&1 1>&2 2>&3)
      if id -u "$USERNAME" >/dev/null 2>&1; then
        USER_INFO=$(getent passwd "$USERNAME")
        LAST_LOGIN=$(last -n 1 "$USERNAME" | awk '{print $4, $5, $6, $7}' | sed 's/,//') # Extract last login info
        USER_HOME=$(echo "$USER_INFO" | cut -d: -f6)
        USER_SHELL=$(echo "$USER_INFO" | cut -d: -f7)
        USER_COMMENT=$(echo "$USER_INFO" | cut -d: -f5)
        USER_GROUPS=$(groups "$USERNAME" | cut -d: -f2) # Get groups user is in

        # Get user account aging information
        PASSWORD_CHANGE=$(chage -l "$USERNAME" | grep "Last password change" | cut -d: -f2)
        PASSWORD_EXPIRED=$(chage -l "$USERNAME" | grep "Password expires" | cut -d: -f2)
        ACCOUNT_INACTIVE=$(chage -l "$USERNAME" | grep "Account inactive" | cut -d: -f2)
        ACCOUNT_EXPIRES=$(chage -l "$USERNAME" | grep "Account expires" | cut -d: -f2)
        DAYS_BEFORE_EXPIRE=$(chage -l "$USERNAME" | grep "Number of days before password expires" | cut -d: -f2)
        if sudo passwd -S "$USERNAME" | grep -q 'L'; then
          USER_STATUS="Disabled"
        else
          USER_STATUS="Enabled"
        fi

        INFO_MESSAGE="User $USERNAME Information:\n\
Username: $USERNAME\n\
Home Directory: $USER_HOME\n\
Last Login: ${LAST_LOGIN:-Never}\n\
Comment: ${USER_COMMENT:-None}\n\
Shell: $USER_SHELL\n\
Groups: ${USER_GROUPS:-None}\n\
Status: $USER_STATUS\n\
Last Password Change: $PASSWORD_CHANGE\n\
Password Expired: ${PASSWORD_EXPIRED:-Never}\n\
Account Inactive: ${ACCOUNT_INACTIVE:-Never}\n\
Account Expires: ${ACCOUNT_EXPIRES:-Never}\n\
Days Before Password Expires: ${DAYS_BEFORE_EXPIRE:-0}\n"

        whiptail --msgbox "$INFO_MESSAGE" 20 60 --title "User Information"
      else
        whiptail --msgbox "User '$USERNAME' does not exist!" 8 39 --title "Error"
      fi
      ;;
    6)
      GROUPNAME=$(whiptail --inputbox "Enter the group name to add:" 8 39 --title "Add Group" 3>&1 1>&2 2>&3)
      OUTPUT=$(sudo groupadd "$GROUPNAME" 2>&1)
      if [ $? -ne 0 ]; then
        whiptail --msgbox "$OUTPUT" 8 39 --title "Error"
      else
        whiptail --msgbox "Group '$GROUPNAME' added successfully!" 8 39 --title "Success"
      fi
      ;;
    7)
      GROUPNAME=$(whiptail --inputbox "Enter the group name to modify:" 8 39 --title "Modify Group" 3>&1 1>&2 2>&3)
      if getent group "$GROUPNAME" >/dev/null 2>&1; then
        NEW_GROUPNAME=$(whiptail --inputbox "Enter the new group name:" 8 39 --title "Modify Group Name" 3>&1 1>&2 2>&3)
        
        # Check if the new group name already exists
        if getent group "$NEW_GROUPNAME" >/dev/null 2>&1; then
          whiptail --msgbox "The group name '$NEW_GROUPNAME' already exists. Please choose a different group name." 8 39 --title "Error"
        else
          OUTPUT=$(sudo groupmod -n "$NEW_GROUPNAME" "$GROUPNAME" 2>&1)
          if [ $? -ne 0 ]; then
            whiptail --msgbox "$OUTPUT" 8 39 --title "Error"
          else
            whiptail --msgbox "Group '$GROUPNAME' renamed to '$NEW_GROUPNAME' successfully!" 8 39 --title "Success"
          fi
        fi
      else
        whiptail --msgbox "Group '$GROUPNAME' does not exist!" 8 39 --title "Error"
      fi
      ;;
    8)
      GROUPNAME=$(whiptail --inputbox "Enter the group name to delete:" 8 39 --title "Delete Group" 3>&1 1>&2 2>&3)
      OUTPUT=$(sudo groupdel "$GROUPNAME" 2>&1)
      if [ $? -ne 0 ]; then
        whiptail --msgbox "$OUTPUT" 8 39 --title "Error"
      else
        whiptail --msgbox "Group '$GROUPNAME' deleted successfully!" 8 39 --title "Success"
      fi
      ;;
    9)
      USERNAME=$(whiptail --inputbox "Enter the username to add to a group:" 8 39 --title "Add User to Group" 3>&1 1>&2 2>&3)
      GROUPNAME=$(whiptail --inputbox "Enter the group name:" 8 39 --title "Add User to Group" 3>&1 1>&2 2>&3)
      OUTPUT=$(sudo usermod -aG "$GROUPNAME" "$USERNAME" 2>&1)
      if [ $? -ne 0 ]; then
        whiptail --msgbox "$OUTPUT" 8 39 --title "Error"
      else
        whiptail --msgbox "User '$USERNAME' added to group '$GROUPNAME' successfully!" 8 39 --title "Success"
      fi
      ;;
    10)
      USERS=$(cut -d: -f1 /etc/passwd)
      echo "$USERS" > /tmp/userlist.txt
      LINES=$(wc -l < /tmp/userlist.txt)
      HEIGHT=$(( LINES > 10 ? LINES : 10 ))
      [ $HEIGHT -gt 20 ] && HEIGHT=20
      whiptail --scrolltext --textbox /tmp/userlist.txt $HEIGHT 60 --title "User List"
      ;;
    11)
      GROUPS=$(cut -d: -f1 /etc/group)
      echo "$GROUPS" > /tmp/grouplist.txt
      LINES=$(wc -l < /tmp/grouplist.txt)
      HEIGHT=$(( LINES > 10 ? LINES : 10 ))
      [ $HEIGHT -gt 20 ] && HEIGHT=20
      whiptail --scrolltext --textbox /tmp/grouplist.txt $HEIGHT 60 --title "Group List"
      ;;
    12)  # Enable User
      USERNAME=$(whiptail --inputbox "Enter the username to enable:" 8 39 --title "Enable User" 3>&1 1>&2 2>&3)

      if id -u "$USERNAME" >/dev/null 2>&1; then
         USER_STATUS=$(sudo passwd -S "$USERNAME" | awk '{print $2}') # Get the user status

         if [ "$USER_STATUS" == "LK" ]; then
             OUTPUT=$(sudo usermod -U "$USERNAME" 2>&1)
             if [ $? -ne 0 ]; then
                 whiptail --msgbox "$OUTPUT" 8 39 --title "Error"
             else
                 whiptail --msgbox "User '$USERNAME' enabled successfully!" 8 39 --title "Success"
             fi
         else
             whiptail --msgbox "User '$USERNAME' is already enabled." 8 39 --title "Info"
         fi
      else
         whiptail --msgbox "User '$USERNAME' does not exist!" 8 39 --title "Error"
      fi
      ;;
 
   13)
      USERNAME=$(whiptail --inputbox "Enter the username to disable:" 8 39 --title "Disable User" 3>&1 1>&2 2>&3)
      OUTPUT=$(sudo usermod -L "$USERNAME" 2>&1)
      if [ $? -ne 0 ]; then
        whiptail --msgbox "$OUTPUT" 8 39 --title "Error"
      else
        whiptail --msgbox "User '$USERNAME' disabled successfully!" 8 39 --title "Success"
      fi
      ;;
    14)
      whiptail --msgbox "User and Group Management Script\nVersion 1.0\nCreated by [Your Name]" 8 39 --title "About"
      ;;
    15)
      break
      ;;
  esac
done

