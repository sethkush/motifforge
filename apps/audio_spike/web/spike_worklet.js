// AudioWorklet side of the web audio engine (see lib/engine/engine_factory_web.dart).
//
// The synth runs in a Web Worker and posts interleaved stereo Float32Array
// chunks straight to this processor over a MessagePort: the page's main
// thread is not on the audio path, so UI work can't starve it. The processor
// reports how many frames it has actually played every ~10 ms, which the
// worker uses for backpressure (it keeps only `lookaheadMs` of audio queued).
class SpikeProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this.data = null;
    this.reset();
    this.port.onmessage = (e) => {
      if (e.data && e.data.type === 'port') {
        this.data = e.data.port;
        this.data.onmessage = (m) => this.onData(m.data);
        this.reset();
      }
    };
  }

  reset() {
    this.queue = [];
    this.readPos = 0;
    this.played = 0;
    this.underruns = 0;
    this.started = false;
    this.lastReport = 0;
  }

  onData(d) {
    if (d instanceof Float32Array) {
      this.queue.push(d);
    } else if (d && d.t === 'reset') {
      this.reset();
    }
  }

  process(inputs, outputs) {
    const out = outputs[0];
    const left = out[0];
    const right = out.length > 1 ? out[1] : out[0];
    const n = left.length;
    let i = 0;
    while (i < n && this.queue.length > 0) {
      const buf = this.queue[0];
      const frames = buf.length >> 1;
      const take = Math.min(frames - this.readPos, n - i);
      for (let k = 0; k < take; k++) {
        const j = (this.readPos + k) << 1;
        left[i + k] = buf[j];
        right[i + k] = buf[j + 1];
      }
      i += take;
      this.readPos += take;
      if (this.readPos >= frames) {
        this.queue.shift();
        this.readPos = 0;
      }
    }
    this.played += i;
    if (i > 0) this.started = true;
    if (i < n) {
      for (; i < n; i++) {
        left[i] = 0;
        right[i] = 0;
      }
      // Only a shortfall after playback began is an underrun.
      if (this.started) this.underruns++;
    }
    if (this.data && this.played - this.lastReport >= 480) {
      this.lastReport = this.played;
      this.data.postMessage({ t: 's', played: this.played, underruns: this.underruns });
    }
    return true;
  }
}

registerProcessor('spike-processor', SpikeProcessor);
