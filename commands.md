

```sh
ssh jeisenbarth@access.nancy.grid5000.fr
```

### On jeisenbarth@fnancy:~$


Make the reservation (11 physical nodes on graphene for 7hr in a /22 subnetwork)
```sh
oarsub -I -t deploy -l slash_22=1+{"cluster='graphene'"}/nodes=11,walltime=7
```

Warning : do not exceed 3 reservations and 7hr per reservation. This is close to the authorized maximum (11(physical_nodes) * 4(cores/CPU) * 7(hours) * 3(reservations) = 924 core.hours )

Retrieve the network address that Grid5000 assigned to you (keep that somewhere)
```sh
g5k-subnets -sp
```

Deploy the system that will be the base for the Distem (DISTributed systems EMulator)
```sh
kadeploy3 -f $OAR_NODEFILE -e jessie-x64-nfs -k
```

Install Distem on that system
```sh
distem-bootstrap --node-list $OAR_NODE_FILE
```

Connect to the coordinator (see the result of the previous command)
```
ssh graphene-??
```

### On jeisenbarth@graphene-?:~$


Deploy the plateform for the experiment (the argument is the returned value of the ```g5k-subnets -sp``` command)
```sh
ruby plateform_setup_4perpnode.rb "10.144.?.0"
```

Run the experiment (-n is for the number of node that will continue to mine after the first part)
```sh
ruby experiment_4perpnode.rb -n 10
```

You can also use the -s option that will activate the monitoring with ethstats

Warning : Only one -s simultaneously or ethstats will have contradictory infos

When the experiment is finished two files will be written in public/distem :

- last_block_number_40-?.txt
- blocks_info_40-?.json

### On your machine

To retrieve them :

```sh
scp jeisenbarth@access.nancy.grid5000.fr:public/distem/last_block_number_40-?.txt path/to/your/destination
scp jeisenbarth@access.nancy.grid5000.fr:public/distem/blocks_info_40-?.json path/to/your/destination
```

### After an experiment, on the coordinator:~$

```sh
distem -q
exit
```

### On jeisenbarth@fnancy:~$

Reinstall Distem on that system
```sh
distem-bootstrap --node-list $OAR_NODE_FILE
```

Reconnect to the coordinator (see the result of the previous command)
```
ssh graphene-??
```

### ssh to the coordinator and reexecute plateform_setup_4perpnode and experiment_4perpnode
