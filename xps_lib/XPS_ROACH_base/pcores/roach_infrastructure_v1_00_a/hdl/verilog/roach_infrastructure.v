module roach_infrastructure(
    sys_clk_n, sys_clk_p,
    sys_clk, sys_clk90, sys_clk180, sys_clk270,
    dly_clk_n,  dly_clk_p,
    dly_clk,
    epb_clk_buf,
    epb_clk,
    idelay_rst, idelay_rdy,
    aux_clk_0_n, aux_clk_0_p,
    aux_clk_0,
    aux_clk_1_n, aux_clk_1_p,
    aux_clk_1
  );
  input  sys_clk_n, sys_clk_p;
  output sys_clk, sys_clk90, sys_clk180, sys_clk270;
  input  dly_clk_n, dly_clk_p;
  output dly_clk;
  input  epb_clk_buf;
  output epb_clk;
  input  aux_clk_0_n, aux_clk_0_p;
  output aux_clk_0;
  input  aux_clk_1_n, aux_clk_1_p;
  output aux_clk_1;

  input  idelay_rst;
  output idelay_rdy;


  /* EPB Clk */
  wire epb_clk_ibuf;

  IBUF ibuf_epb(
    .I(epb_clk_buf),
    .O(epb_clk_ibuf)
  );

  BUFG bufg_epb(
    .I(epb_clk_ibuf), .O(epb_clk)
  );

  /* system clock */
  wire sys_clk_int;
  wire sysclk_dcm_locked;

  IBUFGDS #(
    .IOSTANDARD("LVDS_25"),
    .DIFF_TERM("TRUE")
  ) ibufgd_sys (
    .I (sys_clk_p),
    .IB(sys_clk_n),
    .O (sys_clk_int)
  );

  wire sys_clk_dcm, sys_clk90_dcm;
  DCM_BASE #(
    .CLKIN_PERIOD(10.0)
  ) SYSCLK_DCM (
    .CLK0(sys_clk_dcm),
    .CLK180(),
    .CLK270(),
    .CLK2X(),
    .CLK2X180(),
    .CLK90(sys_clk90_dcm),
    .CLKDV(),
    .CLKFX(),
    .CLKFX180(),
    .LOCKED(sysclk_dcm_locked),
    .CLKFB(sys_clk),
    .CLKIN(sys_clk_int),
    .RST(1'b0)
  );

  BUFG bufg_sys_clk[1:0](
    .I({sys_clk_dcm, sys_clk90_dcm}),
    .O({sys_clk,     sys_clk90})
  );

  // rely on Xilinx internal clock inversion structures down the line
  assign sys_clk180 = ~sys_clk;
  assign sys_clk270 = ~sys_clk90;

  /* Aux clocks */
  wire  aux_clk_0_int;
  wire  aux_clk_1_int;
  IBUFGDS #(
    .IOSTANDARD("LVDS_25"),
    .DIFF_TERM("TRUE")
  ) ibufgd_aux_arr[1:0] (
    .I ({aux_clk_0_p,   aux_clk_1_p}),
    .IB({aux_clk_0_n,   aux_clk_1_n}),
    .O ({aux_clk_0_int, aux_clk_1_int})
  );

  wire  aux_clk_0_dcm;
  wire  aux_clk_1_dcm;

  DCM_BASE #(
    .CLKIN_PERIOD(5.0)
  ) AUXCLK0_DCM (
    .CLK0(  aux_clk_0_dcm),
    .LOCKED(),
    .CLKFB( aux_clk_0),
    .CLKIN( aux_clk_0_int),
    .RST(   ~sysclk_dcm_locked)
  );

  DCM_BASE #(
    .CLKIN_PERIOD(5.0)
  ) AUXCLK1_DCM (
    .CLK0(  aux_clk_1_dcm),
    .LOCKED(),
    .CLKFB( aux_clk_1),
    .CLKIN( aux_clk_1_int),
    .RST(   ~sysclk_dcm_locked)
  );

  BUFG bufg_aux_clk[1:0](
    .I({aux_clk_0_dcm, aux_clk_1_dcm}),
    .O({aux_clk_0,     aux_clk_1})
  );

  /* Delay Clock */
  wire dly_clk_int;
  IBUFDS ibufds_dly_clk(
    .I (dly_clk_p),
    .IB(dly_clk_n),
    .O (dly_clk_int)
  );

  BUFG bufg_inst(
    .I(dly_clk_int),
    .O(dly_clk)
  );

  IDELAYCTRL idelayctrl_inst(
    .REFCLK(dly_clk),
    .RST(idelay_rst),
    .RDY(idelay_rdy)
  );


endmodule
