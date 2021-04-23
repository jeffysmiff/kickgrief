# Kick the griefers!!!
In March 2021, Rockstar Games released an update for Grand Theft Auto V Online that removed (intentionally or otherwise) the ability to go to network settings and execute a 'Test NAT Type' test resulting in the player being left in a public session but on their own. If the player then wanted to do MC business sell missions, they were at the mercy of a lobby full of griefers, intent on blowing them up before they can make the sale. Net result is that cash grinders such as myself were left having to do the Cayo Perico heist over and over and over...and let's face it, that gets dull.
So I figured I'd make use of my other love in life, the Raspberry PI and build a device that I can use to achieve the same thing.

## What Does It Do???
I genuinely do not believe that Rockstar produced this update with the intent of patching the solo public lobby glitch. Of course, anyone can make the argument that it is trying to push people to shark cards but to me, Cayo Perico negates that. Why would you spend £30 for a megaladon shark card when you can have the same money in 4hrs gameplay?
OK, so if they didn't do this intentionally, then why? For me, the answer is quite simple. Network glitches. How many times have you been in the middle of a mission, maybe with some friends, and suddenly they're not in the game any more and the mission fails? The Internet is an inherently unreliable network. You do not have a direct wire connected to Rockstars servers. You're going through myriads of routers, gateways, bridges, firewalls and other devices along the way. Any one of those fails and your network connection will glitch. Sure, it'll recover again but for that tiny period, your connection to the server will be dead. And GTA V always reacted to those glitches in a bad way. So I think Rockstar just made GTA V more tolerent to small glitches so people don't lose their sessions too quickly.
What I've found is that if the connectivity is down for longer - around 5-10 seconds - then you still get the same result. However, if you do a 'Test NAT Type' test, the connection isn't broken for that long. So that's what this solution does.

## How Does It Do It???
A Raspberry PI 3 had two network devices, a WiFi connection and a wired connection. So the simple answer is that I create a link between the two. I make the wired connection act as a DHCP server on a private network, then the WiFi connection hooks into your home WiFi. 
The Xbox is then connected to the wired socket either via a private switch (if you have one) or a crossover network cable. The Xbox is then issued an IP address in the private network space offered on that interface.
The PI then acts as a router between the private network that the Xbox is on, and your home network that the WiFi is connected to.
All that sits on top of that is a web page with a big button that, when pressed, breaks the connection for 10 seconds between the two networks.

## How Do I Set This Up???
1) Grab Raspberry PI OS Lite:
https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-03-25/2021-03-04-raspios-buster-armhf-lite.zip

2) Download Etcher:
https://www.balena.io/etcher/

3) Use Etcher to burn the Raspberry PI OS to a MicroSD card

4) After the OS is done, do not insert it into the PI yet. Instead, you need to do two things in the partition called 'Boot':
4a) Create an empty file simply called 'ssh'
4b) Create a file called wpa_supplicant.conf with this as the contents:
```
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=GB

network={
	ssid="MY NETWORK SSID"
	psk="MY NETWORK PASSWORD"
	key_mgmt=WPA-PSK
}
```
Also change the 'country' in the above to your country!!!

5) Stick the MicroSD in the PI and power it up. So long as the network settings in the file above are good, then it'll connect to your home WiFi. you can find its IP address on your router. Look under 'Attached Devices' (or equivalent) in your router and look for a device called 'raspberrypi'

6) Connect to the PI with:
```
ssh pi@<ip address>
```
e.g. 
```
ssh pi@192.168.0.2
```

7) Install git
```
sudo apt install git
```

8) Grab everything from this project
```
git clone https://github.com/jeffysmiff/kickgrief.git
```

9) Run the installer
```
chmod +x install_kickgrief.sh
sudo ./install_kickgrief.sh
```

10) Connect one end of a crossover cable to the Xbox, the other end to the network socket of the PI

11) Power on the Xbox, go into network settings and verify that the IP address is 192.168.101.something

12) Start GTA V Online in a public session

13) On your phone or some suitable device, open a browser and navigate to the IP address of your PI e.g.
```
http://192.168.0.21
```

14) Click the big green button

15) 10s later, you should be in a solo, public session!!!