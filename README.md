# jarvisuk
Just A Really Very Impressive Systemverilog UVM Kit

# tools
vcs

[jarvism](https://github.com/shady831213/jarvism)

# usage
set $JVSUK_HOME to jarvisuk home dir.

add $JVSUK_HOME/jvs.f to your filelist.

# test
```
source jarvism_cfg/jarvism_setup.sh
jarvism run_group jvs

```

# memory allocator
+ support random or fix address malloc(), free()
+ support va2pa
+ support memory attributes

## test
```
source jarvism_cfg/jarvism_setup.sh
jarvism run_test jvs_memory jvs_memory_showcase -seed 1
```

# interrupt
+ support pin interrupt
+ support msi irq
+ support soft irq
+ support shared irq vector
+ support irq vector redirection

## test
pin interrupt
```
source jarvism_cfg/jarvism_setup.sh
jarvism run_test jvs_memory jvs_int_simple_test
```
msi irq
```
source jarvism_cfg/jarvism_setup.sh
jarvism run_test jvs_memory jvs_msi_irq_test
```
soft irq
```
source jarvism_cfg/jarvism_setup.sh
jarvism run_test jvs_memory jvs_soft_irq_test
```


# register region
+ solve register name conflict
+ multiple sequencer and adapter share root_map
+ multiple reg_blocks with the same attribute into same reg region
+ thread-safe
## test
```
source jarvism_cfg/jarvism_setup.sh
jarvism run_test jvs_register_region jvs_register_region_test -seed 1
```

# clock reset group
+ 
+ support same source but diffrent frequency clocks
+ support differnt source async clocks
+ support global or partially reset
+ support sync and async reset
## test
```
source jarvism_cfg/jarvism_setup.sh
jarvism run_test jvs_clk_rst_group jvs_clk_rst_group_basic_test -seed 1 -wave
```

