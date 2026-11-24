`ifndef __JVS_INT_DRIVER_SV__
 `define __JVS_INT_DRIVER_SV__
//for test

class jvs_int_drv_trans extends jvs_irq_trans_base;
   jvs_irq_trans_attr attr;
   bit set;
   `uvm_object_utils_begin(jvs_int_drv_trans);
      `uvm_field_object(attr,UVM_ALL_ON)
   `uvm_object_utils_end
   function new(string name = "jvs_int_drv_trans");
      super.new(name);
   endfunction	
endclass // jvs_int_drv_trans

class jvs_int_driver #(int PIN_COUNT = `JVS_MAX_INT_PIN_NUM) extends uvm_driver#(jvs_int_drv_trans);
   `JVS_PIN_COMPONENT_UTILS(jvs_int_driver)

   typedef virtual jvs_int_if #(PIN_COUNT) vif_t;
   vif_t vif;
   int unsigned int_set_cnt[PIN_COUNT];
   function new(string name = "jvs_int_driver", uvm_component parent);
      super.new(name, parent);
   endfunction // new

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(vif_t)::get(this, "", "jvs_int_if", vif)) begin
	 `uvm_fatal(get_full_name(), "Can't get the interrupt interface!");
      end
   endfunction // build_phase

   virtual task main_phase(uvm_phase phase);
      vif.interrupt <= '0;

      forever begin
	 seq_item_port.get_next_item(req);
	 if (req.irq_vector >= PIN_COUNT)
	    `uvm_fatal("JVS_IRQ_PIN", $sformatf("Pin %0d outside %0d-pin interface", req.irq_vector, PIN_COUNT))
	 if (req.set) begin
	    int_set_cnt[req.irq_vector] ++ ;
	    vif.interrupt[req.irq_vector] <= 1'b1;
	    @(posedge vif.clk);
	 end
	 else begin
	    if (int_set_cnt[req.irq_vector] > 0) begin
	       int_set_cnt[req.irq_vector]--;
	       if (int_set_cnt[req.irq_vector] == 0) begin
		  vif.interrupt[req.irq_vector] <= 1'b0;
	       end
	       @(posedge vif.clk);
	    end
	 end // else: !if(req.set)
	 seq_item_port.item_done();
      end
   endtask
endclass
`endif
