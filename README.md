# bitCat
## setup
### Ubuntu

1. Write this code to some ShellScript file.
```sh:setup.sh
#! /bin/sh

sudo apt install snap git cron -y
sudo snap install nim-lang --classic

git clone https://github.com/penta2himajin/bitCat
sudo chmod 777 bitCat
cd bitCat
nimble build_project
cp bin/bitCat ../bitCat_exec
cd ~
sudo rm -rf bitCat
mv bitCat_exec bitCat

crontab -l > temp
echo "* * * * * ./bitCat" >> temp
crontab -u `whoami` temp
rm temp
```

2. Granting authority to the file.
```
chmod 766 setup.sh
```

3. Execute the file.
```sh
sh setup.sh
```
