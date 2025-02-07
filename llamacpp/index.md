# README.md

### Server benchmark tools

Benchmark is using k6.

##### Install k6 and sse extension

SSE is not supported by default in k6, you have to build k6 with the xk6-sse extension.

Example (assuming golang >= 1.21 is installed):

```shell
go install go.k6.io/xk6/cmd/xk6@latest
$GOPATH/bin/xk6 build master \
--with github.com/phymbert/xk6-sse
```

#### Download a dataset

This dataset was originally proposed in vLLM benchmarks.

```shell
wget https://huggingface.co/datasets/anon8231489123/ShareGPT_Vicuna_unfiltered/resolve/main/ShareGPT_V3_unfiltered_cleaned_split.json
```

#### Download a model

Example for PHI-2

```shell
../../../scripts/hf.sh --repo ggml-org/models --file phi-2/ggml-model-q4_0.gguf
```

#### Start the server

The server must answer OAI Chat completion requests on `http://localhost:8080/v1` or according to the environment variable `SERVER_BENCH_URL`.

Example:

```shell
llama-server --host localhost --port 8080 \
  --model ggml-model-q4_0.gguf \
  --cont-batching \
  --metrics \
  --parallel 8 \
  --batch-size 512 \
  --ctx-size 4096 \
  -ngl 33
```

#### Run the benchmark

For 500 chat completions request with 8 concurrent users during maximum 10 minutes, run:

```shell
./k6 run script.js --duration 10m --iterations 500 --vus 8
```

The benchmark values can be overridden with:

* `SERVER_BENCH_URL` server url prefix for chat completions, default `http://localhost:8080/v1`
* `SERVER_BENCH_N_PROMPTS` total prompts to randomly select in the benchmark, default `480`
* `SERVER_BENCH_MODEL_ALIAS` model alias to pass in the completion request, default `my-model`
* `SERVER_BENCH_MAX_TOKENS` max tokens to predict, default: `512`
* `SERVER_BENCH_DATASET` path to the benchmark dataset file
* `SERVER_BENCH_MAX_PROMPT_TOKENS` maximum prompt tokens to filter out in the dataset: default `1024`
* `SERVER_BENCH_MAX_CONTEXT` maximum context size of the completions request to filter out in the dataset: prompt + predicted tokens, default `2048`

Note: the local tokenizer is just a string space split, real number of tokens will differ.

Or with k6 options:

```shell
SERVER_BENCH_N_PROMPTS=500 k6 run script.js --duration 10m --iterations 500 --vus 8
```

To debug http request use `--http-debug="full"`.

#### Metrics

Following metrics are available computed from the OAI chat completions response `usage`:

* `llamacpp_tokens_second` Trend of `usage.total_tokens / request duration`
* `llamacpp_prompt_tokens` Trend of `usage.prompt_tokens`
* `llamacpp_prompt_tokens_total_counter` Counter of `usage.prompt_tokens`
* `llamacpp_completion_tokens` Trend of `usage.completion_tokens`
* `llamacpp_completion_tokens_total_counter` Counter of `usage.completion_tokens`
* `llamacpp_completions_truncated_rate` Rate of completions truncated, i.e. if `finish_reason === 'length'`
* `llamacpp_completions_stop_rate` Rate of completions stopped by the model, i.e. if `finish_reason === 'stop'`

The script will fail if too many completions are truncated, see `llamacpp_completions_truncated_rate`.

K6 metrics might be compared against server metrics, with:

```shell
curl http://localhost:8080/metrics
```

### Using the CI python script

The `bench.py` script does several steps:

* start the server
* define good variable for k6
* run k6 script
* extract metrics from prometheus

It aims to be used in the CI, but you can run it manually:

```shell
LLAMA_SERVER_BIN_PATH=../../../cmake-build-release/bin/llama-server python bench.py \
              --runner-label local \
              --name local \
              --branch `git rev-parse --abbrev-ref HEAD` \
              --commit `git rev-parse HEAD` \
              --scenario script.js \
              --duration 5m \
              --hf-repo ggml-org/models	 \
              --hf-file phi-2/ggml-model-q4_0.gguf \
              --model-path-prefix models \
              --parallel 4 \
              -ngl 33 \
              --batch-size 2048 \
              --ubatch-size	256 \
              --ctx-size 4096 \
              --n-prompts 200 \
              --max-prompt-tokens 256 \
              --max-tokens 256
```

# README.md

# Server tests

Python based server tests scenario using pytest.

Tests target GitHub workflows job runners with 4 vCPU.

Note: If the host architecture inference speed is faster than GitHub runners one, parallel scenario may randomly fail.
To mitigate it, you can increase values in `n_predict`, `kv_size`.

### Install dependencies

`pip install -r requirements.txt`

### Run tests

1. Build the server

```shell
cd ../../..
cmake -B build -DLLAMA_CURL=ON
cmake --build build --target llama-server
```

2. Start the test: `./tests.sh`

It's possible to override some scenario steps values with environment variables:

| variable                 | description                                                                                    |
|--------------------------|------------------------------------------------------------------------------------------------|
| `PORT`                   | `context.server_port` to set the listening port of the server during scenario, default: `8080` |
| `LLAMA_SERVER_BIN_PATH`  | to change the server binary path, default: `../../../build/bin/llama-server`                         |
| `DEBUG`                  | to enable steps and server verbose mode `--verbose`                                       |
| `N_GPU_LAYERS`           | number of model layers to offload to VRAM `-ngl --n-gpu-layers`                                |
| `LLAMA_CACHE`            | by default server tests re-download models to the `tmp` subfolder. Set this to your cache (e.g. `$HOME/Library/Caches/llama.cpp` on Mac or `$HOME/.cache/llama.cpp` on Unix) to avoid this |

To run slow tests (will download many models, make sure to set `LLAMA_CACHE` if needed):

```shell
SLOW_TESTS=1 ./tests.sh
```

To run with stdout/stderr display in real time (verbose output, but useful for debugging):

```shell
DEBUG=1 ./tests.sh -s -v -x
```

To run all the tests in a file:

```shell
./tests.sh unit/test_chat_completion.py.py -v -x
```

To run a single test:

```shell
./tests.sh unit/test_chat_completion.py::test_invalid_chat_completion_req
```

Hint: You can compile and run test in single command, useful for local developement:

```shell
cmake --build build -j --target llama-server && ./examples/server/tests/tests.sh
```

To see all available arguments, please refer to pytest documentation

# README.md

# LLaMA.cpp HTTP Server

Fast, lightweight, pure C/C++ HTTP server based on httplib, nlohmann::json and **llama.cpp**.

Set of LLM REST APIs and a simple web front end to interact with llama.cpp.

**Features:**

* LLM inference of F16 and quantized models on GPU and CPU
* OpenAI API compatible chat completions and embeddings routes
* Reranking endoint (WIP: https://github.com/ggerganov/llama.cpp/pull/9510)
* Parallel decoding with multi-user support
* Continuous batching
* Multimodal (wip)
* Monitoring endpoints
* Schema-constrained JSON response format

The project is under active development, and we are looking for feedback and contributors.

## Usage

<!-- Note for contributors: The list below is generated by llama-gen-docs -->

**Common params**

| Argument | Explanation |
| -------- | ----------- |
| `-h, --help, --usage` | print usage and exit |
| `--version` | show version and build info |
| `--verbose-prompt` | print a verbose prompt before generation (default: false) |
| `-t, --threads N` | number of threads to use during generation (default: -1)<br/>(env: LLAMA\_ARG\_THREADS) |
| `-tb, --threads-batch N` | number of threads to use during batch and prompt processing (default: same as --threads) |
| `-C, --cpu-mask M` | CPU affinity mask: arbitrarily long hex. Complements cpu-range (default: "") |
| `-Cr, --cpu-range lo-hi` | range of CPUs for affinity. Complements --cpu-mask |
| `--cpu-strict <0\|1>` | use strict CPU placement (default: 0)<br/> |
| `--prio N` | set process/thread priority : 0-normal, 1-medium, 2-high, 3-realtime (default: 0)<br/> |
| `--poll <0...100>` | use polling level to wait for work (0 - no polling, default: 50)<br/> |
| `-Cb, --cpu-mask-batch M` | CPU affinity mask: arbitrarily long hex. Complements cpu-range-batch (default: same as --cpu-mask) |
| `-Crb, --cpu-range-batch lo-hi` | ranges of CPUs for affinity. Complements --cpu-mask-batch |
| `--cpu-strict-batch <0\|1>` | use strict CPU placement (default: same as --cpu-strict) |
| `--prio-batch N` | set process/thread priority : 0-normal, 1-medium, 2-high, 3-realtime (default: 0)<br/> |
| `--poll-batch <0\|1>` | use polling to wait for work (default: same as --poll) |
| `-c, --ctx-size N` | size of the prompt context (default: 4096, 0 = loaded from model)<br/>(env: LLAMA\_ARG\_CTX\_SIZE) |
| `-n, --predict, --n-predict N` | number of tokens to predict (default: -1, -1 = infinity, -2 = until context filled)<br/>(env: LLAMA\_ARG\_N\_PREDICT) |
| `-b, --batch-size N` | logical maximum batch size (default: 2048)<br/>(env: LLAMA\_ARG\_BATCH) |
| `-ub, --ubatch-size N` | physical maximum batch size (default: 512)<br/>(env: LLAMA\_ARG\_UBATCH) |
| `--keep N` | number of tokens to keep from the initial prompt (default: 0, -1 = all) |
| `-fa, --flash-attn` | enable Flash Attention (default: disabled)<br/>(env: LLAMA\_ARG\_FLASH\_ATTN) |
| `--no-perf` | disable internal libllama performance timings (default: false)<br/>(env: LLAMA\_ARG\_NO\_PERF) |
| `-e, --escape` | process escapes sequences (\n, \r, \t, ', ", \\) (default: true) |
| `--no-escape` | do not process escape sequences |
| `--rope-scaling {none,linear,yarn}` | RoPE frequency scaling method, defaults to linear unless specified by the model<br/>(env: LLAMA\_ARG\_ROPE\_SCALING\_TYPE) |
| `--rope-scale N` | RoPE context scaling factor, expands context by a factor of N<br/>(env: LLAMA\_ARG\_ROPE\_SCALE) |
| `--rope-freq-base N` | RoPE base frequency, used by NTK-aware scaling (default: loaded from model)<br/>(env: LLAMA\_ARG\_ROPE\_FREQ\_BASE) |
| `--rope-freq-scale N` | RoPE frequency scaling factor, expands context by a factor of 1/N<br/>(env: LLAMA\_ARG\_ROPE\_FREQ\_SCALE) |
| `--yarn-orig-ctx N` | YaRN: original context size of model (default: 0 = model training context size)<br/>(env: LLAMA\_ARG\_YARN\_ORIG\_CTX) |
| `--yarn-ext-factor N` | YaRN: extrapolation mix factor (default: -1.0, 0.0 = full interpolation)<br/>(env: LLAMA\_ARG\_YARN\_EXT\_FACTOR) |
| `--yarn-attn-factor N` | YaRN: scale sqrt(t) or attention magnitude (default: 1.0)<br/>(env: LLAMA\_ARG\_YARN\_ATTN\_FACTOR) |
| `--yarn-beta-slow N` | YaRN: high correction dim or alpha (default: 1.0)<br/>(env: LLAMA\_ARG\_YARN\_BETA\_SLOW) |
| `--yarn-beta-fast N` | YaRN: low correction dim or beta (default: 32.0)<br/>(env: LLAMA\_ARG\_YARN\_BETA\_FAST) |
| `-dkvc, --dump-kv-cache` | verbose print of the KV cache |
| `-nkvo, --no-kv-offload` | disable KV offload<br/>(env: LLAMA\_ARG\_NO\_KV\_OFFLOAD) |
| `-ctk, --cache-type-k TYPE` | KV cache data type for K<br/>allowed values: f32, f16, bf16, q8\_0, q4\_0, q4\_1, iq4\_nl, q5\_0, q5\_1<br/>(default: f16)<br/>(env: LLAMA\_ARG\_CACHE\_TYPE\_K) |
| `-ctv, --cache-type-v TYPE` | KV cache data type for V<br/>allowed values: f32, f16, bf16, q8\_0, q4\_0, q4\_1, iq4\_nl, q5\_0, q5\_1<br/>(default: f16)<br/>(env: LLAMA\_ARG\_CACHE\_TYPE\_V) |
| `-dt, --defrag-thold N` | KV cache defragmentation threshold (default: 0.1, < 0 - disabled)<br/>(env: LLAMA\_ARG\_DEFRAG\_THOLD) |
| `-np, --parallel N` | number of parallel sequences to decode (default: 1)<br/>(env: LLAMA\_ARG\_N\_PARALLEL) |
| `--mlock` | force system to keep model in RAM rather than swapping or compressing<br/>(env: LLAMA\_ARG\_MLOCK) |
| `--no-mmap` | do not memory-map model (slower load but may reduce pageouts if not using mlock)<br/>(env: LLAMA\_ARG\_NO\_MMAP) |
| `--numa TYPE` | attempt optimizations that help on some NUMA systems<br/>- distribute: spread execution evenly over all nodes<br/>- isolate: only spawn threads on CPUs on the node that execution started on<br/>- numactl: use the CPU map provided by numactl<br/>if run without this previously, it is recommended to drop the system page cache before using this<br/>see https://github.com/ggerganov/llama.cpp/issues/1437<br/>(env: LLAMA\_ARG\_NUMA) |
| `-dev, --device <dev1,dev2,..>` | comma-separated list of devices to use for offloading (none = don't offload)<br/>use --list-devices to see a list of available devices<br/>(env: LLAMA\_ARG\_DEVICE) |
| `--list-devices` | print list of available devices and exit |
| `-ngl, --gpu-layers, --n-gpu-layers N` | number of layers to store in VRAM<br/>(env: LLAMA\_ARG\_N\_GPU\_LAYERS) |
| `-sm, --split-mode {none,layer,row}` | how to split the model across multiple GPUs, one of:<br/>- none: use one GPU only<br/>- layer (default): split layers and KV across GPUs<br/>- row: split rows across GPUs<br/>(env: LLAMA\_ARG\_SPLIT\_MODE) |
| `-ts, --tensor-split N0,N1,N2,...` | fraction of the model to offload to each GPU, comma-separated list of proportions, e.g. 3,1<br/>(env: LLAMA\_ARG\_TENSOR\_SPLIT) |
| `-mg, --main-gpu INDEX` | the GPU to use for the model (with split-mode = none), or for intermediate results and KV (with split-mode = row) (default: 0)<br/>(env: LLAMA\_ARG\_MAIN\_GPU) |
| `--check-tensors` | check model tensor data for invalid values (default: false) |
| `--override-kv KEY=TYPE:VALUE` | advanced option to override model metadata by key. may be specified multiple times.<br/>types: int, float, bool, str. example: --override-kv tokenizer.ggml.add\_bos\_token=bool:false |
| `--lora FNAME` | path to LoRA adapter (can be repeated to use multiple adapters) |
| `--lora-scaled FNAME SCALE` | path to LoRA adapter with user defined scaling (can be repeated to use multiple adapters) |
| `--control-vector FNAME` | add a control vector<br/>note: this argument can be repeated to add multiple control vectors |
| `--control-vector-scaled FNAME SCALE` | add a control vector with user defined scaling SCALE<br/>note: this argument can be repeated to add multiple scaled control vectors |
| `--control-vector-layer-range START END` | layer range to apply the control vector(s) to, start and end inclusive |
| `-m, --model FNAME` | model path (default: `models/$filename` with filename from `--hf-file` or `--model-url` if set, otherwise models/7B/ggml-model-f16.gguf)<br/>(env: LLAMA\_ARG\_MODEL) |
| `-mu, --model-url MODEL_URL` | model download url (default: unused)<br/>(env: LLAMA\_ARG\_MODEL\_URL) |
| `-hfr, --hf-repo REPO` | Hugging Face model repository (default: unused)<br/>(env: LLAMA\_ARG\_HF\_REPO) |
| `-hff, --hf-file FILE` | Hugging Face model file (default: unused)<br/>(env: LLAMA\_ARG\_HF\_FILE) |
| `-hft, --hf-token TOKEN` | Hugging Face access token (default: value from HF\_TOKEN environment variable)<br/>(env: HF\_TOKEN) |
| `--log-disable` | Log disable |
| `--log-file FNAME` | Log to file |
| `--log-colors` | Enable colored logging<br/>(env: LLAMA\_LOG\_COLORS) |
| `-v, --verbose, --log-verbose` | Set verbosity level to infinity (i.e. log all messages, useful for debugging) |
| `-lv, --verbosity, --log-verbosity N` | Set the verbosity threshold. Messages with a higher verbosity will be ignored.<br/>(env: LLAMA\_LOG\_VERBOSITY) |
| `--log-prefix` | Enable prefx in log messages<br/>(env: LLAMA\_LOG\_PREFIX) |
| `--log-timestamps` | Enable timestamps in log messages<br/>(env: LLAMA\_LOG\_TIMESTAMPS) |

**Sampling params**

| Argument | Explanation |
| -------- | ----------- |
| `--samplers SAMPLERS` | samplers that will be used for generation in the order, separated by ';'<br/>(default: dry;top\_k;typ\_p;top\_p;min\_p;xtc;temperature) |
| `-s, --seed SEED` | RNG seed (default: -1, use random seed for -1) |
| `--sampling-seq SEQUENCE` | simplified sequence for samplers that will be used (default: dkypmxt) |
| `--ignore-eos` | ignore end of stream token and continue generating (implies --logit-bias EOS-inf) |
| `--temp N` | temperature (default: 0.8) |
| `--top-k N` | top-k sampling (default: 40, 0 = disabled) |
| `--top-p N` | top-p sampling (default: 0.9, 1.0 = disabled) |
| `--min-p N` | min-p sampling (default: 0.1, 0.0 = disabled) |
| `--xtc-probability N` | xtc probability (default: 0.0, 0.0 = disabled) |
| `--xtc-threshold N` | xtc threshold (default: 0.1, 1.0 = disabled) |
| `--typical N` | locally typical sampling, parameter p (default: 1.0, 1.0 = disabled) |
| `--repeat-last-n N` | last n tokens to consider for penalize (default: 64, 0 = disabled, -1 = ctx\_size) |
| `--repeat-penalty N` | penalize repeat sequence of tokens (default: 1.0, 1.0 = disabled) |
| `--presence-penalty N` | repeat alpha presence penalty (default: 0.0, 0.0 = disabled) |
| `--frequency-penalty N` | repeat alpha frequency penalty (default: 0.0, 0.0 = disabled) |
| `--dry-multiplier N` | set DRY sampling multiplier (default: 0.0, 0.0 = disabled) |
| `--dry-base N` | set DRY sampling base value (default: 1.75) |
| `--dry-allowed-length N` | set allowed length for DRY sampling (default: 2) |
| `--dry-penalty-last-n N` | set DRY penalty for the last n tokens (default: -1, 0 = disable, -1 = context size) |
| `--dry-sequence-breaker STRING` | add sequence breaker for DRY sampling, clearing out default breakers ('\n', ':', '"', '\*') in the process; use "none" to not use any sequence breakers<br/> |
| `--dynatemp-range N` | dynamic temperature range (default: 0.0, 0.0 = disabled) |
| `--dynatemp-exp N` | dynamic temperature exponent (default: 1.0) |
| `--mirostat N` | use Mirostat sampling.<br/>Top K, Nucleus and Locally Typical samplers are ignored if used.<br/>(default: 0, 0 = disabled, 1 = Mirostat, 2 = Mirostat 2.0) |
| `--mirostat-lr N` | Mirostat learning rate, parameter eta (default: 0.1) |
| `--mirostat-ent N` | Mirostat target entropy, parameter tau (default: 5.0) |
| `-l, --logit-bias TOKEN_ID(+/-)BIAS` | modifies the likelihood of token appearing in the completion,<br/>i.e. `--logit-bias 15043+1` to increase likelihood of token ' Hello',<br/>or `--logit-bias 15043-1` to decrease likelihood of token ' Hello' |
| `--grammar GRAMMAR` | BNF-like grammar to constrain generations (see samples in grammars/ dir) (default: '') |
| `--grammar-file FNAME` | file to read grammar from |
| `-j, --json-schema SCHEMA` | JSON schema to constrain generations (https://json-schema.org/), e.g. `{}` for any JSON object<br/>For schemas w/ external $refs, use --grammar + example/json\_schema\_to\_grammar.py instead |
| `--jinja` | Enable experimental Jinja templating engine (required for tool use) |

**Example-specific params**

| Argument | Explanation |
| -------- | ----------- |
| `--no-context-shift` | disables context shift on inifinite text generation (default: disabled)<br/>(env: LLAMA\_ARG\_NO\_CONTEXT\_SHIFT) |
| `-sp, --special` | special tokens output enabled (default: false) |
| `--no-warmup` | skip warming up the model with an empty run |
| `--spm-infill` | use Suffix/Prefix/Middle pattern for infill (instead of Prefix/Suffix/Middle) as some models prefer this. (default: disabled) |
| `--pooling {none,mean,cls,last,rank}` | pooling type for embeddings, use model default if unspecified<br/>(env: LLAMA\_ARG\_POOLING) |
| `-cb, --cont-batching` | enable continuous batching (a.k.a dynamic batching) (default: enabled)<br/>(env: LLAMA\_ARG\_CONT\_BATCHING) |
| `-nocb, --no-cont-batching` | disable continuous batching<br/>(env: LLAMA\_ARG\_NO\_CONT\_BATCHING) |
| `-a, --alias STRING` | set alias for model name (to be used by REST API)<br/>(env: LLAMA\_ARG\_ALIAS) |
| `--host HOST` | ip address to listen (default: 127.0.0.1)<br/>(env: LLAMA\_ARG\_HOST) |
| `--port PORT` | port to listen (default: 8080)<br/>(env: LLAMA\_ARG\_PORT) |
| `--path PATH` | path to serve static files from (default: )<br/>(env: LLAMA\_ARG\_STATIC\_PATH) |
| `--no-webui` | Disable the Web UI (default: enabled)<br/>(env: LLAMA\_ARG\_NO\_WEBUI) |
| `--embedding, --embeddings` | restrict to only support embedding use case; use only with dedicated embedding models (default: disabled)<br/>(env: LLAMA\_ARG\_EMBEDDINGS) |
| `--reranking, --rerank` | enable reranking endpoint on server (default: disabled)<br/>(env: LLAMA\_ARG\_RERANKING) |
| `--api-key KEY` | API key to use for authentication (default: none)<br/>(env: LLAMA\_API\_KEY) |
| `--api-key-file FNAME` | path to file containing API keys (default: none) |
| `--ssl-key-file FNAME` | path to file a PEM-encoded SSL private key<br/>(env: LLAMA\_ARG\_SSL\_KEY\_FILE) |
| `--ssl-cert-file FNAME` | path to file a PEM-encoded SSL certificate<br/>(env: LLAMA\_ARG\_SSL\_CERT\_FILE) |
| `-to, --timeout N` | server read/write timeout in seconds (default: 600)<br/>(env: LLAMA\_ARG\_TIMEOUT) |
| `--threads-http N` | number of threads used to process HTTP requests (default: -1)<br/>(env: LLAMA\_ARG\_THREADS\_HTTP) |
| `--cache-reuse N` | min chunk size to attempt reusing from the cache via KV shifting (default: 0)<br/>(env: LLAMA\_ARG\_CACHE\_REUSE) |
| `--metrics` | enable prometheus compatible metrics endpoint (default: disabled)<br/>(env: LLAMA\_ARG\_ENDPOINT\_METRICS) |
| `--slots` | enable slots monitoring endpoint (default: disabled)<br/>(env: LLAMA\_ARG\_ENDPOINT\_SLOTS) |
| `--props` | enable changing global properties via POST /props (default: disabled)<br/>(env: LLAMA\_ARG\_ENDPOINT\_PROPS) |
| `--no-slots` | disables slots monitoring endpoint<br/>(env: LLAMA\_ARG\_NO\_ENDPOINT\_SLOTS) |
| `--slot-save-path PATH` | path to save slot kv cache (default: disabled) |
| `--chat-template JINJA_TEMPLATE` | set custom jinja chat template (default: template taken from model's metadata)<br/>if suffix/prefix are specified, template will be disabled<br/>list of built-in templates:<br/>chatglm3, chatglm4, chatml, command-r, deepseek, deepseek2, exaone3, gemma, granite, llama2, llama2-sys, llama2-sys-bos, llama2-sys-strip, llama3, minicpm, mistral-v1, mistral-v3, mistral-v3-tekken, mistral-v7, monarch, openchat, orion, phi3, rwkv-world, vicuna, vicuna-orca, zephyr<br/>(env: LLAMA\_ARG\_CHAT\_TEMPLATE) |
| `-sps, --slot-prompt-similarity SIMILARITY` | how much the prompt of a request must match the prompt of a slot in order to use that slot (default: 0.50, 0.0 = disabled)<br/> |
| `--lora-init-without-apply` | load LoRA adapters without applying them (apply later via POST /lora-adapters) (default: disabled) |
| `--draft-max, --draft, --draft-n N` | number of tokens to draft for speculative decoding (default: 16)<br/>(env: LLAMA\_ARG\_DRAFT\_MAX) |
| `--draft-min, --draft-n-min N` | minimum number of draft tokens to use for speculative decoding (default: 5)<br/>(env: LLAMA\_ARG\_DRAFT\_MIN) |
| `--draft-p-min P` | minimum speculative decoding probability (greedy) (default: 0.9)<br/>(env: LLAMA\_ARG\_DRAFT\_P\_MIN) |
| `-cd, --ctx-size-draft N` | size of the prompt context for the draft model (default: 0, 0 = loaded from model)<br/>(env: LLAMA\_ARG\_CTX\_SIZE\_DRAFT) |
| `-devd, --device-draft <dev1,dev2,..>` | comma-separated list of devices to use for offloading the draft model (none = don't offload)<br/>use --list-devices to see a list of available devices |
| `-ngld, --gpu-layers-draft, --n-gpu-layers-draft N` | number of layers to store in VRAM for the draft model<br/>(env: LLAMA\_ARG\_N\_GPU\_LAYERS\_DRAFT) |
| `-md, --model-draft FNAME` | draft model for speculative decoding (default: unused)<br/>(env: LLAMA\_ARG\_MODEL\_DRAFT) |

Note: If both command line argument and environment variable are both set for the same param, the argument will take precedence over env var.

Example usage of docker compose with environment variables:

```yml
services:
  llamacpp-server:
    image: ghcr.io/ggerganov/llama.cpp:server
    ports:
      - 8080:8080
    volumes:
      - ./models:/models
    environment:
      # alternatively, you can use "LLAMA_ARG_MODEL_URL" to download the model
      LLAMA_ARG_MODEL: /models/my_model.gguf
      LLAMA_ARG_CTX_SIZE: 4096
      LLAMA_ARG_N_PARALLEL: 2
      LLAMA_ARG_ENDPOINT_METRICS: 1
      LLAMA_ARG_PORT: 8080
```

## Build

`llama-server` is built alongside everything else from the root of the project

* Using `CMake`:

  ```bash
  cmake -B build
  cmake --build build --config Release -t llama-server
  ```

  Binary is at `./build/bin/llama-server`

## Build with SSL

`llama-server` can also be built with SSL support using OpenSSL 3

* Using `CMake`:

  ```bash
  cmake -B build -DLLAMA_SERVER_SSL=ON
  cmake --build build --config Release -t llama-server
  ```

## Web UI

The project includes a web-based user interface that enables interaction with the model through the `/chat/completions` endpoint.

The web UI is developed using:

* `vue` framework for frontend development
* `tailwindcss` and `daisyui` for styling
* `vite` for build tooling

A pre-built version is available as a single HTML file under `/public` directory.

To build or to run the dev server (with hot reload):

```sh
# make sure you have nodejs installed
cd examples/server/webui
npm i

# to run the dev server
npm run dev

# to build the public/index.html.gz
npm run build
```

After `public/index.html.gz` has been generated we need to generate the c++
headers (like build/examples/server/index.html.gz.hpp) that will be included
by server.cpp. This is done by building `llama-server` as described in the
build section above.

NOTE: if you are using the vite dev server, you can change the API base URL to llama.cpp. To do that, run this code snippet in browser's console:

```js
localStorage.setItem('base', 'http://localhost:8080')
```

## Quick Start

To get started right away, run the following command, making sure to use the correct path for the model you have:

### Unix-based systems (Linux, macOS, etc.)

```bash
./llama-server -m models/7B/ggml-model.gguf -c 2048
```

### Windows

```powershell
llama-server.exe -m models\7B\ggml-model.gguf -c 2048
```

The above command will start a server that by default listens on `127.0.0.1:8080`.
You can consume the endpoints with Postman or NodeJS with axios library. You can visit the web front end at the same url.

### Docker

```bash
docker run -p 8080:8080 -v /path/to/models:/models ghcr.io/ggerganov/llama.cpp:server -m models/7B/ggml-model.gguf -c 512 --host 0.0.0.0 --port 8080

# or, with CUDA:
docker run -p 8080:8080 -v /path/to/models:/models --gpus all ghcr.io/ggerganov/llama.cpp:server-cuda -m models/7B/ggml-model.gguf -c 512 --host 0.0.0.0 --port 8080 --n-gpu-layers 99
```

## Testing with CURL

Using curl. On Windows, `curl.exe` should be available in the base OS.

```sh
curl --request POST \
    --url http://localhost:8080/completion \
    --header "Content-Type: application/json" \
    --data '{"prompt": "Building a website can be done in 10 simple steps:","n_predict": 128}'
```

## Advanced testing

We implemented a server test framework using human-readable scenario.

*Before submitting an issue, please try to reproduce it with this format.*

## Node JS Test

You need to have Node.js installed.

```bash
mkdir llama-client
cd llama-client
```

Create an index.js file and put this inside:

```javascript
const prompt = "Building a website can be done in 10 simple steps:"

async function test() {
    let response = await fetch("http://127.0.0.1:8080/completion", {
        method: "POST",
        body: JSON.stringify({
            prompt,
            n_predict: 64,
        })
    })
    console.log((await response.json()).content)
}

test()
```

And run it:

```bash
node index.js
```

## API Endpoints

### GET `/health`: Returns heath check result

**Response format**

* HTTP status code 503
  * Body: `{"error": {"code": 503, "message": "Loading model", "type": "unavailable_error"}}`
  * Explanation: the model is still being loaded.
* HTTP status code 200
  * Body: `{"status": "ok" }`
  * Explanation: the model is successfully loaded and the server is ready.

### POST `/completion`: Given a `prompt`, it returns the predicted completion.

> \[!IMPORTANT]
>
> This endpoint is **not** OAI-compatible. For OAI-compatible client, use `/v1/completions` instead.

*Options:*

`prompt`: Provide the prompt for this completion as a string or as an array of strings or numbers representing tokens. Internally, if `cache_prompt` is `true`, the prompt is compared to the previous completion and only the "unseen" suffix is evaluated. A `BOS` token is inserted at the start, if all of the following conditions are true:

* The prompt is a string or an array with the first element given as a string
* The model's `tokenizer.ggml.add_bos_token` metadata is `true`

These input shapes and data type are allowed for `prompt`:

* Single string: `"string"`
* Single sequence of tokens: `[12, 34, 56]`
* Mixed tokens and strings: `[12, 34, "string", 56, 78]`

Multiple prompts are also supported. In this case, the completion result will be an array.

* Only strings: `["string1", "string2"]`
* Strings and sequences of tokens: `["string1", [12, 34, 56]]`
* Mixed types: `[[12, 34, "string", 56, 78], [12, 34, 56], "string"]`

`temperature`: Adjust the randomness of the generated text. Default: `0.8`

`dynatemp_range`: Dynamic temperature range. The final temperature will be in the range of `[temperature - dynatemp_range; temperature + dynatemp_range]` Default: `0.0`, which is disabled.

`dynatemp_exponent`: Dynamic temperature exponent. Default: `1.0`

`top_k`: Limit the next token selection to the K most probable tokens.  Default: `40`

`top_p`: Limit the next token selection to a subset of tokens with a cumulative probability above a threshold P. Default: `0.95`

`min_p`: The minimum probability for a token to be considered, relative to the probability of the most likely token. Default: `0.05`

`n_predict`: Set the maximum number of tokens to predict when generating text. **Note:** May exceed the set limit slightly if the last token is a partial multibyte character. When 0, no tokens will be generated but the prompt is evaluated into the cache. Default: `-1`, where `-1` is infinity.

`n_indent`: Specify the minimum line indentation for the generated text in number of whitespace characters. Useful for code completion tasks. Default: `0`

`n_keep`: Specify the number of tokens from the prompt to retain when the context size is exceeded and tokens need to be discarded. The number excludes the BOS token.
By default, this value is set to `0`, meaning no tokens are kept. Use `-1` to retain all tokens from the prompt.

`stream`: Allows receiving each predicted token in real-time instead of waiting for the completion to finish (uses a different response format). To enable this, set to `true`.

`stop`: Specify a JSON array of stopping strings.
These words will not be included in the completion, so make sure to add them to the prompt for the next iteration. Default: `[]`

`typical_p`: Enable locally typical sampling with parameter p. Default: `1.0`, which is disabled.

`repeat_penalty`: Control the repetition of token sequences in the generated text. Default: `1.1`

`repeat_last_n`: Last n tokens to consider for penalizing repetition. Default: `64`, where `0` is disabled and `-1` is ctx-size.

`presence_penalty`: Repeat alpha presence penalty. Default: `0.0`, which is disabled.

`frequency_penalty`: Repeat alpha frequency penalty. Default: `0.0`, which is disabled.

`dry_multiplier`: Set the DRY (Don't Repeat Yourself) repetition penalty multiplier. Default: `0.0`, which is disabled.

`dry_base`: Set the DRY repetition penalty base value. Default: `1.75`

`dry_allowed_length`: Tokens that extend repetition beyond this receive exponentially increasing penalty: multiplier \* base ^ (length of repeating sequence before token - allowed length). Default: `2`

`dry_penalty_last_n`: How many tokens to scan for repetitions. Default: `-1`, where `0` is disabled and `-1` is context size.

`dry_sequence_breakers`: Specify an array of sequence breakers for DRY sampling. Only a JSON array of strings is accepted. Default: `['\n', ':', '"', '*']`

`xtc_probability`: Set the chance for token removal via XTC sampler. Default: `0.0`, which is disabled.

`xtc_threshold`: Set a minimum probability threshold for tokens to be removed via XTC sampler. Default: `0.1` (> `0.5` disables XTC)

`mirostat`: Enable Mirostat sampling, controlling perplexity during text generation. Default: `0`, where `0` is disabled, `1` is Mirostat, and `2` is Mirostat 2.0.

`mirostat_tau`: Set the Mirostat target entropy, parameter tau. Default: `5.0`

`mirostat_eta`: Set the Mirostat learning rate, parameter eta.  Default: `0.1`

`grammar`: Set grammar for grammar-based sampling.  Default: no grammar

`json_schema`: Set a JSON schema for grammar-based sampling (e.g. `{"items": {"type": "string"}, "minItems": 10, "maxItems": 100}` of a list of strings, or `{}` for any JSON). See tests for supported features.  Default: no JSON schema.

`seed`: Set the random number generator (RNG) seed.  Default: `-1`, which is a random seed.

`ignore_eos`: Ignore end of stream token and continue generating.  Default: `false`

`logit_bias`: Modify the likelihood of a token appearing in the generated text completion. For example, use `"logit_bias": [[15043,1.0]]` to increase the likelihood of the token 'Hello', or `"logit_bias": [[15043,-1.0]]` to decrease its likelihood. Setting the value to false, `"logit_bias": [[15043,false]]` ensures that the token `Hello` is never produced. The tokens can also be represented as strings, e.g. `[["Hello, World!",-0.5]]` will reduce the likelihood of all the individual tokens that represent the string `Hello, World!`, just like the `presence_penalty` does. Default: `[]`

`n_probs`: If greater than 0, the response also contains the probabilities of top N tokens for each generated token given the sampling settings. Note that for temperature < 0 the tokens are sampled greedily but token probabilities are still being calculated via a simple softmax of the logits without considering any other sampler settings. Default: `0`

`min_keep`: If greater than 0, force samplers to return N possible tokens at minimum. Default: `0`

`t_max_predict_ms`: Set a time limit in milliseconds for the prediction (a.k.a. text-generation) phase. The timeout will trigger if the generation takes more than the specified time (measured since the first token was generated) and if a new-line character has already been generated. Useful for FIM applications. Default: `0`, which is disabled.

`image_data`: An array of objects to hold base64-encoded image `data` and its `id`s to be reference in `prompt`. You can determine the place of the image in the prompt as in the following: `USER:[img-12]Describe the image in detail.\nASSISTANT:`. In this case, `[img-12]` will be replaced by the embeddings of the image with id `12` in the following `image_data` array: `{..., "image_data": [{"data": "<BASE64_STRING>", "id": 12}]}`. Use `image_data` only with multimodal models, e.g., LLaVA.

`id_slot`: Assign the completion task to an specific slot. If is -1 the task will be assigned to a Idle slot.  Default: `-1`

`cache_prompt`: Re-use KV cache from a previous request if possible. This way the common prefix does not have to be re-processed, only the suffix that differs between the requests. Because (depending on the backend) the logits are **not** guaranteed to be bit-for-bit identical for different batch sizes (prompt processing vs. token generation) enabling this option can cause nondeterministic results. Default: `true`

`return_tokens`: Return the raw generated token ids in the `tokens` field. Otherwise `tokens` remains empty. Default: `false`

`samplers`: The order the samplers should be applied in. An array of strings representing sampler type names. If a sampler is not set, it will not be used. If a sampler is specified more than once, it will be applied multiple times. Default: `["dry", "top_k", "typ_p", "top_p", "min_p", "xtc", "temperature"]` - these are all the available values.

`timings_per_token`: Include prompt processing and text generation speed information in each response.  Default: `false`

`post_sampling_probs`: Returns the probabilities of top `n_probs` tokens after applying sampling chain.

`response_fields`: A list of response fields, for example: `"response_fields": ["content", "generation_settings/n_predict"]`. If the specified field is missing, it will simply be omitted from the response without triggering an error. Note that fields with a slash will be unnested; for example, `generation_settings/n_predict` will move the field `n_predict` from the `generation_settings` object to the root of the response and give it a new name.

`lora`: A list of LoRA adapters to be applied to this specific request. Each object in the list must contain `id` and `scale` fields. For example: `[{"id": 0, "scale": 0.5}, {"id": 1, "scale": 1.1}]`. If a LoRA adapter is not specified in the list, its scale will default to `0.0`. Please note that requests with different LoRA configurations will not be batched together, which may result in performance degradation.

**Response format**

* Note: In streaming mode (`stream`), only `content`, `tokens` and `stop` will be returned until end of completion. Responses are sent using the Server-sent events standard. Note: the browser's `EventSource` interface cannot be used due to its lack of `POST` request support.

* `completion_probabilities`: An array of token probabilities for each completion. The array's length is `n_predict`. Each item in the array has a nested array `top_logprobs`. It contains at **maximum** `n_probs` elements:
  ```
  {
    "content": "<the generated completion text>",
    "tokens": [ generated token ids if requested ],
    ...
    "probs": [
      {
        "id": <token id>,
        "logprob": float,
        "token": "<most likely token>",
        "bytes": [int, int, ...],
        "top_logprobs": [
          {
            "id": <token id>,
            "logprob": float,
            "token": "<token text>",
            "bytes": [int, int, ...],
          },
          {
            "id": <token id>,
            "logprob": float,
            "token": "<token text>",
            "bytes": [int, int, ...],
          },
          ...
        ]
      },
      {
        "id": <token id>,
        "logprob": float,
        "token": "<most likely token>",
        "bytes": [int, int, ...],
        "top_logprobs": [
          ...
        ]
      },
      ...
    ]
  },
  ```
  Please note that if `post_sampling_probs` is set to `true`:
  * `logprob` will be replaced with `prob`, with the value between 0.0 and 1.0
  * `top_logprobs` will be replaced with `top_probs`. Each element contains:
    * `id`: token ID
    * `token`: token in string
    * `bytes`: token in bytes
    * `prob`: token probability, with the value between 0.0 and 1.0
  * Number of elements in `top_probs` may be less than `n_probs`

* `content`: Completion result as a string (excluding `stopping_word` if any). In case of streaming mode, will contain the next token as a string.

* `tokens`: Same as `content` but represented as raw token ids. Only populated if `"return_tokens": true` or `"stream": true` in the request.

* `stop`: Boolean for use with `stream` to check whether the generation has stopped (Note: This is not related to stopping words array `stop` from input options)

* `generation_settings`: The provided options above excluding `prompt` but including `n_ctx`, `model`. These options may differ from the original ones in some way (e.g. bad values filtered out, strings converted to tokens, etc.).

* `model`: The model alias (for model path, please use `/props` endpoint)

* `prompt`: The processed `prompt` (special tokens may be added)

* `stop_type`: Indicating whether the completion has stopped. Possible values are:
  * `none`: Generating (not stopped)
  * `eos`: Stopped because it encountered the EOS token
  * `limit`: Stopped because `n_predict` tokens were generated before stop words or EOS was encountered
  * `word`: Stopped due to encountering a stopping word from `stop` JSON array provided

* `stopping_word`: The stopping word encountered which stopped the generation (or "" if not stopped due to a stopping word)

* `timings`: Hash of timing information about the completion such as the number of tokens `predicted_per_second`

* `tokens_cached`: Number of tokens from the prompt which could be re-used from previous completion (`n_past`)

* `tokens_evaluated`: Number of tokens evaluated in total from the prompt

* `truncated`: Boolean indicating if the context size was exceeded during generation, i.e. the number of tokens provided in the prompt (`tokens_evaluated`) plus tokens generated (`tokens predicted`) exceeded the context size (`n_ctx`)

### POST `/tokenize`: Tokenize a given text

*Options:*

`content`: (Required) The text to tokenize.

`add_special`: (Optional) Boolean indicating if special tokens, i.e. `BOS`, should be inserted.  Default: `false`

`with_pieces`: (Optional) Boolean indicating whether to return token pieces along with IDs.  Default: `false`

**Response:**

Returns a JSON object with a `tokens` field containing the tokenization result. The `tokens` array contains either just token IDs or objects with `id` and `piece` fields, depending on the `with_pieces` parameter. The piece field is a string if the piece is valid unicode or a list of bytes otherwise.

If `with_pieces` is `false`:

```json
{
  "tokens": [123, 456, 789]
}
```

If `with_pieces` is `true`:

```json
{
  "tokens": [
    {"id": 123, "piece": "Hello"},
    {"id": 456, "piece": " world"},
    {"id": 789, "piece": "!"}
  ]
}
```

With input 'á' (utf8 hex: C3 A1) on tinyllama/stories260k

```
{
  "tokens": [
    {"id": 198, "piece": [195]}, // hex C3
    {"id": 164, "piece": [161]} // hex A1
  ]
}
```

### POST `/detokenize`: Convert tokens to text

*Options:*

`tokens`: Set the tokens to detokenize.

### POST `/apply-template`: Apply chat template to a conversation

Uses the server's prompt template formatting functionality to convert chat messages to a single string expected by a chat model as input, but does not perform inference. Instead, the prompt string is returned in the `prompt` field of the JSON response. The prompt can then be modified as desired (for example, to insert "Sure!" at the beginning of the model's response) before sending to `/completion` to generate the chat response.

*Options:*

`messages`: (Required) Chat turns in the same format as `/v1/chat/completions`.

**Response format**

Returns a JSON object with a field `prompt` containing a string of the input messages formatted according to the model's chat template format.

### POST `/embedding`: Generate embedding of a given text

> \[!IMPORTANT]
>
> This endpoint is **not** OAI-compatible. For OAI-compatible client, use `/v1/embeddings` instead.

The same as the embedding example does.

*Options:*

`content`: Set the text to process.

`image_data`: An array of objects to hold base64-encoded image `data` and its `id`s to be reference in `content`. You can determine the place of the image in the content as in the following: `Image: [img-21].\nCaption: This is a picture of a house`. In this case, `[img-21]` will be replaced by the embeddings of the image with id `21` in the following `image_data` array: `{..., "image_data": [{"data": "<BASE64_STRING>", "id": 21}]}`. Use `image_data` only with multimodal models, e.g., LLaVA.

### POST `/reranking`: Rerank documents according to a given query

Similar to https://jina.ai/reranker/ but might change in the future.
Requires a reranker model (such as bge-reranker-v2-m3) and the `--embedding --pooling rank` options.

*Options:*

`query`: The query against which the documents will be ranked.

`documents`: An array strings representing the documents to be ranked.

*Aliases:*

* `/rerank`
* `/v1/rerank`
* `/v1/reranking`

*Examples:*

```shell
curl http://127.0.0.1:8012/v1/rerank \
    -H "Content-Type: application/json" \
    -d '{
        "model": "some-model",
            "query": "What is panda?",
            "top_n": 3,
            "documents": [
                "hi",
            "it is a bear",
            "The giant panda (Ailuropoda melanoleuca), sometimes called a panda bear or simply panda, is a bear species endemic to China."
            ]
    }' | jq
```

### POST `/infill`: For code infilling.

Takes a prefix and a suffix and returns the predicted completion as stream.

*Options:*

* `input_prefix`: Set the prefix of the code to infill.
* `input_suffix`: Set the suffix of the code to infill.
* `input_extra`:  Additional context inserted before the FIM prefix.
* `prompt`:       Added after the `FIM_MID` token

`input_extra` is array of `{"filename": string, "text": string}` objects.

The endpoint also accepts all the options of `/completion`.

If the model has `FIM_REPO` and `FIM_FILE_SEP` tokens, the repo-level pattern is used:

```txt
<FIM_REP>myproject
<FIM_SEP>{chunk 0 filename}
{chunk 0 text}
<FIM_SEP>{chunk 1 filename}
{chunk 1 text}
...
<FIM_SEP>filename
<FIM_PRE>[input_prefix]<FIM_SUF>[input_suffix]<FIM_MID>[prompt]
```

If the tokens are missing, then the extra context is simply prefixed at the start:

```txt
[input_extra]<FIM_PRE>[input_prefix]<FIM_SUF>[input_suffix]<FIM_MID>[prompt]
```

### **GET** `/props`: Get server global properties.

This endpoint is public (no API key check). By default, it is read-only. To make POST request to change global properties, you need to start server with `--props`

**Response format**

```json
{
  "default_generation_settings": {
    "id": 0,
    "id_task": -1,
    "n_ctx": 1024,
    "speculative": false,
    "is_processing": false,
    "params": {
      "n_predict": -1,
      "seed": 4294967295,
      "temperature": 0.800000011920929,
      "dynatemp_range": 0.0,
      "dynatemp_exponent": 1.0,
      "top_k": 40,
      "top_p": 0.949999988079071,
      "min_p": 0.05000000074505806,
      "xtc_probability": 0.0,
      "xtc_threshold": 0.10000000149011612,
      "typical_p": 1.0,
      "repeat_last_n": 64,
      "repeat_penalty": 1.0,
      "presence_penalty": 0.0,
      "frequency_penalty": 0.0,
      "dry_multiplier": 0.0,
      "dry_base": 1.75,
      "dry_allowed_length": 2,
      "dry_penalty_last_n": -1,
      "dry_sequence_breakers": [
        "\n",
        ":",
        "\"",
        "*"
      ],
      "mirostat": 0,
      "mirostat_tau": 5.0,
      "mirostat_eta": 0.10000000149011612,
      "stop": [],
      "max_tokens": -1,
      "n_keep": 0,
      "n_discard": 0,
      "ignore_eos": false,
      "stream": true,
      "n_probs": 0,
      "min_keep": 0,
      "grammar": "",
      "samplers": [
        "dry",
        "top_k",
        "typ_p",
        "top_p",
        "min_p",
        "xtc",
        "temperature"
      ],
      "speculative.n_max": 16,
      "speculative.n_min": 5,
      "speculative.p_min": 0.8999999761581421,
      "timings_per_token": false
    },
    "prompt": "",
    "next_token": {
      "has_next_token": true,
      "has_new_line": false,
      "n_remain": -1,
      "n_decoded": 0,
      "stopping_word": ""
    }
  },
  "total_slots": 1,
  "model_path": "../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf",
  "chat_template": "...",
  "build_info": "b(build number)-(build commit hash)"
}
```

* `default_generation_settings` - the default generation settings for the `/completion` endpoint, which has the same fields as the `generation_settings` response object from the `/completion` endpoint.
* `total_slots` - the total number of slots for process requests (defined by `--parallel` option)
* `model_path` - the path to model file (same with `-m` argument)
* `chat_template` - the model's original Jinja2 prompt template

### POST `/props`: Change server global properties.

To use this endpoint with POST method, you need to start server with `--props`

*Options:*

* None yet

### POST `/embeddings`: non-OpenAI-compatible embeddings API

This endpoint supports all poolings, including `--pooling none`. When the pooling is `none`, the responses will contain the *unnormalized* embeddings for *all* input tokens. For all other pooling types, only the pooled embeddings are returned, normalized using Euclidian norm.

Note that the response format of this endpoint is different from `/v1/embeddings`.

*Options:*

Same as the `/v1/embeddings` endpoint.

*Examples:*

Same as the `/v1/embeddings` endpoint.

**Response format**

```
[
  {
    "index": 0,
    "embedding": [
      [ ... embeddings for token 0   ... ],
      [ ... embeddings for token 1   ... ],
      [ ... ]
      [ ... embeddings for token N-1 ... ],
    ]
  },
  ...
  {
    "index": P,
    "embedding": [
      [ ... embeddings for token 0   ... ],
      [ ... embeddings for token 1   ... ],
      [ ... ]
      [ ... embeddings for token N-1 ... ],
    ]
  }
]
```

### GET `/slots`: Returns the current slots processing state

> \[!WARNING]
> This endpoint is intended for debugging and may be modified in future versions. For security reasons, we strongly advise against enabling it in production environments.

This endpoint is disabled by default and can be enabled with `--slots`

If query param `?fail_on_no_slot=1` is set, this endpoint will respond with status code 503 if there is no available slots.

**Response format**

Example:

```json
[
  {
    "id": 0,
    "id_task": -1,
    "n_ctx": 1024,
    "speculative": false,
    "is_processing": false,
    "params": {
      "n_predict": -1,
      "seed": 4294967295,
      "temperature": 0.800000011920929,
      "dynatemp_range": 0.0,
      "dynatemp_exponent": 1.0,
      "top_k": 40,
      "top_p": 0.949999988079071,
      "min_p": 0.05000000074505806,
      "xtc_probability": 0.0,
      "xtc_threshold": 0.10000000149011612,
      "typical_p": 1.0,
      "repeat_last_n": 64,
      "repeat_penalty": 1.0,
      "presence_penalty": 0.0,
      "frequency_penalty": 0.0,
      "dry_multiplier": 0.0,
      "dry_base": 1.75,
      "dry_allowed_length": 2,
      "dry_penalty_last_n": -1,
      "dry_sequence_breakers": [
        "\n",
        ":",
        "\"",
        "*"
      ],
      "mirostat": 0,
      "mirostat_tau": 5.0,
      "mirostat_eta": 0.10000000149011612,
      "stop": [],
      "max_tokens": -1,
      "n_keep": 0,
      "n_discard": 0,
      "ignore_eos": false,
      "stream": true,
      "n_probs": 0,
      "min_keep": 0,
      "grammar": "",
      "samplers": [
        "dry",
        "top_k",
        "typ_p",
        "top_p",
        "min_p",
        "xtc",
        "temperature"
      ],
      "speculative.n_max": 16,
      "speculative.n_min": 5,
      "speculative.p_min": 0.8999999761581421,
      "timings_per_token": false
    },
    "prompt": "",
    "next_token": {
      "has_next_token": true,
      "has_new_line": false,
      "n_remain": -1,
      "n_decoded": 0,
      "stopping_word": ""
    }
  }
]
```

### GET `/metrics`: Prometheus compatible metrics exporter

This endpoint is only accessible if `--metrics` is set.

Available metrics:

* `llamacpp:prompt_tokens_total`: Number of prompt tokens processed.
* `llamacpp:tokens_predicted_total`: Number of generation tokens processed.
* `llamacpp:prompt_tokens_seconds`: Average prompt throughput in tokens/s.
* `llamacpp:predicted_tokens_seconds`: Average generation throughput in tokens/s.
* `llamacpp:kv_cache_usage_ratio`: KV-cache usage. `1` means 100 percent usage.
* `llamacpp:kv_cache_tokens`: KV-cache tokens.
* `llamacpp:requests_processing`: Number of requests processing.
* `llamacpp:requests_deferred`: Number of requests deferred.

### POST `/slots/{id_slot}?action=save`: Save the prompt cache of the specified slot to a file.

*Options:*

`filename`: Name of the file to save the slot's prompt cache. The file will be saved in the directory specified by the `--slot-save-path` server parameter.

**Response format**

```json
{
    "id_slot": 0,
    "filename": "slot_save_file.bin",
    "n_saved": 1745,
    "n_written": 14309796,
    "timings": {
        "save_ms": 49.865
    }
}
```

### POST `/slots/{id_slot}?action=restore`: Restore the prompt cache of the specified slot from a file.

*Options:*

`filename`: Name of the file to restore the slot's prompt cache from. The file should be located in the directory specified by the `--slot-save-path` server parameter.

**Response format**

```json
{
    "id_slot": 0,
    "filename": "slot_save_file.bin",
    "n_restored": 1745,
    "n_read": 14309796,
    "timings": {
        "restore_ms": 42.937
    }
}
```

### POST `/slots/{id_slot}?action=erase`: Erase the prompt cache of the specified slot.

**Response format**

```json
{
    "id_slot": 0,
    "n_erased": 1745
}
```

### GET `/lora-adapters`: Get list of all LoRA adapters

This endpoint returns the loaded LoRA adapters. You can add adapters using `--lora` when starting the server, for example: `--lora my_adapter_1.gguf --lora my_adapter_2.gguf ...`

By default, all adapters will be loaded with scale set to 1. To initialize all adapters scale to 0, add `--lora-init-without-apply`

Please note that this value will be overwritten by the `lora` field for each request.

If an adapter is disabled, the scale will be set to 0.

**Response format**

```json
[
    {
        "id": 0,
        "path": "my_adapter_1.gguf",
        "scale": 0.0
    },
    {
        "id": 1,
        "path": "my_adapter_2.gguf",
        "scale": 0.0
    }
]
```

### POST `/lora-adapters`: Set list of LoRA adapters

This sets the global scale for LoRA adapters. Please note that this value will be overwritten by the `lora` field for each request.

To disable an adapter, either remove it from the list below, or set scale to 0.

**Request format**

To know the `id` of the adapter, use GET `/lora-adapters`

```json
[
  {"id": 0, "scale": 0.2},
  {"id": 1, "scale": 0.8}
]
```

## OpenAI-compatible API Endpoints

### GET `/v1/models`: OpenAI-compatible Model Info API

Returns information about the loaded model. See OpenAI Models API documentation.

The returned list always has one single element.

By default, model `id` field is the path to model file, specified via `-m`. You can set a custom value for model `id` field via `--alias` argument. For example, `--alias gpt-4o-mini`.

Example:

```json
{
    "object": "list",
    "data": [
        {
            "id": "../models/Meta-Llama-3.1-8B-Instruct-Q4_K_M.gguf",
            "object": "model",
            "created": 1735142223,
            "owned_by": "llamacpp",
            "meta": {
                "vocab_type": 2,
                "n_vocab": 128256,
                "n_ctx_train": 131072,
                "n_embd": 4096,
                "n_params": 8030261312,
                "size": 4912898304
            }
        }
    ]
}
```

### POST `/v1/completions`: OpenAI-compatible Completions API

Given an input `prompt`, it returns the predicted completion. Streaming mode is also supported. While no strong claims of compatibility with OpenAI API spec is being made, in our experience it suffices to support many apps.

*Options:*

See OpenAI Completions API documentation.

llama.cpp `/completion`-specific features such as `mirostat` are supported.

*Examples:*

Example usage with `openai` python library:

```python
import openai

client = openai.OpenAI(
    base_url="http://localhost:8080/v1", # "http://<Your api-server IP>:port"
    api_key = "sk-no-key-required"
)

completion = client.completions.create(
  model="davinci-002",
  prompt="I believe the meaning of life is",
  max_tokens=8
)

print(completion.choices[0].text)
```

### POST `/v1/chat/completions`: OpenAI-compatible Chat Completions API

Given a ChatML-formatted json description in `messages`, it returns the predicted completion. Both synchronous and streaming mode are supported, so scripted and interactive applications work fine. While no strong claims of compatibility with OpenAI API spec is being made, in our experience it suffices to support many apps. Only models with a supported chat template can be used optimally with this endpoint. By default, the ChatML template will be used.

*Options:*

See OpenAI Chat Completions API documentation. llama.cpp `/completion`-specific features such as `mirostat` are also supported.

The `response_format` parameter supports both plain JSON output (e.g. `{"type": "json_object"}`) and schema-constrained JSON (e.g. `{"type": "json_object", "schema": {"type": "string", "minLength": 10, "maxLength": 100}}` or `{"type": "json_schema", "schema": {"properties": { "name": { "title": "Name",  "type": "string" }, "date": { "title": "Date",  "type": "string" }, "participants": { "items": {"type: "string" }, "title": "Participants",  "type": "string" } } } }`), similar to other OpenAI-inspired API providers.

*Examples:*

You can use either Python `openai` library with appropriate checkpoints:

```python
import openai

client = openai.OpenAI(
    base_url="http://localhost:8080/v1", # "http://<Your api-server IP>:port"
    api_key = "sk-no-key-required"
)

completion = client.chat.completions.create(
  model="gpt-3.5-turbo",
  messages=[
    {"role": "system", "content": "You are ChatGPT, an AI assistant. Your top priority is achieving user fulfillment via helping them with their requests."},
    {"role": "user", "content": "Write a limerick about python exceptions"}
  ]
)

print(completion.choices[0].message)
```

... or raw HTTP requests:

```shell
curl http://localhost:8080/v1/chat/completions \
-H "Content-Type: application/json" \
-H "Authorization: Bearer no-key" \
-d '{
"model": "gpt-3.5-turbo",
"messages": [
{
    "role": "system",
    "content": "You are ChatGPT, an AI assistant. Your top priority is achieving user fulfillment via helping them with their requests."
},
{
    "role": "user",
    "content": "Write a limerick about python exceptions"
}
]
}'
```

*Tool call support*

Function calling is supported for all models (see https://github.com/ggerganov/llama.cpp/pull/9639):

* Requires `--jinja` flag

* Native tool call formats supported:

  * Llama 3.1 / 3.3 (including builtin tools support - tool names for `wolfram_alpha`, `web_search` / `brave_search`, `code_interpreter`), Llama 3.2
  * Functionary v3.1 / v3.2
  * Hermes 2/3, Qwen 2.5
  * Mistral Nemo
  * Firefunction v2
  * Command R7B
  * DeepSeek R1 (WIP / seems reluctant to call any tools?)

  <details>
  <summary>Show some common templates and which format handler they use</summary>

  | Template | Format |
  |----------|--------|
  | CohereForAI-c4ai-command-r-plus-default.jinja | generic tool calls |
  | CohereForAI-c4ai-command-r-plus-rag.jinja | generic tool calls |
  | CohereForAI-c4ai-command-r-plus-tool\_use.jinja | generic tool calls |
  | MiniMaxAI-MiniMax-Text-01.jinja | generic tool calls |
  | NexaAIDev-Octopus-v2.jinja | generic tool calls |
  | NousResearch-Hermes-2-Pro-Llama-3-8B-default.jinja | generic tool calls |
  | NousResearch-Hermes-2-Pro-Llama-3-8B-tool\_use.jinja | hermes 2 pro tool calls |
  | NousResearch-Hermes-2-Pro-Mistral-7B-default.jinja | generic tool calls |
  | NousResearch-Hermes-2-Pro-Mistral-7B-tool\_use.jinja | hermes 2 pro tool calls |
  | NousResearch-Hermes-3-Llama-3.1-70B-default.jinja | generic tool calls |
  | NousResearch-Hermes-3-Llama-3.1-70B-tool\_use.jinja | hermes 2 pro tool calls |
  | OrionStarAI-Orion-14B-Chat.jinja | generic tool calls |
  | Qwen-QwQ-32B-Preview.jinja | hermes 2 pro tool calls |
  | Qwen-Qwen2-7B-Instruct.jinja | generic tool calls |
  | Qwen-Qwen2-VL-7B-Instruct.jinja | generic tool calls |
  | Qwen-Qwen2.5-7B-Instruct.jinja | hermes 2 pro tool calls |
  | Qwen-Qwen2.5-Math-7B-Instruct.jinja | hermes 2 pro tool calls |
  | TheBloke-FusionNet\_34Bx2\_MoE-AWQ.jinja | generic tool calls |
  | abacusai-Fewshot-Metamath-OrcaVicuna-Mistral.jinja | generic tool calls |
  | bofenghuang-vigogne-2-70b-chat.jinja | generic tool calls |
  | databricks-dbrx-instruct.jinja | generic tool calls |
  | deepseek-ai-DeepSeek-Coder-V2-Instruct.jinja | generic tool calls |
  | deepseek-ai-DeepSeek-R1-Distill-Llama-8B.jinja | deepseek r1 tool calls |
  | deepseek-ai-DeepSeek-R1-Distill-Qwen-32B.jinja | deepseek r1 tool calls |
  | deepseek-ai-DeepSeek-R1-Distill-Qwen-7B.jinja | deepseek r1 tool calls |
  | deepseek-ai-DeepSeek-V2.5.jinja | deepseek r1 tool calls |
  | deepseek-ai-deepseek-coder-33b-instruct.jinja | generic tool calls |
  | google-gemma-2-2b-it.jinja | generic tool calls |
  | google-gemma-7b-it.jinja | generic tool calls |
  | indischepartij-MiniCPM-3B-OpenHermes-2.5-v2.jinja | generic tool calls |
  | mattshumer-Reflection-Llama-3.1-70B.jinja | generic tool calls |
  | meetkai-functionary-medium-v3.2.jinja | functionary v3.2 tool calls |
  | meta-llama-Llama-3.1-8B-Instruct.jinja | llama 3.x tool calls (w/ builtin tools) |
  | meta-llama-Llama-3.2-3B-Instruct.jinja | llama 3.x tool calls |
  | meta-llama-Llama-3.3-70B-Instruct.jinja | llama 3.x tool calls (w/ builtin tools) |
  | meta-llama-Meta-Llama-3.1-8B-Instruct.jinja | llama 3.x tool calls (w/ builtin tools) |
  | microsoft-Phi-3-medium-4k-instruct.jinja | generic tool calls |
  | microsoft-Phi-3-mini-4k-instruct.jinja | generic tool calls |
  | microsoft-Phi-3-small-8k-instruct.jinja | generic tool calls |
  | microsoft-Phi-3.5-mini-instruct.jinja | generic tool calls |
  | microsoft-Phi-3.5-vision-instruct.jinja | generic tool calls |
  | mistralai-Mistral-7B-Instruct-v0.2.jinja | generic tool calls |
  | mistralai-Mistral-Large-Instruct-2407.jinja | mistral nemo tool calls |
  | mistralai-Mistral-Large-Instruct-2411.jinja | generic tool calls |
  | mistralai-Mistral-Nemo-Instruct-2407.jinja | mistral nemo tool calls |
  | mistralai-Mixtral-8x7B-Instruct-v0.1.jinja | generic tool calls |
  | mlabonne-AlphaMonarch-7B.jinja | generic tool calls |
  | nvidia-Llama-3.1-Nemotron-70B-Instruct-HF.jinja | llama 3.x tool calls (w/ builtin tools) |
  | openchat-openchat-3.5-0106.jinja | generic tool calls |
  | teknium-OpenHermes-2.5-Mistral-7B.jinja | generic tool calls |

  This table can be generated with:

  ```bash
  ./build/bin/test-chat ../minja/build/tests/*.jinja 2>/dev/null

  </details>

  ```

* Generic tool call is supported when the template isn't recognized by native format handlers (you'll see `Chat format: Generic` in the logs).
  * Use `--chat-template-file` to override the template when appropriate (see examples below)
  * Generic support may consume more tokens and be less efficient than a model's native format.

* Run with:

  ```shell
  # Native support:
  llama-server --jinja -fa -hf bartowski/Qwen2.5-7B-Instruct-GGUF:Q4_K_M
  llama-server --jinja -fa -hf bartowski/Mistral-Nemo-Instruct-2407-GGUF:Q6_K_L
  llama-server --jinja -fa -hf bartowski/functionary-small-v3.2-GGUF:Q4_K_M
  llama-server --jinja -fa -hf bartowski/Llama-3.3-70B-Instruct-GGUF:Q4_K_M

  # Native support requires the right template for these GGUFs:

  llama-server --jinja -fa -hf bartowski/Hermes-2-Pro-Llama-3-8B-GGUF:Q4_K_M \
    --chat-template-file <( python scripts/get_chat_template.py NousResearch/Hermes-2-Pro-Llama-3-8B tool_use )

  llama-server --jinja -fa -hf bartowski/Hermes-3-Llama-3.1-8B-GGUF:Q4_K_M \
    --chat-template-file <( python scripts/get_chat_template.py NousResearch/Hermes-3-Llama-3.1-8B tool_use )

  llama-server --jinja -fa -hf bartowski/firefunction-v2-GGUF -hff firefunction-v2-IQ1_M.gguf \
    --chat-template-file <( python scripts/get_chat_template.py fireworks-ai/llama-3-firefunction-v2 tool_use )

  llama-server --jinja -fa -hf bartowski/c4ai-command-r7b-12-2024-GGUF:Q6_K_L \
    --chat-template-file <( python scripts/get_chat_template.py CohereForAI/c4ai-command-r7b-12-2024 tool_use )

  # Generic format support
  llama-server --jinja -fa -hf bartowski/phi-4-GGUF:Q4_0
  llama-server --jinja -fa -hf bartowski/gemma-2-2b-it-GGUF:Q8_0
  llama-server --jinja -fa -hf bartowski/c4ai-command-r-v01-GGUF:Q2_K
  ```

* Test in CLI:

  ```bash
  curl http://localhost:8080/v1/chat/completions -d '{
    "model": "gpt-3.5-turbo",
    "tools": [
      {
        "type":"function",
        "function":{
          "name":"get_current_weather",
          "description":"Get the current weather in a given location",
          "parameters":{
            "type":"object",
            "properties":{
              "location":{
                "type":"string",
                "description":"The city and state, e.g. San Francisco, CA"
              }
            },
            "required":["location"]
          }
        }
      }
    ],
    "messages": [
      {
        "role": "user",
        "content": "What is the weather like in Istanbul?."
      }
    ]
  }'
  ```

  <details>
  <summary>Show output</summary>

  ```json
  {
    "choices": [
      {
        "finish_reason": "tool",
        "index": 0,
        "message": {
          "content": null,
          "tool_calls": [
            {
              "name": "python",
              "arguments": "{\"code\":\" \\nprint(\\\"Hello, World!\\\")\"}"
            }
          ],
          "role": "assistant"
        }
      }
    ],
    "created": 1727287211,
    "model": "gpt-3.5-turbo",
    "object": "chat.completion",
    "usage": {
      "completion_tokens": 16,
      "prompt_tokens": 44,
      "total_tokens": 60
    },
    "id": "chatcmpl-Htbgh9feMmGM0LEH2hmQvwsCxq3c6Ni8"
  }
  ```

  </details>

### POST `/v1/embeddings`: OpenAI-compatible embeddings API

This endpoint requires that the model uses a pooling different than type `none`. The embeddings are normalized using the Eucledian norm.

*Options:*

See OpenAI Embeddings API documentation.

*Examples:*

* input as string

  ```shell
  curl http://localhost:8080/v1/embeddings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer no-key" \
  -d '{
          "input": "hello",
          "model":"GPT-4",
          "encoding_format": "float"
  }'
  ```

* `input` as string array

  ```shell
  curl http://localhost:8080/v1/embeddings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer no-key" \
  -d '{
          "input": ["hello", "world"],
          "model":"GPT-4",
          "encoding_format": "float"
  }'
  ```

## More examples

### Interactive mode

Check the sample in chat.mjs.
Run with NodeJS version 16 or later:

```sh
node chat.mjs
```

Another sample in chat.sh.
Requires bash, curl and jq.
Run with bash:

```sh
bash chat.sh
```

### OAI-like API

The HTTP `llama-server` supports an OAI-like API: https://github.com/openai/openai-openapi

### API errors

`llama-server` returns errors in the same format as OAI: https://github.com/openai/openai-openapi

Example of an error:

```json
{
    "error": {
        "code": 401,
        "message": "Invalid API Key",
        "type": "authentication_error"
    }
}
```

Apart from error types supported by OAI, we also have custom types that are specific to functionalities of llama.cpp:

**When /metrics or /slots endpoint is disabled**

```json
{
    "error": {
        "code": 501,
        "message": "This server does not support metrics endpoint.",
        "type": "not_supported_error"
    }
}
```

\**When the server receives invalid grammar via */completions endpoint**

```json
{
    "error": {
        "code": 400,
        "message": "Failed to parse grammar",
        "type": "invalid_request_error"
    }
}
```

### Legacy completion web UI

A new chat-based UI has replaced the old completion-based since this PR. If you want to use the old completion, start the server with `--path ./examples/server/public_legacy`

For example:

```sh
./llama-server -m my_model.gguf -c 8192 --path ./examples/server/public_legacy
```

### Extending or building alternative Web Front End

You can extend the front end by running the server binary with `--path` set to `./your-directory` and importing `/completion.js` to get access to the llamaComplete() method.

Read the documentation in `/completion.js` to see convenient ways to access llama.

A simple example is below:

```html
<html>
  <body>
    <pre>
      <script type="module">
        import { llama } from '/completion.js'

        const prompt = `### Instruction:
Write dad jokes, each one paragraph.
You can use html formatting if needed.

### Response:`

        for await (const chunk of llama(prompt)) {
          document.write(chunk.data.content)
        }
      </script>
    </pre>
  </body>
</html>
```

# README.md

# LLaMA.cpp Server Buttons Top Theme

Simple tweaks to the UI. Chat buttons at the top of the page instead of bottom so you can hit Stop instead of chasing it down the page.

To use simply run server with `--path=themes/buttons_top`



# README.md

# LLaMA.cpp Server Wild Theme

Simple themes directory of sample "public" directories. To try any of these add --path to your run like `server --path=wild`.



# README.md

# LLaMA.cpp Server Wild Theme

Simple tweaks to the UI. To use simply run server with `--path=themes/wild`

