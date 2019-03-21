`ifndef __JVS_INT_MONITOR_SV__
 `define __JVS_INT_MONITOR_SV__
class jvs_int_monitor extends uvm_monitor;
   `uvm_component_utils(jvs_int_monitor)
   virtual jvs_int_if vif;
   uvm_analysis_port #(jvs_irq_trans) ap;
   function new(string name = "jvs_int_monitor", uvm_component parent);
      super.new(name, parent);
   endfunction // new

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      ap = new("ap", this);
      if (!uvm_config_db#(virtual jvs_int_if)::get(this, "", "jvs_int_if", vif)) begin
	 `uvm_fatal(get_full_name(), "Can't get the interrupt interface!");
      end
   endfunction // build_phase

   virtual task main_phase(uvm_phase phase);
      jvs_irq_trans tr;
      forever begin
	 @(posedge vif.clk);
	 if (|vif.interrupt) begin
	    `uvm_info(this.get_name(), "get interrupt!", UVM_HIGH);
	    tr = jvs_irq_trans::type_id::create("tr");
	    tr.irq_vector = get_vector(vif.interrupt);
	    ap.write(tr);
	    tr.end_event.wait_on();
	    @(posedge vif.clk);
	    `uvm_info(this.get_name(), "release interrupt!", UVM_HIGH);
	 end
      end
   endtask // main_phase

   local function bit[`JVS_MAX_IRQ_VECTOR_WIDTH-1:0] get_vector(bit[`JVS_MAX_INT_PIN_NUM - 1 : 0] interrupt);
      foreach(interrupt[i]) begin
	 if (interrupt[i]) begin
	    return i;
	 end
      end
      `uvm_fatal(this.get_name(), "get interrupt toggle but no valid irq, maybe interrupt is cleared illegally!");
      return {`JVS_MAX_IRQ_VECTOR_WIDTH{1'b0}};
   endfunction
endclass
`endif