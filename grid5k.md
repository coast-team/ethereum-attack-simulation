## Make a reservation

(on nancy frontend)

```sh
oarsub -I -t deploy -l slash_22=1+{"cluster='graphene'"}/nodes=<nb_nodes>,walltime=<time>
```

<time> could be "1:30:12s" or "1:40" or "2" (2 hours)

To get the /22 assigned to our reservation :

```sh
g5k-subnets -sp
```

Then we deploy an generic debian image (with NFS for distem)

```sh
kadeploy3 -f $OAR_NODEFILE -e jessie-x64-nfs -k
```

Then :

```sh
distem-bootstrap --node-list $OAR_NODE_FILE
```

Wait for the installation of distem on the node.

Transfer the distem scripts and the lxc image to your home directory at grid5000 :

```sh
scp jessie-ethereum-lxc.tar.gz jeisenbarth@access.nancy.grid5000.fr:
```

(you can find this file in the release)

```sh
scp experiment.rb jeisenbarth@access.nancy.grid5000.fr:
```

```sh
scp plateform_setup.rb jeisenbarth@access.nancy.grid5000.fr:
```

Now you can connect to the coordinator :

```sh
ssh <coord_name> # example ssh graphene-34
```

And run your distem scripts :

```sh
ruby plateform_setup_4perpnode.rb <ip_addr_get_from_g5k-subnet>

ruby experiment_4pernode.rb <parameters ...>
```
