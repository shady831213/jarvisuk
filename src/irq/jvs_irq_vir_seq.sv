`ifndef __JVS_IRQ_VIR_SEQ_SV__
 `define __JVS_IRQ_VIR_SEQ_SV__
class jvs_irq_vir_seq extends uvm_sequence_base;
   `uvm_declare_p_sequencer(jvs_irq_vir_sequencer)
   `uvm_object_utils_begin(jvs_irq_vir_seq)
   `uvm_object_utils_end

   function new(string name = "jvs_irq_vir_seq");
      super.new(name);
   endfunction // new

   task body();
      forever begin
	 irq_process();
      end
   endtask // body

   protected virtual task irq_process();
      jvs_irq_trans irq_tr;
      p_sequencer.get_irq(irq_tr);
      `uvm_info(this.get_name(), {"irq_tr : \n", irq_tr.sprint()}, UVM_HIGH);
      //no handler, finish and return
      if (!p_sequencer.irq_table.exists(irq_tr.irq_vector) || p_sequencer.irq_table[irq_tr.irq_vector] == null) begin
	 irq_tr.handle_state = jvs_irq_trans::FINISH;
	 irq_tr.end_tr();
	 return;
      end
      p_sequencer.irq_table[irq_tr.irq_vector].lock.get(1);
      foreach(p_sequencer.irq_table[irq_tr.irq_vector].queue[i]) begin
	 p_sequencer.irq_table[irq_tr.irq_vector].queue[i].handle(irq_tr);
	 //if one handler change tr state to finish, break
	 if (irq_tr.handle_state == jvs_irq_trans::FINISH) begin
	    break;
	 end
      end
      //if all handler didn't handle this tr or all handler shared this tr, it means all done, so change state to finish
      if (irq_tr.handle_state == jvs_irq_trans::THROUGH || irq_tr.handle_state == jvs_irq_trans::UNHANDLED) begin
	 irq_tr.handle_state = jvs_irq_trans::FINISH;
      end
      //if all redirected trans have been handled and can finshi, end_tr
      //otherwise it is resposibility of redirected trans to end_tr
      if (irq_tr.can_end_tr()) begin
	 irq_tr.end_tr();
      end
      p_sequencer.irq_table[irq_tr.irq_vector].lock.put(1);
      
   endtask
endclass
`endif