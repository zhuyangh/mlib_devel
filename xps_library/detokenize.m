function detokenize(in_fid, out_fid, xps_objs);

xsg_obj = xps_objs{1};

hw_sys         = get(xsg_obj,'hw_sys');
sw_os          = get(xsg_obj,'sw_os');
app_clk        = get(xsg_obj,'clk_src');
app_clk_freq   = get(xsg_obj,'clk_rate');
sys_clk_freq  = 100;
aux_clk_freq  = 100;
mkdig_sys_clk_freq = 156.25;
multiply       = 1;
divide         = 1;
divclk         = 1;

if strcmp(hw_sys, 'ROACH2')
   if strcmp(app_clk, 'sys_clk')
      [sys_multiply sys_divide sys_divclk] = clk_factors(sys_clk_freq, app_clk_freq);
      [aux_multiply aux_divide aux_divclk] = clk_factors(aux_clk_freq, aux_clk_freq);
      fprintf(strcat('Running off sys_clk @ ', int2str(sys_clk_freq*sys_multiply/sys_divide/sys_divclk), 'MHz','\n'))
   elseif strcmp(app_clk, 'aux_clk')
      aux_clk_freq = app_clk_freq;
      [sys_multiply sys_divide sys_divclk] = clk_factors(sys_clk_freq, sys_clk_freq);
      [aux_multiply aux_divide aux_divclk] = clk_factors(aux_clk_freq, aux_clk_freq);
      fprintf(strcat('Running off aux_clk @ ', int2str(app_clk_freq), 'MHz', '\n'))
   else
      [sys_multiply sys_divide sys_divclk] = clk_factors(sys_clk_freq, sys_clk_freq);
      fprintf(strcat('Running off adc_clk @ ', int2str(app_clk_freq), 'MHz','\n'))
   end
   if aux_clk_freq < 135
      aux_clk_high_low = 'low';
   else
      aux_clk_high_low = 'high';
   end
   sys_clk_high_low = 'low';
end

if strcmp(hw_sys, 'MKDIG')
   if strcmp(app_clk, 'sys_clk')
      [multiply divide divclk] = clk_factors(mkdig_sys_clk_freq, app_clk_freq);
      fprintf(strcat('Running off sys_clk @ ', int2str(mkdig_sys_clk_freq*multiply/divide/divclk), 'MHz','\n'))
   else
      [multiply divide divclk] = clk_factors(app_clk_freq, app_clk_freq);
      fprintf(strcat('Running off adc_clk @ ', int2str(app_clk_freq), 'MHz','\n')) 
   end
   if mkdig_sys_clk_freq < 135
      clk_high_low = 'low';
   else
      clk_high_low = 'high';
   end
end

while 1
    line = fgets(in_fid);
    if ~ischar(line)
        break;
    else
        toks = regexp(line,'(.*)#IF#(.*?)#(.*)','tokens');
        if isempty(toks)
            fprintf(out_fid,line);
        else
            default   = toks{1}{1};
            condition = toks{1}{2};
            real_line = toks{1}{3};
            condition_met = 0;
            for i = 1:length(xps_objs)
                b = xps_objs{i};
                try
                    if eval(condition)
                        condition_met = 1;
                        try
                            real_line = eval(real_line);
                        end
                        fprintf(out_fid,real_line);
                        break;
                    end
                end
            end
            if ~condition_met & ~isempty(default)
                fprintf(out_fid, [default, '\n']);
            end
        end
    end
end

