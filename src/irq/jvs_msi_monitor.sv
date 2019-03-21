`ifndef __JVS_MSI_MONITOR_SV__
 `define __JVS_MSI_MONITOR_SV__
virtual class jvs_msi_monitor extends uvm_monitor;
   `uvm_field_utils_begin(jvs_msi_monitor)
   `uvm_field_utils_end
   uvm_analysis_port #(jvs_irq_trans) ap;
   function new(string name = "jvs_msi_monitor", uvm_component parent);
      super.new(name, parent);
   endfunction // new

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      ap = new("ap", this);
   endfunction // build_phase

   virtual task main_phase(uvm_phase phase);
      forever begin
	 jvs_irq_trans tr;
	 `uvm_info(this.get_name(), "wait a msi interrupt!", UVM_HIGH);
	 monitor_msi(tr);
	 if (tr == null) begin
	    `uvm_fatal(this.get_name(), "null irq_trans!");
	 end
	 tr.irq_vector = `JVS_MSI_IRQ_V(tr.irq_vector);
	 ap.write(tr);
	 tr.end_event.wait_on();
	 `uvm_info(this.get_name(), "get a msi interrupt!", UVM_HIGH);
      end
   endtask // main_phase

   pure protected virtual task monitor_msi(output jvs_irq_trans tr);
endclass
`endif