# bitCat
## setup
### make token.nim to target machine's home directory

### type the commands below
1. Install some package that needs to use this.
```
sudo apt install snap git cron -y
sudo snap install nim-lang --classic
```

2. Write this code to some ShellScript file.
```sh:setup.sh
#! /bin/sh

git clone https://github.com/penta2himajin/bitCat
sudo chmod 777 bitCat
cd bitCat
mv ../token.nim src/token.nim
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

3. Granting authority to the file.
```
chmod 766 setup.sh
```

4. Execute the file.
```sh
sh setup.sh
```
