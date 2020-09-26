classdef DeathCoil < audioPlugin                            % <== (1) Inherit from audioPlugin.
    properties (Access = private)                           % <== (2) Define tunable property.
        ampThd1 = 0.7;
        ampBias1 = 0.15;
        stretchMod1 = 0.3;
        thdReductionVal1 = 0.8;
        slopeDet = false;
        slopeFac = 0.99981;
        slopeThdUpper = 0.5;
        slopeThdLower = 0.4;
        saveVal = 0.5;
        slopeDiv = 1.4;
        %lpFilt = designfilt('lowpassiir','FilterOrder',2, ...
        % 'PassbandFrequency',fr.SampleRate/3,'PassbandRipple',0.25, ...
        % 'SampleRate',fr.SampleRate);
        
        c = 1;
    end
    properties (Constant)
        PluginInterface = audioPluginInterface();
    end
    methods
        function reset(plugin) %#ok<MANU>
            % initialize internal state
        end

        function out = process(plugin, in)                 %< == (4) Define audio processing.
            in1 = in(:,1); in2 = in(:,2);
            
            p1 = plugin.ProcessChannel(in1);
            p2 = plugin.ProcessChannel(in2);
            
            out = [p1 p2];
        end
        
        
        function out = ProcessChannel(plugin, in)
            s = in .* 3;
            wd = length(in);
            %s = filter(lpFilt, s);
            p = s ./ (abs(s) + plugin.stretchMod1) ;% + hann(wd) .* y;

            p(abs(p) > 1) = 1;
            p(p > plugin.ampThd1) = plugin.ampBias1 + s(p > plugin.ampThd1) * 1.15 + p(p > plugin.ampThd1) * 0.85;% + w(p > 0.1) * 2.85 ;
            %p(abs(p) < slopeThdUpper) = p(abs(p) < slopeThdUpper) ./ p(abs(p) < slopeThdUpper);
            p(p > 1) = 1 + max((1 - abs(p(p > 1))), 0.1);

            p(abs(p) > 1) = 0.99;
            %p(abs(p) < 0.01) = 0;

            for i = 1:wd
                if plugin.slopeDet
                    if p(i) < plugin.slopeThdLower
                        plugin.slopeDet = false;
                        continue
                    end

                    p(i) = plugin.saveVal * (plugin.slopeFac ^ (plugin.c / plugin.slopeDiv)) + (p(i) / 4 - 0.25);

                    plugin.c = plugin.c + 1;
                end

                if (p(i) > plugin.slopeThdUpper) && ~plugin.slopeDet
                    plugin.slopeDet = true;
                    plugin.saveVal = p(i);
                    p(i) = p(i) * plugin.thdReductionVal1;

                    if p(i) > plugin.slopeThdUpper
                        p(i) = plugin.slopeThdUpper * plugin.thdReductionVal1;
                    end
                    
                    plugin.c = 1;
                end
            end
            
            p(abs(p) > 1) = 0.99;
            
            out = p;
        end
    end
end