`ifndef __JVS_REG_TREE_SV__
 `define __JVS_REG_TREE_SV__
virtual class jvs_reg_tree_node#(type NONLEAF_TYPE = jvs_reg_tree_node) extends uvm_object;
   typedef jvs_reg_tree_node#(NONLEAF_TYPE) THIS_TYPE;
   protected NONLEAF_TYPE parent;
   `uvm_field_utils_begin(jvs_reg_tree_node#(NONLEAF_TYPE))
     `uvm_field_object(parent, UVM_ALL_ON)
   `uvm_field_utils_end

   function new(string name = "jvs_reg_tree_node");
      super.new(name);
   endfunction // new

   function void set_parent(NONLEAF_TYPE parent);
      this.parent = parent;
   endfunction // set_parent

   function NONLEAF_TYPE get_parent();
      return this.parent;
   endfunction // get_parent

   function bit[63:0] get_max();
      return get_base()+get_size()-1;
   endfunction // get_max

   protected function bit in_region(THIS_TYPE node);
      return get_base() >= node.get_base() && get_max() <= node.get_max();
   endfunction // in_region

   function bit is_overlapped(THIS_TYPE node);
      return get_base() >= node.get_base() && get_base() <= node.get_max() || get_max() >= node.get_base() && get_max() <= node.get_max();
   endfunction // is_overlapped

   protected function bit check_in_region(THIS_TYPE node);
      if (!node.in_region(node.parent)) begin
	 `uvm_info(this.get_name(), $psprintf("%0s is not in this region!", node.get_name()), UVM_LOW);
	 return 0;
      end
      return 1;
   endfunction // check_in_region

   pure virtual function bit[63:0] get_base();
   pure virtual function bit[63:0] get_size();
   
endclass // jvs_reg_tree_node

class jvs_reg_tree_nodes#(type NODE_TYPE = jvs_reg_tree_node#(jvs_reg_tree_node)) extends uvm_object;
   protected NODE_TYPE node_table[string];
   `uvm_object_param_utils_begin(jvs_reg_tree_nodes#(NODE_TYPE))
     `uvm_field_aa_object_string(node_table,UVM_ALL_ON)
   `uvm_object_utils_end
   function new(string name = "jvs_reg_tree_nodes");
      super.new(name);
   endfunction // new

   function bit check_exist_name(NODE_TYPE node);
      if (node_table.exists(node.get_name())) begin
	 `uvm_info(this.get_name(), $psprintf("%0s is existed!", node.get_name()), UVM_LOW);
	 return 0;
      end
      return 1;
   endfunction

   function bit check_overlap(NODE_TYPE node);
      foreach(node_table[i]) begin
	 if (node.is_overlapped(node_table[i])) begin
	    `uvm_info(this.get_name(), $psprintf("%0s is overlapped with %0s!", node.get_name(), node_table[i].get_name()), UVM_LOW);
	    return 0;
	 end
      end
      return 1;
   endfunction

   function bit remove_node(string key);
      if (!node_table.exists(key)) begin
	 return 0;
      end
      node_table[key].set_parent(null);
      node_table.delete(key);
      return 1;
   endfunction

   function void add_node(NODE_TYPE node);
      node_table[node.get_name()] = node;
   endfunction // add_node

   function NODE_TYPE get_node(string key);
      if (!node_table.exists(key)) begin
	 return null;
      end
      return node_table[key];
   endfunction // get_node

   function void get_nodes(ref NODE_TYPE nodes[$]);
      foreach(node_table[i]) begin
	 nodes.push_back(node_table[i]);
      end
   endfunction
endclass
`endif