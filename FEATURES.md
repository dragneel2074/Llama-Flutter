# Complete Feature Reference

## All Available Parameters

### Generation Control
| Parameter | Type | Default | Description | Guide |
|-----------|------|---------|-------------|-------|
| `maxTokens` | int | 512 | Maximum tokens to generate | [PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md#maxtokens-int-default-512) |

### Sampling Parameters  
| Parameter | Type | Default | Description | Guide |
|-----------|------|---------|-------------|-------|
| `temperature` | double | 0.7 | Randomness (0=deterministic, 2+=creative) | [PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md#temperature-double-default-07) |
| `topP` | double | 0.9 | Nucleus sampling threshold | [PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md#topp-double-default-09-range-00-10) |
| `topK` | int | 40 | Consider top K tokens | [PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md#topk-int-default-40) |
| `minP` | double | 0.05 | Min probability threshold | [PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md#minp-double-default-005-range-00-10) |
| `typicalP` | double | 1.0 | Locally typical sampling (1.0=off) | [PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md#typicalp-double-default-10-range-00-10) |

### Penalty Parameters
| Parameter | Type | Default | Description | Guide |
|-----------|------|---------|-------------|-------|
| `repeatPenalty` | double | 1.1 | Penalize repetition (1.0=none) | [PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md#repeatpenalty-double-default-11) |
| `frequencyPenalty` | double | 0.0 | Penalize frequent tokens | [PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md#frequencypenalty-double-default-00-range--20-to-20) |
| `presencePenalty` | double | 0.0 | Penalize tokens that appeared | [PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md#presencepenalty-double-default-00-range--20-to-20) |
| `repeatLastN` | int | 64 | Repetition penalty window size | [PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md#repeatlastn-int-default-64) |
| `penalizeNewline` | bool | true | Apply penalty to newlines | [PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md#penalizenewline-bool-default-true) |

### Mirostat Parameters
| Parameter | Type | Default | Description | Guide |
|-----------|------|---------|-------------|-------|
| `mirostat` | int | 0 | Mirostat mode (0=off, 1/2=on) | [PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md#mirostat-int-default-0) |
| `mirostatTau` | double | 5.0 | Target perplexity | [PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md#mirostattau-double-default-50) |
| `mirostatEta` | double | 0.1 | Learning rate | [PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md#mirostateta-double-default-01) |

### Other Parameters
| Parameter | Type | Default | Description | Guide |
|-----------|------|---------|-------------|-------|
| `seed` | int? | null | Random seed (null=random) | [PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md#seed-int-default-null) |

### Chat-Specific
| Parameter | Type | Default | Description | Guide |
|-----------|------|---------|-------------|-------|
| `messages` | List<ChatMessage> | required | Conversation history | [CHAT_TEMPLATES.md](CHAT_TEMPLATES.md#message-roles) |
| `template` | String? | null | Chat template (null=auto) | [CHAT_TEMPLATES.md](CHAT_TEMPLATES.md#supported-templates) |

### Model Loading
| Parameter | Type | Default | Description | Guide |
|-----------|------|---------|-------------|-------|
| `modelPath` | String | required | Path to GGUF file | [QUICK_START.md](QUICK_START.md) |
| `nThreads` | int | 4 | CPU threads to use | [QUICK_START.md](QUICK_START.md) |
| `contextSize` | int | 2048 | Context window size | [QUICK_START.md](QUICK_START.md) |
| `nGpuLayers` | int? | null | GPU layers (null=CPU only) | [QUICK_START.md](QUICK_START.md) |

## Chat Templates

### Supported Templates
| Template | Models | Format |
|----------|--------|--------|
| `chatml` | Qwen, Llama-3, Command-R | `<\|im_start\|>...<\|im_end\|>` |
| `llama2` | Llama-2, Code Llama | `[INST]...[/INST]` |
| `alpaca` | Alpaca | `### Instruction:...` |
| `vicuna` | Vicuna | `USER:...ASSISTANT:` |
| `phi` | Phi-2, Phi-3 | `<\|system\|>...<\|end\|>` |
| `gemma` | Gemma | `<start_of_turn>...<end_of_turn>` |

Full details: [CHAT_TEMPLATES.md](CHAT_TEMPLATES.md)

## System Prompt

Set via first message with `role: 'system'`:

```dart
final messages = [
  ChatMessage(
    role: 'system',
    content: 'You are a helpful assistant.',
  ),
  // ... user messages
];
```

## Quick Examples

### Basic Chat
```dart
await controller.generateChat(
  messages: [
    ChatMessage(role: 'system', content: 'You are helpful.'),
    ChatMessage(role: 'user', content: 'Hello!'),
  ],
);
```

### With All Parameters
```dart
await controller.generateChat(
  messages: messages,
  template: 'chatml',           // Force specific template
  maxTokens: 500,
  temperature: 0.8,
  topP: 0.9,
  topK: 50,
  minP: 0.05,
  typicalP: 1.0,
  repeatPenalty: 1.2,
  frequencyPenalty: 0.5,
  presencePenalty: 0.3,
  repeatLastN: 128,
  mirostat: 0,
  mirostatTau: 5.0,
  mirostatEta: 0.1,
  seed: 42,
  penalizeNewline: true,
);
```

### Common Presets

#### Factual/Coding
```dart
temperature: 0.1,
topP: 0.9,
repeatPenalty: 1.1,
```

#### Balanced Chat
```dart
temperature: 0.7,
topP: 0.9,
topK: 40,
repeatPenalty: 1.1,
```

#### Creative Writing
```dart
temperature: 1.0,
topP: 0.95,
topK: 100,
repeatPenalty: 1.15,
presencePenalty: 0.5,
```

## Documentation Index

1. **[QUICK_START.md](QUICK_START.md)** - Get started in 5 minutes
2. **[PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md)** - Complete parameter reference ⭐
3. **[CHAT_TEMPLATES.md](CHAT_TEMPLATES.md)** - Chat template formats
4. **[CHAT_TEMPLATE_QUICKSTART.md](CHAT_TEMPLATE_QUICKSTART.md)** - Quick template usage
5. **[README.md](README.md)** - Project overview
6. **[ARCHITECTURE.md](ARCHITECTURE.md)** - Technical details

## API Methods

### LlamaController

```dart
// Load model
await controller.loadModel(
  modelPath: '/path/to/model.gguf',
  threads: 4,
  contextSize: 2048,
  gpuLayers: null,
);

// Generate with raw prompt
final stream = controller.generate(
  prompt: 'Your formatted prompt',
  maxTokens: 512,
  temperature: 0.7,
  // ... all other parameters
);

// Generate with chat template
final stream = controller.generateChat(
  messages: [
    ChatMessage(role: 'user', content: 'Hello'),
  ],
  maxTokens: 512,
  temperature: 0.7,
  // ... all other parameters
);

// Stop generation
await controller.stop();

// Cleanup
await controller.dispose();

// Check status
bool loaded = await controller.isModelLoaded();
bool generating = controller.isGenerating;

// Get supported templates
List<String> templates = await controller.getSupportedTemplates();
```

## Missing Features (Potential Future Additions)

- [ ] Logit bias (boost/suppress specific tokens)
- [ ] Custom stop sequences
- [ ] Grammar constraints (JSON/XML mode)
- [ ] Multiple sequence generation (n parameter)
- [ ] Token probability output
- [ ] Streaming with backpressure control
- [ ] Model quantization settings
- [ ] KV cache management
- [ ] Batch processing

## Contributing

Want to add a feature? See [CONTRIBUTING.md](CONTRIBUTING.md)

## Questions?

- **Parameters**: See [PARAMETERS_GUIDE.md](PARAMETERS_GUIDE.md)
- **Templates**: See [CHAT_TEMPLATES.md](CHAT_TEMPLATES.md)
- **Issues**: Open a GitHub issue
