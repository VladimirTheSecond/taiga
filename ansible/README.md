### ansible playbook to run taiga server on compute instance
OS - Ubuntu 26.04  
hosts.ini is not on github, use the example instead  

### role common
basics - create admin user, allow ssh port, enable UFW and fail2ban, update packages

### role docker  
remove default docker that comes with ubuntu 26.04, install docker CE (thats recommended by docker to avoid problems with updates and dependencies)

### role taiga  
based on official instructions from https://community.taiga.io/t/taiga-30min-setup/170  
what we change is using nginx instead of taiga-gateway  

