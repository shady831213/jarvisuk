`ifndef __JVS_REG_RESOURCE_MANAGER_SV__
 `define __JVS_REG_RESOURCE_MANAGER_SV__
class jvs_reg_seqr_adapter_pair extends uvm_object;
   uvm_reg_adapter adapter;
   uvm_sequencer_base sequencer;
   `uvm_object_utils_begin(jvs_reg_seqr_adapter_pair)
     `uvm_field_object(adapter, UVM_ALL_ON | UVM_REFERENCE)
     `uvm_field_object(sequencer, UVM_ALL_ON | UVM_REFERENCE)
   `uvm_object_utils_end

   function new(string name = "jvs_reg_seqr_adapter_pair");
      super.new(name);
   endfunction // new

   function bit check();
      return sequencer != null && adapter != null;
   endfunction
endclass // jvs_reg_seqr_adapter_pair

//all pairs must created by factory, to garentee (root_map, ref of sequencer) 1 on 1 map
class jvs_reg_seqr_adapter_pair_factory;
   local static jvs_reg_seqr_adapter_pair pairs[$];

   static function jvs_reg_seqr_adapter_pair get_seqr_adapter_pair(uvm_sequencer_base sequencer, uvm_reg_adapter adapter);
      jvs_reg_seqr_adapter_pair pairs_found[$];
      jvs_reg_seqr_adapter_pair pair;
      //check null
      if (adapter == null || sequencer == null) begin
	 return null;
      end
      //check exist
      pairs_found = pairs.find_first with (item.adapter == adapter && item.sequencer == sequencer);
      if (pairs_found.size() == 1) begin
	 return pairs_found.pop_front();
      end
      //add new ref
      pair = jvs_reg_seqr_adapter_pair::type_id::create({sequencer.get_name(), "___", adapter.get_name()});
      pair.sequencer = sequencer;
      pair.adapter = adapter;
      pairs.push_front(pair);
      return pair;
   endfunction
endclass // jvs_reg_seqr_adapter_pair_factory

class jvs_reg_resource_manager extends uvm_object;
   local static jvs_reg_resource_manager inst;
   local semaphore lock;
   local jvs_common_condition cond;
   //one hot and atomic
   local jvs_reg_seqr_adapter_pair map_table[uvm_reg_map];
   local int 	   seqr_adapter_ref[jvs_reg_seqr_adapter_pair];
   local int 	   root_map_ref[uvm_reg_map];
   `uvm_object_utils_begin(jvs_reg_resource_manager)
   `uvm_object_utils_end

   function new(string name = "jvs_reg_resource_manager");
      super.new(name);
   endfunction // new

   static function jvs_reg_resource_manager get_manager();
      if(jvs_reg_resource_manager::inst == null) begin
	 jvs_reg_resource_manager::inst = jvs_reg_resource_manager::type_id::create("jvs_reg_resource_manager");
	 jvs_reg_resource_manager::inst.lock = new(1);
	 jvs_reg_resource_manager::inst.cond = new(jvs_reg_resource_manager::inst.lock);
      end
      return jvs_reg_resource_manager::inst;
   endfunction // get_manager

   local function bit change_pair(jvs_reg_seqr_adapter_pair seqr_adapter, uvm_reg_map root_map);
      if (root_map == null) begin
	 `uvm_info(this.get_name(), "root_map is null!", UVM_LOW);
	 return 0;
      end
      if (root_map.get_root_map() != root_map) begin
	 `uvm_info(this.get_name(), "root_map is not root!", UVM_LOW);
	 return 0;
      end
      if (!seqr_adapter.check()) begin
	 `uvm_info(this.get_name(), "seqr_adapter is illegal!", UVM_LOW);
	 return 0;	 
      end
      if (map_table[root_map] != seqr_adapter) begin
	 root_map.set_sequencer(seqr_adapter.sequencer, seqr_adapter.adapter);
	 map_table[root_map] = seqr_adapter;
      end
      seqr_adapter_ref[seqr_adapter]++;
      root_map_ref[root_map]++;
      return 1;
   endfunction // change_pair

   task request_reg_map(jvs_reg_seqr_adapter_pair seqr_adapter, uvm_reg_map root_map);
      lock.get(1);
      //already in use
      `uvm_info(this.get_name(), $psprintf("request seq_adapter %0s and root_map %0s", seqr_adapter.get_name(), root_map.get_name()), UVM_HIGH);
      if (map_table[root_map] == seqr_adapter) begin
	 seqr_adapter_ref[seqr_adapter] ++;
	 root_map_ref[root_map] ++;
	 `uvm_info(this.get_name(), $psprintf("seq_adapter %0s and root_map %0s in use!, seqr_adapter ref %0d, root_map ref %0d", seqr_adapter.get_name(), root_map.get_name(), seqr_adapter_ref[seqr_adapter], root_map_ref[root_map]), UVM_HIGH);
	 lock.put(1);
	 return;
      end
      `uvm_info(this.get_name(), $psprintf("seq_adapter %0s and root_map %0s not in use, waiting!, seqr_adapter ref %0d, root_map ref %0d", seqr_adapter.get_name(), root_map.get_name(), seqr_adapter_ref[seqr_adapter], root_map_ref[root_map]), UVM_HIGH);
      while((root_map_ref[root_map] != 0 || seqr_adapter_ref[seqr_adapter] != 0) && map_table[root_map] != seqr_adapter) begin
	 `uvm_info(this.get_name(), $psprintf("cur process seq_adapter %0s and root_map %0s go to sleep!", seqr_adapter.get_name(), root_map.get_name()), UVM_HIGH);
	 cond.sleep();
      end
      `uvm_info(this.get_name(), $psprintf("cur process seq_adapter %0s and root_map %0s waked up!", seqr_adapter.get_name(), root_map.get_name()), UVM_HIGH);
      if (!change_pair(seqr_adapter, root_map)) begin
	 `uvm_fatal(this.get_name(), $psprintf("change seqr_adapter pair %0s fail!", seqr_adapter.get_name()));
      end
      lock.put(1);
   endtask

   task release_reg_map(jvs_reg_seqr_adapter_pair seqr_adapter, uvm_reg_map root_map);
      lock.get(1);
      if (!map_table.exists(root_map) || map_table[root_map] != seqr_adapter) begin
	 `uvm_fatal(this.get_name(), $psprintf("seqr_adapter pair %0s try to release root_map %0s, but it's not owner of root_map!", seqr_adapter.get_name(), root_map.get_name()));
	 lock.put(1);
	 return;
      end
      if (seqr_adapter_ref[seqr_adapter] < 1 || root_map_ref[root_map] < 1) begin
	 `uvm_fatal(this.get_name(), $psprintf("seqr_adapter pair %0s or root_map %0s no ref, they are %0d, %0d !", seqr_adapter.get_name(), root_map.get_name(), seqr_adapter_ref[seqr_adapter], root_map_ref[root_map]));
	 lock.put(1);
	 return;
      end
      seqr_adapter_ref[seqr_adapter]--;
      root_map_ref[root_map]--;
      `uvm_info(this.get_name(), $psprintf("release seq_adapter %0s and root_map %0s!, seqr_adapter ref %0d, root_map ref %0d", seqr_adapter.get_name(), root_map.get_name(), seqr_adapter_ref[seqr_adapter], root_map_ref[root_map]), UVM_HIGH);
      if (seqr_adapter_ref[seqr_adapter] == 0 || root_map_ref[root_map] == 0) begin
	 `uvm_info(this.get_name(), $psprintf("seq_adapter %0s and root_map %0s wake up all process!", seqr_adapter.get_name(), root_map.get_name()), UVM_HIGH);
	 cond.wake_all();
      end
      lock.put(1);
   endtask

endclass // jvs_reg_resource_manager


`endif