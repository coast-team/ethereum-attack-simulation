## Simulation on Grid5000

### Overview

A private network of 40 ethereum nodes (full) and 1 bootnode.
The 40 nodes are mining for 1 hour. After that, x number of them are turned off, and the remaining ones will mine for another 1 hour.
At the end, we retrieve the information of the last mined blocks.

### Hardware

All the nodes ran on the "graphene" cluster of Grid5000 with these hardware specs :

- 1 CPU Intel Xeon X3440, 4 cores/CPU, 16GB RAM (per node)

### Software

Deployment of 11 lxc images built with Ansible (configuration manager).

The bootnode and the ethereum nodes are run as systemd services.
