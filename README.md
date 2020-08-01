## overthewire

[PROJECT HAS MOVED HERE](https://github.com/Flandre-X/otw)

A launcher for OverTheWire that passwords and loads passwords and executes ssh
commands automatically.

Using this program, you will no longer have to:
1. Copy and paste passwords from a file to an ssh command
2. Type ssh commands

(However, you will have to copy and paste passwords to log in to natas, and you
may have to type ssh commands for certain anomolies such as bandit18.)

Dependencies: ssh, sshpass  
Optional Dependencies: git, xclip, xdg-open

### Demonstration
A directory with the same name as the game you want to play must be created to
log in to the game.

![otw1.png](https://raw.githubusercontent.com/johnrbernard/overthewire/master/demonstration/otw1.png)

If otw.sh doesn't have a password saved for the current level, it will prompt
the user for one (otw.sh output is in green, level output is in the default color).

![otw2.png](https://raw.githubusercontent.com/johnrbernard/overthewire/master/demonstration/otw2.png)


After obtaining the password to the next level, you can copy and paste the
password when the otw.sh prompt appears.

![otw3.png](https://raw.githubusercontent.com/johnrbernard/overthewire/master/demonstration/otw3.png)


After entering the password once, otw.sh saves the password and automatically
uses it to sign in to the corresponding level.

![otw4.png](https://raw.githubusercontent.com/johnrbernard/overthewire/master/demonstration/otw4.png)


Here you can see that otw.sh saved the password under the bandit folder in a
file corresponding to the level number.

![otw5.png](https://raw.githubusercontent.com/johnrbernard/overthewire/master/demonstration/otw5.png)


You can replay any level for which you have saved a password by typing the
level number following the game name.

![otw6.png](https://raw.githubusercontent.com/johnrbernard/overthewire/master/demonstration/otw6.png)


To learn more about otw.sh's capabilities, run the command with the option `--help` or `-h`.
