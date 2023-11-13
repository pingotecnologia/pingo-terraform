#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "[INFO] Installing initial dependencies"
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt-get install python3-unidiff python3-matplotlib python3-pip libssl-dev libsasl2-dev nginx libldap2-dev python3-dev -y

echo "[INFO] Installing postgresql-12"
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql-12 postgresql-client-12

echo "[INFO] Installing some more dependencies"
sudo apt install libpq-dev -y
sudo pip3 install --upgrade pip
sudo pip3 install --upgrade setuptools
sudo pip3 install xlwt num2words

echo "[INFO] Installing wkhtml"
sudo apt-get install xfonts-75dpi xfonts-base fontconfig -y
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb
sudo dpkg -i wkhtmltox_0.12.6.1-2.jammy_amd64.deb
sudo apt install -f

echo "[INFO] Creating odoo user"
sudo adduser ${odoo_user} \
--home /home/${odoo_user} \
--disabled-password \
--shell /bin/bash \
--gecos GECOS
sudo usermod -aG sudo ${odoo_user}
sudo passwd -d ${odoo_user}
sudo -u postgres createuser -d ${odoo_user}
sleep 5

echo "[INFO] Creating Odoo Directory"
su ${odoo_user}
export HOME="/home/${odoo_user}"
mkdir /home/${odoo_user}/.ssh
ssh-keyscan github.com >> /home/${odoo_user}/.ssh/known_hosts
cd
mkdir odoo
cd odoo
mkdir logs

echo "[INFO] Cloning repositories"
git clone --depth=1 --branch=${odoo_version} https://github.com/odoo/odoo.git odoo
git clone  --depth=1 --branch=main https://github.com/pingotecnologia/pingo-shared-scripts.git pingo-shared-scripts

echo "[INFO] Installing python requirements"
pip3 install -r odoo/requirements.txt

echo "[INFO] Creating execution scripts"
mkdir ~/bin # if not exist
cp -r ~/odoo/pingo-shared-scripts/odoo/${odoo_version} ~/bin/odoo

echo "[INFO] Nginx Configuration"
sudo cp  ~/bin/odoo/nginx.conf /etc/nginx/sites-available/odoo
sudo sed -i "s/odoo.domain.com/${odoo_domain_name}/" /etc/nginx/sites-available/odoo
sudo ln -s /etc/nginx/sites-available/odoo /etc/nginx/sites-enabled/odoo

echo "[INFO] Odoo Service Configuration"
sudo bash -c "cp ~/bin/odoo/odoo.service /etc/systemd/system/"
sudo sed -i "s/odoo_user/${odoo_user}/" /etc/systemd/system/odoo.service
sudo cp  ~/bin/odoo/odoo.conf /home/${odoo_user}/odoo/odoo.conf
sudo sed -i "s/odoo_user/${odoo_user}/" /home/${odoo_user}/odoo/odoo.conf
chown ${odoo_user}:${odoo_user} /home/${odoo_user} -R

echo "[INFO] Starting Odoo service"
sudo systemctl enable odoo
sudo systemctl daemon-reload
sudo systemctl restart nginx
sudo systemctl start odoo
sudo systemctl status odoo

echo "[INFO] Odoo Installed. Enjoy the Party!"
