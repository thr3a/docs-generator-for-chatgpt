## Named Arguments

\--model

Name or path of the huggingface model to use.

Default: “facebook/opt-125m”

\--task

Possible choices: auto, generate, embedding

The task to use the model for. Each vLLM instance only supports one task, even if the same model can be used for multiple tasks. When the model only supports one task, “auto” can be used to select it; otherwise, you must specify explicitly which task to use.

Default: “auto”

\--tokenizer

Name or path of the huggingface tokenizer to use. If unspecified, model name or path will be used.

\--skip-tokenizer-init

Skip initialization of tokenizer and detokenizer

\--revision

The specific model version to use. It can be a branch name, a tag name, or a commit id. If unspecified, will use the default version.

\--code-revision

The specific revision to use for the model code on Hugging Face Hub. It can be a branch name, a tag name, or a commit id. If unspecified, will use the default version.

\--tokenizer-revision

Revision of the huggingface tokenizer to use. It can be a branch name, a tag name, or a commit id. If unspecified, will use the default version.

\--tokenizer-mode

Possible choices: auto, slow, mistral

The tokenizer mode.

-   “auto” will use the fast tokenizer if available.
    
-   “slow” will always use the slow tokenizer.
    
-   “mistral” will always use the mistral\_common tokenizer.
    

Default: “auto”

\--chat-template-text-format

Possible choices: string, openai

The format to render text content within a chat template. “string” will keep the content field as a string whereas “openai” will parse content in the current OpenAI format.

Default: “string”

\--trust-remote-code

Trust remote code from huggingface.

\--allowed-local-media-path

Allowing API requests to read local images or videos from directories specified by the server file system. This is a security risk. Should only be enabled in trusted environments.

\--download-dir

Directory to download and load the weights, default to the default cache dir of huggingface.

\--load-format

Possible choices: auto, pt, safetensors, npcache, dummy, tensorizer, sharded\_state, gguf, bitsandbytes, mistral

The format of the model weights to load.

-   “auto” will try to load the weights in the safetensors format and fall back to the pytorch bin format if safetensors format is not available.
    
-   “pt” will load the weights in the pytorch bin format.
    
-   “safetensors” will load the weights in the safetensors format.
    
-   “npcache” will load the weights in pytorch format and store a numpy cache to speed up the loading.
    
-   “dummy” will initialize the weights with random values, which is mainly for profiling.
    
-   “tensorizer” will load the weights using tensorizer from CoreWeave. See the Tensorize vLLM Model script in the Examples section for more information.
    
-   “bitsandbytes” will load the weights using bitsandbytes quantization.
    

Default: “auto”

\--config-format

Possible choices: auto, hf, mistral

The format of the model config to load.

-   “auto” will try to load the config in hf format if available else it will try to load in mistral format
    

Default: “ConfigFormat.AUTO”

\--dtype

Possible choices: auto, half, float16, bfloat16, float, float32

Data type for model weights and activations.

-   “auto” will use FP16 precision for FP32 and FP16 models, and BF16 precision for BF16 models.
    
-   “half” for FP16. Recommended for AWQ quantization.
    
-   “float16” is the same as “half”.
    
-   “bfloat16” for a balance between precision and range.
    
-   “float” is shorthand for FP32 precision.
    
-   “float32” for FP32 precision.
    

Default: “auto”

\--kv-cache-dtype

Possible choices: auto, fp8, fp8\_e5m2, fp8\_e4m3

Data type for kv cache storage. If “auto”, will use model data type. CUDA 11.8+ supports fp8 (=fp8\_e4m3) and fp8\_e5m2. ROCm (AMD GPU) supports fp8 (=fp8\_e4m3)

Default: “auto”

\--quantization-param-path

Path to the JSON file containing the KV cache scaling factors. This should generally be supplied, when KV cache dtype is FP8. Otherwise, KV cache scaling factors default to 1.0, which may cause accuracy issues. FP8\_E5M2 (without scaling) is only supported on cuda version greater than 11.8. On ROCm (AMD GPU), FP8\_E4M3 is instead supported for common inference criteria.

\--max-model-len

Model context length. If unspecified, will be automatically derived from the model config.

\--guided-decoding-backend

Possible choices: outlines, lm-format-enforcer

Which engine will be used for guided decoding (JSON schema / regex etc) by default. Currently support [outlines-dev/outlines](https://github.com/outlines-dev/outlines) and [noamgat/lm-format-enforcer](https://github.com/noamgat/lm-format-enforcer). Can be overridden per request via guided\_decoding\_backend parameter.

Default: “outlines”

\--distributed-executor-backend

Possible choices: ray, mp

Backend to use for distributed model workers, either “ray” or “mp” (multiprocessing). If the product of pipeline\_parallel\_size and tensor\_parallel\_size is less than or equal to the number of GPUs available, “mp” will be used to keep processing on a single host. Otherwise, this will default to “ray” if Ray is installed and fail otherwise. Note that tpu and hpu only support Ray for distributed inference.

\--worker-use-ray

Deprecated, use –distributed-executor-backend=ray.

\--pipeline-parallel-size, -pp

Number of pipeline stages.

Default: 1

\--tensor-parallel-size, -tp

Number of tensor parallel replicas.

Default: 1

\--max-parallel-loading-workers

Load model sequentially in multiple batches, to avoid RAM OOM when using tensor parallel and large models.

\--ray-workers-use-nsight

If specified, use nsight to profile Ray workers.

\--block-size

Possible choices: 8, 16, 32, 64, 128

Token block size for contiguous chunks of tokens. This is ignored on neuron devices and set to max-model-len

Default: 16

\--enable-prefix-caching

Enables automatic prefix caching.

\--disable-sliding-window

Disables sliding window, capping to sliding window size

\--use-v2-block-manager

\[DEPRECATED\] block manager v1 has been removed and SelfAttnBlockSpaceManager (i.e. block manager v2) is now the default. Setting this flag to True or False has no effect on vLLM behavior.

\--num-lookahead-slots

Experimental scheduling config necessary for speculative decoding. This will be replaced by speculative config in the future; it is present to enable correctness tests until then.

Default: 0

\--seed

Random seed for operations.

Default: 0

\--swap-space

CPU swap space size (GiB) per GPU.

Default: 4

\--cpu-offload-gb

The space in GiB to offload to CPU, per GPU. Default is 0, which means no offloading. Intuitively, this argument can be seen as a virtual way to increase the GPU memory size. For example, if you have one 24 GB GPU and set this to 10, virtually you can think of it as a 34 GB GPU. Then you can load a 13B model with BF16 weight, which requires at least 26GB GPU memory. Note that this requires fast CPU-GPU interconnect, as part of the model is loaded from CPU memory to GPU memory on the fly in each model forward pass.

Default: 0

\--gpu-memory-utilization

The fraction of GPU memory to be used for the model executor, which can range from 0 to 1. For example, a value of 0.5 would imply 50% GPU memory utilization. If unspecified, will use the default value of 0.9. This is a global gpu memory utilization limit, for example if 50% of the gpu memory is already used before vLLM starts and –gpu-memory-utilization is set to 0.9, then only 40% of the gpu memory will be allocated to the model executor.

Default: 0.9

\--num-gpu-blocks-override

If specified, ignore GPU profiling result and use this number of GPU blocks. Used for testing preemption.

\--max-num-batched-tokens

Maximum number of batched tokens per iteration.

\--max-num-seqs

Maximum number of sequences per iteration.

Default: 256

\--max-logprobs

Max number of log probs to return logprobs is specified in SamplingParams.

Default: 20

\--disable-log-stats

Disable logging statistics.

\--quantization, -q

Possible choices: aqlm, awq, deepspeedfp, tpu\_int8, fp8, fbgemm\_fp8, modelopt, marlin, gguf, gptq\_marlin\_24, gptq\_marlin, awq\_marlin, gptq, compressed-tensors, bitsandbytes, qqq, experts\_int8, neuron\_quant, ipex, None

Method used to quantize the weights. If None, we first check the quantization\_config attribute in the model config file. If that is None, we assume the model weights are not quantized and use dtype to determine the data type of the weights.

\--rope-scaling

RoPE scaling configuration in JSON format. For example, {“rope\_type”:”dynamic”,”factor”:2.0}

\--rope-theta

RoPE theta. Use with rope\_scaling. In some cases, changing the RoPE theta improves the performance of the scaled model.

\--hf-overrides

Extra arguments for the HuggingFace config. This should be a JSON string that will be parsed into a dictionary.

\--enforce-eager

Always use eager-mode PyTorch. If False, will use eager mode and CUDA graph in hybrid for maximal performance and flexibility.

\--max-seq-len-to-capture

Maximum sequence length covered by CUDA graphs. When a sequence has context length larger than this, we fall back to eager mode. Additionally for encoder-decoder models, if the sequence length of the encoder input is larger than this, we fall back to the eager mode.

Default: 8192

\--disable-custom-all-reduce

See ParallelConfig.

\--tokenizer-pool-size

Size of tokenizer pool to use for asynchronous tokenization. If 0, will use synchronous tokenization.

Default: 0

\--tokenizer-pool-type

Type of tokenizer pool to use for asynchronous tokenization. Ignored if tokenizer\_pool\_size is 0.

Default: “ray”

\--tokenizer-pool-extra-config

Extra config for tokenizer pool. This should be a JSON string that will be parsed into a dictionary. Ignored if tokenizer\_pool\_size is 0.

\--limit-mm-per-prompt

For each multimodal plugin, limit how many input instances to allow for each prompt. Expects a comma-separated list of items, e.g.: image=16,video=2 allows a maximum of 16 images and 2 videos per prompt. Defaults to 1 for each modality.

\--mm-processor-kwargs

Overrides for the multimodal input mapping/processing, e.g., image processor. For example: {“num\_crops”: 4}.

\--enable-lora

If True, enable handling of LoRA adapters.

\--enable-lora-bias

If True, enable bias for LoRA adapters.

\--max-loras

Max number of LoRAs in a single batch.

Default: 1

\--max-lora-rank

Max LoRA rank.

Default: 16

\--lora-extra-vocab-size

Maximum size of extra vocabulary that can be present in a LoRA adapter (added to the base model vocabulary).

Default: 256

\--lora-dtype

Possible choices: auto, float16, bfloat16

Data type for LoRA. If auto, will default to base model dtype.

Default: “auto”

\--long-lora-scaling-factors

Specify multiple scaling factors (which can be different from base model scaling factor - see eg. Long LoRA) to allow for multiple LoRA adapters trained with those scaling factors to be used at the same time. If not specified, only adapters trained with the base model scaling factor are allowed.

\--max-cpu-loras

Maximum number of LoRAs to store in CPU memory. Must be >= than max\_loras. Defaults to max\_loras.

\--fully-sharded-loras

By default, only half of the LoRA computation is sharded with tensor parallelism. Enabling this will use the fully sharded layers. At high sequence length, max rank or tensor parallel size, this is likely faster.

\--enable-prompt-adapter

If True, enable handling of PromptAdapters.

\--max-prompt-adapters

Max number of PromptAdapters in a batch.

Default: 1

\--max-prompt-adapter-token

Max number of PromptAdapters tokens

Default: 0

\--device

Possible choices: auto, cuda, neuron, cpu, openvino, tpu, xpu, hpu

Device type for vLLM execution.

Default: “auto”

\--num-scheduler-steps

Maximum number of forward steps per scheduler call.

Default: 1

\--multi-step-stream-outputs

If False, then multi-step will stream outputs at the end of all steps

Default: True

\--scheduler-delay-factor

Apply a delay (of delay factor multiplied by previous prompt latency) before scheduling next prompt.

Default: 0.0

\--enable-chunked-prefill

If set, the prefill requests can be chunked based on the max\_num\_batched\_tokens.

\--speculative-model

The name of the draft model to be used in speculative decoding.

\--speculative-model-quantization

Possible choices: aqlm, awq, deepspeedfp, tpu\_int8, fp8, fbgemm\_fp8, modelopt, marlin, gguf, gptq\_marlin\_24, gptq\_marlin, awq\_marlin, gptq, compressed-tensors, bitsandbytes, qqq, experts\_int8, neuron\_quant, ipex, None

Method used to quantize the weights of speculative model. If None, we first check the quantization\_config attribute in the model config file. If that is None, we assume the model weights are not quantized and use dtype to determine the data type of the weights.

\--num-speculative-tokens

The number of speculative tokens to sample from the draft model in speculative decoding.

\--speculative-disable-mqa-scorer

If set to True, the MQA scorer will be disabled in speculative and fall back to batch expansion

\--speculative-draft-tensor-parallel-size, -spec-draft-tp

Number of tensor parallel replicas for the draft model in speculative decoding.

\--speculative-max-model-len

The maximum sequence length supported by the draft model. Sequences over this length will skip speculation.

\--speculative-disable-by-batch-size

Disable speculative decoding for new incoming requests if the number of enqueue requests is larger than this value.

\--ngram-prompt-lookup-max

Max size of window for ngram prompt lookup in speculative decoding.

\--ngram-prompt-lookup-min

Min size of window for ngram prompt lookup in speculative decoding.

\--spec-decoding-acceptance-method

Possible choices: rejection\_sampler, typical\_acceptance\_sampler

Specify the acceptance method to use during draft token verification in speculative decoding. Two types of acceptance routines are supported: 1) RejectionSampler which does not allow changing the acceptance rate of draft tokens, 2) TypicalAcceptanceSampler which is configurable, allowing for a higher acceptance rate at the cost of lower quality, and vice versa.

Default: “rejection\_sampler”

\--typical-acceptance-sampler-posterior-threshold

Set the lower bound threshold for the posterior probability of a token to be accepted. This threshold is used by the TypicalAcceptanceSampler to make sampling decisions during speculative decoding. Defaults to 0.09

\--typical-acceptance-sampler-posterior-alpha

A scaling factor for the entropy-based threshold for token acceptance in the TypicalAcceptanceSampler. Typically defaults to sqrt of –typical-acceptance-sampler-posterior-threshold i.e. 0.3

\--disable-logprobs-during-spec-decoding

If set to True, token log probabilities are not returned during speculative decoding. If set to False, log probabilities are returned according to the settings in SamplingParams. If not specified, it defaults to True. Disabling log probabilities during speculative decoding reduces latency by skipping logprob calculation in proposal sampling, target sampling, and after accepted tokens are determined.

\--model-loader-extra-config

Extra config for model loader. This will be passed to the model loader corresponding to the chosen load\_format. This should be a JSON string that will be parsed into a dictionary.

\--ignore-patterns

The pattern(s) to ignore when loading the model.Default to ‘original/[\*\*](https://docs.vllm.ai/en/stable/models/engine_args.html#id1)/[\*](https://docs.vllm.ai/en/stable/models/engine_args.html#id3)’ to avoid repeated loading of llama’s checkpoints.

Default: \[\]

\--preemption-mode

If ‘recompute’, the engine performs preemption by recomputing; If ‘swap’, the engine performs preemption by block swapping.

\--served-model-name

The model name(s) used in the API. If multiple names are provided, the server will respond to any of the provided names. The model name in the model field of a response will be the first name in this list. If not specified, the model name will be the same as the –model argument. Noted that this name(s) will also be used in model\_name tag content of prometheus metrics, if multiple names provided, metrics tag will take the first one.

\--qlora-adapter-name-or-path

Name or path of the QLoRA adapter.

\--otlp-traces-endpoint

Target URL to which OpenTelemetry traces will be sent.

\--collect-detailed-traces

Valid choices are model,worker,all. It makes sense to set this only if –otlp-traces-endpoint is set. If set, it will collect detailed traces for the specified modules. This involves use of possibly costly and or blocking operations and hence might have a performance impact.

\--disable-async-output-proc

Disable async output processing. This may result in lower performance.

\--scheduling-policy

Possible choices: fcfs, priority

The scheduling policy to use. “fcfs” (first come first served, i.e. requests are handled in order of arrival; default) or “priority” (requests are handled based on given priority (lower value means earlier handling) and time of arrival deciding any ties).

Default: “fcfs”

\--override-neuron-config

Override or set neuron device configuration. e.g. {“cast\_logits\_dtype”: “bloat16”}.’

\--override-pooler-config

Override or set the pooling method in the embedding model. e.g. {“pooling\_type”: “mean”, “normalize”: false}.’

## Async Engine Arguments

Below are the additional arguments related to the asynchronous engine:

```
<span></span><span>usage</span><span>:</span> <span>vllm</span> <span>serve</span> <span>[</span><span>-</span><span>h</span><span>]</span> <span>[</span><span>--</span><span>disable</span><span>-</span><span>log</span><span>-</span><span>requests</span><span>]</span>
```

### Named Arguments

\--disable-log-requests

Disable logging requests.