`include "jvs_irq_base_test.sv"

class jvs_width_pin_handler extends jvs_irq_handler;
   irq_drv_seq pins = new("pins");
   int unsigned expected_pin, deliveries;
   virtual task do_handle(jvs_irq_trans tr);
      if (tr.irq_vector != expected_pin)
         `uvm_fatal("IRQ_PIN", $sformatf("Expected pin %0d, got %0d", expected_pin, tr.irq_vector))
      pins.clear_int(expected_pin);
      deliveries++;
      tr.handle_state = jvs_irq_trans::FINISH;
   endtask
   virtual function jvs_irq_result_trans gen_result(jvs_irq_trans tr);
      return null;
   endfunction
endclass

class jvs_irq_width_test extends uvm_test;
   `uvm_component_utils(jvs_irq_width_test)
   jvs_irq_env #(1) single;
   jvs_irq_env #(4) multi;

   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction
   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      uvm_config_db#(int)::set(this, "*.jvs_int_agent", "is_active", UVM_ACTIVE);
      single = jvs_irq_env#(1)::type_id::create("single", this);
      multi = jvs_irq_env#(4)::type_id::create("multi", this);
   endfunction
   virtual task main_phase(uvm_phase phase);
      jvs_width_pin_handler first = new, last = new;
      phase.raise_objection(this);
      if ($bits(single.jvs_int_ag.int_if.interrupt) != 1 || $bits(multi.jvs_int_ag.int_if.interrupt) != 4)
         `uvm_fatal("IRQ_WIDTH", "Incorrect pin interface widths")
      first.pins.int_seqr = single.jvs_int_ag.int_seqr;
      last.pins.int_seqr = multi.jvs_int_ag.int_seqr;
      last.expected_pin = 3;
      single.register_irq(0, first);
      multi.register_irq(3, last);
      fork
         first.pins.trigger_int(0);
         last.pins.trigger_int(3);
      join
      wait (first.deliveries && last.deliveries);
      @(posedge single.jvs_int_ag.int_if.clk);
      if (first.deliveries != 1 || last.deliveries != 1 ||
          single.jvs_int_ag.int_if.interrupt != 0 || multi.jvs_int_ag.int_if.interrupt != 0)
         `uvm_fatal("IRQ_DELIVERY", "Both handlers must service and clear their own pin exactly once")
      `uvm_info("IRQ_WIDTH_PASS", "Observed and cleared independent one- and four-pin interfaces", UVM_NONE)
      phase.drop_objection(this);
   endtask
endclass
