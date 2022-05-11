# Current State / Mode of blacklister.py
* !!! in development / not released / DO NOT USE !!!

# Current State / Mode of blacklister.sh
* Tested on Debian 11

# What is the difference between py / sh script?
Really, not so much. The python script is currently in development and not ready to run on servers. The bash script I've scripted last night and it was much easier because I could adapt some old functions from further of my scripts like this.

# How to work with "blacklister.py"?
* `sudo apt update`
* `sudo apt -y install python3 python3-setuptools python3-pip git iptables iptables-persistent`
* `sudo git clone https://github.com/pthoelken/serverhardening.git`
* `cd serverhardening/iptables`
* `sudo pip3 install -r requirements.txt`
* `sudo python3 blacklister.py`

# How to work with "blacklister.sh"?
* `sudo apt update`
* `sudo apt -y install python3 python3-setuptools python3-pip git iptables iptables-persistent`
* `sudo git clone https://github.com/pthoelken/serverhardening.git`
* `cd serverhardening/iptables`
* `sudo chmod +x blacklister.sh`

# How to run the blacklister automatically?
* `sudo nano /etc/crontab`
* Add in end of the file your crontab for example every night at midnight:
* * `0 0 * * *   root    python3 /your/path/to/serverhardening/iptables/blacklister.py`
* * `0 0 * * *   root    bash /your/path/to/serverhardening/iptables/blacklister.sh`