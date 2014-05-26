date > /etc/vagrant_box_build_time
echo 'solver.allowVendorChange = true' >> /etc/zypp/zypp.conf
echo 'solver.onlyRequires = true' >> /etc/zypp/zypp.conf

echo 'gem: --no-ri --no-rdoc' > /etc/gemrc

# Vagrant public key
echo -e "\ninstall vagrant key ..."
mkdir -m 0700 /home/vagrant/.ssh
cd /home/vagrant/.ssh
wget --no-check-certificate -O authorized_keys https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant.users /home/vagrant/.ssh

# Update sudoers
echo -e "\nupdate sudoers ..."
echo -e "\n# added by veewee/postinstall.sh" >> /etc/sudoers
echo -e "vagrant ALL=(ALL) NOPASSWD: ALL\n" >> /etc/sudoers

# Speed-up remote logins
echo -e "\nspeed-up remote logins ..."
echo -e "\n# added by veewee/postinstall.sh" >> /etc/ssh/sshd_config
echo -e "UseDNS no\n" >> /etc/ssh/sshd_config

# Remove all repositories
sudo zypper --non-interactive rr SUSE-Linux-Enterprise-Server-12-12.0-
rm /etc/zypp/locks
zypper refresh

# Install chef-solo gem
echo -e "\nInstall Chef-Solo gem\n"
wget -O- https://opscode.com/chef/install.sh | sudo bash

cd /root/
sudo wget --http-user=username --http-password=password -O .oscrc http://gaffer.suse.de:9999/files/.oscrc
cat /root/.oscrc

cd /root/
sudo wget --http-user=username --http-password=password -O regcode.txt http://gaffer.suse.de:9999/files/regcode.txt
sudo cat regcode.txt >> /root/.bashrc
cat /root/.bashrc

echo -e "\nall done.\n"
exit
