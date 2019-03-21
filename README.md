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
TBD

# clock group
TBD
