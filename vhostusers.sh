#/bin/bash
#Script to add/remove vhost users on a Linux Apache2 Webserver by Michael V.2.2 19-08-2005 # #Fill in your own stuff #

#set -x

ADMINMAIL=
ADMINNAME=
ADMINDOMAIN=

#Add a user and a new homedirectory, the new place for the vhosts

adduser(){

echo -n "username:"
read USERNAME

id $USERNAME > /dev/null 2>&1
if [ "$?" = 0 ]
then
echo "User already exist or not valid"
        exit 1
fi

echo -n "domein:"
read DOMEIN
echo -n "also send an email to:"
read EMAIL

echo -n "user expire (YYYY-M-D):"
read EXPIRE

#
#This will generate a random password for the new vhost #

MATRIX="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
LENGTH="8"
while [ ${n:=1} -le $LENGTH ]
do
GENPASS="$GENPASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
let n+=1
done

sudo useradd $USERNAME -m -s /bin/bash -p $(openssl passwd -crypt $GENPASS)

mkdir /home/$USERNAME/log
mkdir /home/$USERNAME/www
touch /home/$USERNAME/log/$USERNAME.access.log
touch /home/$USERNAME/log/$USERNAME.error.log

chown -R $USERNAME:apache /home/$USERNAME/www chown -R $USERNAME:apache /home/$USERNAME/log chmod -R 755 /home/$USERNAME

echo $USERNAME >> /etc/vsftpd/user_list
echo $USERNAME >> /etc/vsftpd/chroot_list

echo "<VirtualHost *:80>
ServerAdmin $ADMINMAIL
DocumentRoot /home/$USERNAME/www
ServerName $DOMEIN
ServerAlias www.$DOMEIN
<Directory />
Options FollowSymLinks
AllowOverride None
</Directory>
<Directory /home/$USERNAME/www/>
Options Indexes FollowSymLinks MultiViews AllowOverride All Order allow,deny allow from all </Directory> TransferLog /home/$USERNAME/log/$USERNAME.access.log
ErrorLog /home/$USERNAME/log/$USERNAME.error.log
</VirtualHost>" >> /etc/httpd/conf/$DOMEIN.conf

echo "<?php phpinfo(); ?>" >> /home/$USERNAME/www/index.php chown $USERNAME:$USERNAME /home/$USERNAME/www/index.php

echo "Include /etc/httpd/conf/$DOMEIN.conf" >> /etc/httpd/conf/httpd.conf


echo "username: $USERNAME"
echo "passwd: $GENPASS"
echo " "
echo "MVG $ADMINNAME"
echo " "

#You can activate the mail option by removing the # next to the echo #This optionwil e-mail the account stuff to you and someone else if you fill in the mail adress at the beginning of the script # echo -e "Hi there, \n\nThis is your new username & password for your ftp account at $DOMEIN \n\nusername: $USERNAME \npasswd: $GENPASS \n\n$ADMINMAIL \n$ADMINDOMAIN \n\nIn case of lost password, send an e-mail to $ADMINMAIL\n

Just be nice & enjoy the net. \n\nDo not reply to this mail" | mail -s "$ADMINDOMAIN new passwd for user $USERNAME" "$ADMINMAIL,$EMAIL"

}

#
#To remove user
#

deleteuser(){

echo -n "username:"
read USERNAME

id $USERNAME > /dev/null 2>&1
if [ "$?" != 0 ]
then
echo "User already removed or not valid"
        exit 1
fi

echo -n "domein:"
read DOMEIN

userdel -r $USERNAME
rm /etc/httpd/conf/$DOMEIN.conf

echo "user: $USERNAME has been removed from the server"

#remove # if you want to recieve mail that the user is removed # | mail -s "$ADMINDOMAIN user removed" "$ADMINMAIL"

}




#Passwd rotator option

passwdrotator(){

echo -n "username:"
read USERNAME

id $USERNAME > /dev/null 2>&1
if [ "$?" != 0 ]
then
echo "User not valid"
        exit 1
fi

echo -n "also send an email to:"
read EMAIL
echo -n "domein:"
read DOMEIN

#
# Generate a password for the user
#
MATRIX="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
LENGTH="8"
while [ ${n:=1} -le $LENGTH ]
do
GENPASS="$GENPASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
        let n+=1
done

usermod -p $(openssl passwd -crypt $GENPASS) $USERNAME

echo "username: $USERNAME"
echo "passwd: $GENPASS"

#remove als the # to recieve mail with the new password # #echo -e "Hi there, \n\nThis is your new password for your ftp account at $DOMEIN \n\nusername:$USERNAME \npasswd: $GENPASS \n\n$ADMINNAME \n$ADMINDOMAIN \n\nIn case of lost password, send  an #e-mail to $ADMINMAIL \n #You are fully responsible for any information or file supplied on your #website. Is not Allowed to publish any copyrighted material that is not owned #by yourself. Is not allowed to post any information which is vulgar, #harassing, hateful, threatening, invading of others privacy, sexually #oriented, or violates any laws, child porn would be reported to the police.
#Just be nice & enjoy the net. \n\nDo not reply to this mail" | mail -s "$ADMINDOMAIN new passwd for # user $USERNAME" "$ADMINMAIL,$EMAIL"

}
case "$1" in
        -[cC])
                adduser
        ;;
        -[dD])
                deleteuser
        ;;
        -[pP]) passwdrotator
        ;;
        *)
                echo " $ADMINDOMAIN add/remove vhost users & rotate passwd"
                echo " To create use: -c -C option"
                echo " To remove use: -d -D option"
                echo " To rotate passwd use: -p -P option"
        ;;
esac
exit 0
