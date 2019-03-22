`ifndef __JVS_REG_BASE_TEST_SV__
 `define __JVS_REG_BASE_TEST_SV__
class jvs_reg_test_trans extends uvm_sequence_item;
   bit w_nr;
   bit [63:0] addr;
   bit [31:0] data;

   `uvm_object_utils_begin(jvs_reg_test_trans)
     `uvm_field_int(w_nr, UVM_ALL_ON)
     `uvm_field_int(addr, UVM_ALL_ON)
     `uvm_field_int(data, UVM_ALL_ON)
   `uvm_object_utils_end

   function new(string name = "jvs_reg_test_trans");
      super.new(name);
   endfunction // new
   
endclass // jvs_reg_test_trans

class jvs_reg_test_adapter extends uvm_reg_adapter;
   `uvm_object_utils_begin(jvs_reg_test_adapter)
   `uvm_object_utils_end

   function new(string name = "jvs_reg_test_adapter");
      super.new(name);
   endfunction // new

   virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
      jvs_reg_test_trans tr = jvs_reg_test_trans::type_id::create("tr");
      tr.addr = rw.addr;
      if (rw.kind == UVM_READ) begin
	 tr.w_nr = 0;
	 tr.print();
	 return tr;
      end
      tr.w_nr = 1;
      tr.data = rw.data;
      tr.print();
      return tr;
   endfunction // reg2bus

   virtual function void bus2reg(uvm_sequence_item bus_item,
				 ref uvm_reg_bus_op rw);
      jvs_reg_test_trans tr;
      if (!$cast(tr, bus_item)) begin
	 `uvm_fatal(this.get_name(), "Wrong type!");
	 return;
      end
      rw.kind = (tr.w_nr == 0) ? UVM_READ: UVM_WRITE;
      rw.addr = tr.addr;
      if (tr.w_nr == 0) begin
	 rw.data = tr.data;
      end
   endfunction
endclass // jvs_reg_test_adapter

typedef uvm_sequencer #(jvs_reg_test_trans) jvs_reg_test_sequencer;

class jvs_reg_test_driver extends uvm_driver#(jvs_reg_test_trans);
   bit[31:0] map[bit[31:0]];
   
   `uvm_component_utils(jvs_reg_test_driver)
     
   function new(string name = "jvs_reg_test_driver", uvm_component parent);
      super.new(name,parent);
   endfunction // new

   virtual task run_phase(uvm_phase phase);
      while(1) begin
	 seq_item_port.get_next_item(req);
	 if (!req.w_nr) begin
	    req.data = map[req.addr[31:0]];
	 end
	 else begin
	    map[req.addr[31:0]] = req.data;
	 end
	 `uvm_info(this.get_name(), "get_trans!", UVM_LOW);
	 req.print();
	 seq_item_port.item_done();
      end
   endtask
endclass // jvs_reg_test_driver

class jvs_reg_base_test extends uvm_test;
   jvs_reg_region_mapper region_mapper;
   `uvm_component_utils(jvs_reg_base_test)
   function new(string name = "jvs_reg_base_test", uvm_component parent);
      super.new(name,parent);
      region_mapper = jvs_reg_region_mapper::type_id::create("region_mapper");
   endfunction // new
   
endclass
`endif