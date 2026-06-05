// Copyright 2026 X-HEEP Contributors
// Solderpad Hardware License, Version 2.1, see LICENSE.md for details.
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Top-level module for the X-ALP SoC design.
// Author: Luigi Giuffrida <luigi.giuffrida@polito.it>
//

<%!
    from pads.pin import Input, Output, Inout, PinDigital, Asignal
%>

<%
    attribute_bits = xheep.get_padring().attributes.get("bits")
    any_muxed_pads = xheep.get_padring().num_muxed_pads() > 0
%>

module x_alp (

    // External Peripheral Interface
    output core_v_mcu_pkg::axi_slv_req_t ext_slv_req_o,
    input  core_v_mcu_pkg::axi_slv_rsp_t ext_slv_rsp_i,

    input  core_v_mcu_pkg::axi_mst_req_t ext_mst_req_i,
    output core_v_mcu_pkg::axi_mst_rsp_t ext_mst_rsp_o,

    output core_v_mcu_pkg::reg_req_t ext_reg_req_o,
    input  core_v_mcu_pkg::reg_rsp_t ext_reg_rsp_i,

    // Test mode
    input logic test_mode_i,

    // Exit interface
    output logic [31:0] exit_value_o,

    % for pad in xheep.get_padring().pad_list:
      <%
      has_input_pin = any(isinstance(pin, Input) for pin in pad.pins)
      has_output_pin = any(isinstance(pin, Output) for pin in pad.pins)
      has_inout_pin = any(isinstance(pin, Inout) for pin in pad.pins)

      if not (has_input_pin or has_output_pin or has_inout_pin):
        continue
      pin0_name = pad.pins[0].rtl_name()
      muxed_string = "_muxed" if pad.is_muxed() else ""
      %>\
      % if has_inout_pin or (has_input_pin and has_output_pin):
        inout wire ${pin0_name}io${"" if loop.last else ","}
      % elif has_input_pin:
        inout wire ${pin0_name}i${"" if loop.last else ","}
      % elif has_output_pin:
        inout wire ${pin0_name}o${"" if loop.last else ","}
      % endif
    % endfor

);

    core_v_mcu u_core_v_mcu (
    % for pin in xheep.get_padring().get_connected_pins():
      % if pin.module == "core_v_mcu":
        % if isinstance(pin, (Input, Inout)):
          .${pin.rtl_name()}i(${pin.rtl_name()}in_x),
        % endif
        % if isinstance(pin, (Output, Inout)):
          .${pin.rtl_name()}o(${pin.rtl_name()}out_x),
        % endif
        % if isinstance(pin, Inout):
          .${pin.rtl_name()}oe_o(${pin.rtl_name()}oe_x),
        % endif
      % endif
    % endfor
        .rst_ni       (rst_ngen),
        .boot_select_i(1'b0),
        .exit_value_o (exit_value_o),
        .test_mode_i  (test_mode_i),
        .ext_slv_req_o(ext_slv_req_o),
        .ext_slv_rsp_i(ext_slv_rsp_i),
        .ext_mst_req_i(ext_mst_req_i),
        .ext_mst_rsp_o(ext_mst_rsp_o),
        .ext_reg_req_o(ext_reg_req_o),
        .ext_reg_rsp_i(ext_reg_rsp_i)
    );

<%
analog_signal_pads = [ pad for pad in xheep.get_padring().pad_list if any(isinstance(pin, Asignal) for pin in pad.pins) ] 
%>
  pad_ring pad_ring_i (
    % for pad in xheep.get_padring().pad_list:
      <%
      has_input_pin = any(isinstance(pin, Input) for pin in pad.pins)
      has_output_pin = any(isinstance(pin, Output) for pin in pad.pins)
      has_inout_pin = any(isinstance(pin, Inout) for pin in pad.pins)

      if not (has_input_pin or has_output_pin or has_inout_pin):
        continue
      pin0_name = pad.pins[0].rtl_name()
      muxed_string = "_muxed" if pad.is_muxed() else ""
      %>\
      % if has_inout_pin or (has_input_pin and has_output_pin):
        .${pin0_name}i(${pin0_name}out_x${muxed_string}),
        .${pin0_name}oe_i(${pin0_name}oe_x${muxed_string}),
        .${pin0_name}o(${pin0_name}in_x${muxed_string}),
        .${pin0_name}io(${pin0_name}io),
      % elif has_input_pin:
        .${pin0_name}o(${pin0_name}in_x${muxed_string}),
        .${pin0_name}io(${pin0_name}i),
      % elif has_output_pin:
        .${pin0_name}i(${pin0_name}out_x${muxed_string}),
        .${pin0_name}io(${pin0_name}o${muxed_string}),
      % endif
    % endfor

    % if len(analog_signal_pads) > 0:
      `ifdef SYNTHESIS
        % for pad in analog_signal_pads:
          .${pad.name.lower()}_io,
        % endfor
      `endif
    %endif

    % if attribute_bits != None:
      .pad_attributes_i(pad_attributes)
    % else:
      .pad_attributes_i('0)
    % endif
  );

  // PAD controller
  core_v_mcu_pkg::reg_req_t pad_req;
  core_v_mcu_pkg::reg_rsp_t pad_resp;

  % if attribute_bits != None:
    logic [core_v_mcu_pkg::NUM_PAD-1:0][${attribute_bits}] pad_attributes;
  % endif
  % if any_muxed_pads:
    logic [core_v_mcu_pkg::NUM_PAD-1:0][${xheep.get_padring().get_muxed_pad_select_width()-1}:0] pad_muxes;
  % endif

  logic rst_ngen;

  // core_v_mcu input/output pins
  % for pad in xheep.get_padring().pad_list:
    % for pin in pad.pins:
      % if isinstance(pin, PinDigital):
        logic ${pin.rtl_name()}in_x, ${pin.rtl_name()}out_x, ${pin.rtl_name()}oe_x;
      % endif
    % endfor
    % if len(pad.pins) > 1 and any( isinstance(pin, PinDigital) for pin in pad.pins ):
      logic ${pad.pins[0].rtl_name()}in_x_muxed, ${pad.pins[0].rtl_name()}out_x_muxed, ${pad.pins[0].rtl_name()}oe_x_muxed;
    % endif
  % endfor


% for pin in xheep.get_padring().pin_list:
  % if isinstance(pin, Input):
    assign ${pin.rtl_name()}out_x = 1'b0;
    assign ${pin.rtl_name()}oe_x = 1'b0;
  % endif
  % if isinstance(pin, Output):
    assign ${pin.rtl_name()}oe_x = 1'b1;
  % endif
% endfor

// PAD MULTIPLEXERS
% for pad in [pad for pad in xheep.get_padring().pad_list if pad.is_muxed() and any(isinstance(pin, PinDigital) for pin in pad.pins)]:
  <% pin0_name = pad.pins[0].rtl_name() %>\
  always_comb
  begin
    % for pin in pad.pins:
      ${pin.rtl_name()}in_x = ${"1'b1" if pin.attributes.get("active") == "low" else "1'b0"};
    % endfor
    unique case(pad_muxes[core_v_mcu_pkg::PAD_${pad.name.upper()}])
      % for idx, pin in enumerate(pad.pins):
        ${idx}: begin
          <% pinidx_name = pin.rtl_name() %>
          ${pin0_name}out_x_muxed = ${pinidx_name}out_x;
          ${pin0_name}oe_x_muxed  = ${pinidx_name}oe_x;
          ${pinidx_name}in_x        = ${pin0_name}in_x_muxed;
        end
      % endfor
      default: begin
        ${pin0_name}out_x_muxed = ${pin0_name}out_x;
        ${pin0_name}oe_x_muxed  = ${pin0_name}oe_x;
        ${pin0_name}in_x        = ${pin0_name}in_x_muxed;
      end
    endcase
  end
% endfor

  pad_control #(
      .reg_req_t(core_v_mcu_pkg::reg_req_t),
      .reg_rsp_t(core_v_mcu_pkg::reg_rsp_t),
      .NUM_PAD  (core_v_mcu_pkg::NUM_PAD)
  ) pad_control_i (
      .clk_i(clk_in_x),
      .rst_ni(rst_ngen),
      .reg_req_i(pad_req),
      .reg_rsp_o(pad_resp)${"," if any_muxed_pads or attribute_bits != None else ""}
      % if attribute_bits != None:
        .pad_attributes_o(pad_attributes)${"," if any_muxed_pads else ""}
      % endif
      % if any_muxed_pads:
        .pad_muxes_o(pad_muxes)
      % endif
  );

  rstgen rstgen_i (
    .clk_i(clk_in_x),
    .rst_ni(rst_nin_x),
    .test_mode_i(1'b0),
    .rst_no(rst_ngen),
    .init_no()
  );


endmodule : x_alp
