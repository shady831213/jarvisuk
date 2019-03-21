`ifndef __JVS_INT_AGENT_SV__
 `define __JVS_INT_AGENT_SV__
typedef uvm_sequencer#(jvs_int_drv_trans) jvs_int_sequencer;
class jvs_int_agent extends uvm_agent;
   `uvm_component_utils(jvs_int_agent)

   virtual jvs_int_if int_if;
   jvs_int_monitor int_mon;
   jvs_int_driver  int_drv;
   jvs_int_sequencer int_seqr;
   uvm_analysis_export #(jvs_irq_trans) irq_put_export;

   function new(string name = "jvs_int_agent", uvm_component parent);
      super.new(name, parent);
      this.is_active = UVM_PASSIVE;
      irq_put_export = new("irq_put_export", this);
   endfunction // new
   
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      int_mon = jvs_int_monitor::type_id::create("int_mon", this);
      if (is_active == UVM_ACTIVE) begin
	 int_seqr = jvs_int_sequencer::type_id::create("int_seqr", this);
	 int_drv = jvs_int_driver::type_id::create("int_drv", this);
      end

      if (!uvm_config_db#(virtual jvs_int_if)::get(this, "", "jvs_int_if", int_if)) begin
	 `uvm_fatal(this.get_full_name(), "Can't get the interrupt interface!");
      end

      uvm_config_db#(virtual jvs_int_if)::set(this, "*", "jvs_int_if", int_if);
   endfunction

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (is_active == UVM_ACTIVE) begin
	 int_drv.seq_item_port.connect(int_seqr.seq_item_export);
      end
      int_mon.ap.connect(irq_put_export);
   endfunction
endclass
`endif