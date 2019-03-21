`ifndef __JVS_IRQ_ENV_SV__
 `define __JVS_IRQ_ENV_SV__
class jvs_irq_env extends uvm_env;
   jvs_irq_vir_sequencer jvs_irq_seqr;
   jvs_int_agent         jvs_int_ag;
   jvs_msi_monitor       jvs_msi_mon;

   `uvm_component_utils_begin(jvs_irq_env)
   `uvm_component_utils_end

   function new(string name = "jvs_irq_env", uvm_component parent = null);
      super.new(name, parent);
   endfunction // new

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      uvm_config_db#(uvm_object_wrapper)::set(this, "jvs_irq_seqr.run_phase", "default_sequence", jvs_irq_vir_seq::type_id::get());
      jvs_irq_seqr = jvs_irq_vir_sequencer::type_id::create("jvs_irq_seqr", this);
      jvs_int_ag = jvs_int_agent::type_id::create("jvs_int_agent", this);
      if (!uvm_config_db#(jvs_msi_monitor)::get(this, "", "jvs_msi_monitor", jvs_msi_mon)) begin
	 `uvm_info(this.get_name, "no msi support!", UVM_LOW);
      end
   endfunction // build_phase

   virtual function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      jvs_int_ag.irq_put_export.connect(jvs_irq_seqr.irq_put_imp);
      if (jvs_msi_mon != null) begin
	 jvs_msi_mon.ap.connect(jvs_irq_seqr.irq_put_imp);
      end
   endfunction // connect_phase

   task register_irq(bit[`JVS_MAX_IRQ_VECTOR_WIDTH-1:0] irq_vector, jvs_irq_handler handler);
      jvs_irq_seqr.register_irq(irq_vector, handler);
   endtask

   task unregister_irq(bit[`JVS_MAX_IRQ_VECTOR_WIDTH-1:0] irq_vector, jvs_irq_handler handler);
      jvs_irq_seqr.register_irq(irq_vector, handler);
   endtask // unregister_irq

   task reset();
      jvs_irq_seqr.reset();
   endtask // reset

   function void trigger_soft_irq(jvs_irq_trans tr);
      if (tr.get_irq_type() != jvs_irq_trans::SOFT_IRQ) begin
	 tr.print();
	 `uvm_fatal(this.get_name(), "irq is not soft irq!");
      end
      jvs_irq_seqr.write(tr);
   endfunction
endclass
`endif