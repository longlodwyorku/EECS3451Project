function Project()
    q1();
    q2();
end

function q1()
    f = figure("Name", "q1");
    band_edges = [500, 1500, 2000, 3000];
    amp = [0, 1, 0];
    dev = [0.01, 0.01, 0.001];
    [n,fo,ao,w] = firpmord(band_edges, amp, dev, 8000);
    h = firpm(n,fo,ao,w);
    tf(h, 1)
    freqz(h,1, 1024, 8000);
    saveas(f, "q1", "png");
end

function q2()
    function graphFilter(freqs, input, name)
        f = figure("Name", name);
        plot(freqs, abs(fft(input)));
        xlabel("frequency");
        ylabel("magnitude");
        title(name);
        saveas(f, name, "png");
    end

    function output = getDynamicFrequencyDomainFilter(input)
        abs_ft = abs(input);
        output = movmean(not(isoutlier(abs_ft, "percentiles",[0, 99.99])), 200) == 1;
    end

    function output = getDynamicTimeDomainFilter(input)
        output = ifft(getDynamicFrequencyDomainFilter(fft(input)));
    end

    function output = getParkMcClellanFilter()
        band_edges = [1070, 1090, 1120, 1140, 2710, 2730, 2800, 2820];
        amp = [1, 0, 1, 0, 1];
        dev = [0.008, 0.01, 0.008, 0.01, 0.008];
        [n,fo,ao,w] = firpmord(band_edges, amp, dev, fs);
        output = firpm(n,fo,ao,w);
    end

    function output = getKaiserFilter()
        band_edges = [1070, 1090, 1120, 1140, 2710, 2730, 2800, 2820];
        amp = [1, 0, 1, 0, 1];
        dev = [0.008, 0.01, 0.008, 0.01, 0.008];
        [n,Wn,beta,ftype] = kaiserord(band_edges,amp,dev, fs);
        output = fir1(n,Wn,ftype,kaiser(n+1,beta),'noscale');
    end

    function output = filterDynamicFrequencyDomain(input)
        ft = fft(input);
        H = getDynamicFrequencyDomainFilter(ft);
        f = figure("Name", "dynamic frequnecy domain filter");
        plot(freqs(1:length(freqs)/2), H(1:length(H)/2));
        xlabel("frequency");
        ylabel("magnitude");
        title("dynamic frequnecy domain filter");
        saveas(f, "dynamic frequnecy domain filter", "png");
        output = real(ifft(ft .* H));
    end

    function output = filterParkMcClellan(input)
        H = getParkMcClellanFilter();
        f = figure("Name", "Park McClellan filter");
        freqz(H(1:length(H)/2), 1, 1024, fs);
        saveas(f, "Park McClellan filter", "png");
        output = filter(H, 1, input);
    end

    function output = filterParkMcClellanTimeDomain(input)
        [h, t] = impz(getParkMcClellanFilter(), 1, fs);
        f = figure("Name", "Park McClellan time domain filter");
        plot(t, h);
        xlabel("time");
        ylabel("h");
        title("Park McClellan time domain filter");
        saveas(f, "Park McClellan time domain filter", "png");
        output = real(cconv(input, h, length(input)));
    end

    function output = filterDynamicTimeDomain(input)
        output = real(cconv(input, getDynamicTimeDomainFilter(input), length(input)));
    end

    function output = filterKaiser(input)
        H = getKaiserFilter();
        f = figure("Name", "Kaiser filter");
        freqz(H(1:length(H)/2), 1, 1024, fs);
        saveas(f, "Kaiser filter", "png");
        output = filter(H, 1, input);
    end
    
    function output = filterKaiserTimeDomain(input)
        [h, t] = impz(getKaiserFilter(), 1, fs);
        f = figure("Name", "Kaiser time domain filter");
        plot(t, h);
        xlabel("time");
        ylabel("h");
        title("Kaiser time domain filter");
        saveas(f, "Kaiser time domain filter", "png");
        output = real(cconv(input, h, length(input)));
    end

    [x, fs] = audioread("music_noisy.wav");
    fig = figure("Name", "fft magnitude noisy");
    fft_x = fft(x);
    freqs = (0 :(length(fft_x) - 1)) * fs / length(fft_x);
    plot(freqs, abs(fft_x));
    xlabel("frequency");
    ylabel("magnitude");
    title("fft magnitude noisy");
    saveas(fig, "fft magnitude noisy", "png");
    %
    y_pm = filterParkMcClellan(x);
    graphFilter(freqs, y_pm, "fft Park McClellan filtered signal");
    audiowrite("Park_McClellan.wav", y_pm, fs);

    y_df = filterDynamicFrequencyDomain(x);
    graphFilter(freqs, y_df, "fft dynamic frequency domain filter filtered signal");
    audiowrite("dynamic_frequency_domain_filter.wav", y_df, fs);

    y_dt = filterDynamicTimeDomain(x);
    graphFilter(freqs, y_dt, "fft dynamic time domain filter filtered signal");
    audiowrite("dynamic_time_domain_filter.wav", y_dt, fs);

    y_k = filterKaiser(x);
    graphFilter(freqs, y_k, "fft kaiser filter filtered signal");
    audiowrite("kaiser_filter.wav", y_k, fs);

    y_pmt = filterParkMcClellanTimeDomain(x);
    graphFilter(freqs, y_pmt, "fft park mcclellan time filtered signal");
    audiowrite("park_mcclellan_time_filter_filter.wav", y_k, fs);

    y_kt = filterKaiserTimeDomain(x);
    graphFilter(freqs, y_kt, "fft kaiser time filter filtered signal");
    audiowrite("kaiser_time_filter.wav", y_k, fs);
end
