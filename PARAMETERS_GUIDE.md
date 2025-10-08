# Generation Parameters Guide

## Overview

This guide explains all the parameters available for controlling text generation behavior in `llama_flutter_android`.

## Parameter Categories

### 1. Basic Parameters

#### `maxTokens` (int, default: 512)
Maximum number of tokens to generate.

```dart
maxTokens: 256  // Generate up to 256 tokens
```

### 2. Sampling Parameters

#### `temperature` (double, default: 0.7)
Controls randomness. Lower = more focused/deterministic, Higher = more creative/random.

- **0.0**: Greedy (always picks most likely token)
- **0.1-0.5**: Very focused, coherent
- **0.7-0.9**: Balanced (recommended)
- **1.0-1.5**: Creative, diverse
- **2.0+**: Very random, potentially incoherent

```dart
temperature: 0.7  // Good balance
temperature: 0.1  // For factual/coding tasks
temperature: 1.2  // For creative writing
```

#### `topP` (double, default: 0.9, range: 0.0-1.0)
**Nucleus sampling**: Only consider tokens with cumulative probability up to P.

- **0.5**: Very focused (top 50% probability mass)
- **0.9**: Balanced (recommended)
- **0.95**: More diverse
- **1.0**: Consider all tokens

```dart
topP: 0.9  // Good default
topP: 0.5  // More focused than temperature alone
```

#### `topK` (int, default: 40)
Only consider the K most likely tokens.

- **1**: Greedy (same as temperature=0)
- **10-20**: Very focused
- **40-50**: Balanced (recommended)
- **100+**: Very diverse

```dart
topK: 40   // Good default
topK: 10   // For factual tasks
topK: 100  // For creative tasks
```

#### `minP` (double, default: 0.05, range: 0.0-1.0)
**Min-P sampling**: Only consider tokens with probability ≥ (minP × top token probability).

More intuitive than top-p for controlling quality:
- **0.05**: Allow diverse options (recommended)
- **0.1**: More focused
- **0.02**: Very diverse

```dart
minP: 0.05  // Good default
minP: 0.1   // Higher quality, less diversity
```

#### `typicalP` (double, default: 1.0, range: 0.0-1.0)
**Locally typical sampling**: Favors tokens with "typical" information content.

- **1.0**: Disabled (default)
- **0.5-0.95**: Enabled (helps coherence)

```dart
typicalP: 1.0   // Disabled
typicalP: 0.95  // Enabled for better coherence
```

### 3. Penalty Parameters

#### `repeatPenalty` (double, default: 1.1)
Penalizes token repetition. Higher = less repetition.

- **1.0**: No penalty
- **1.1-1.2**: Light penalty (recommended)
- **1.3-1.5**: Strong penalty
- **1.5+**: Very strong (may hurt coherence)

```dart
repeatPenalty: 1.1  // Good default
repeatPenalty: 1.3  // If model repeats too much
repeatPenalty: 1.0  // For poetry/songs (repetition is good)
```

#### `frequencyPenalty` (double, default: 0.0, range: -2.0 to 2.0)
Penalizes tokens based on how often they've appeared.

- **0.0**: No penalty (default)
- **0.5-1.0**: Reduces repetition
- **Negative**: Encourages repetition

```dart
frequencyPenalty: 0.0  // No effect
frequencyPenalty: 0.7  // Reduce repetition
```

#### `presencePenalty` (double, default: 0.0, range: -2.0 to 2.0)
Penalizes tokens that have already appeared (binary: appeared or not).

- **0.0**: No penalty (default)
- **0.5-1.0**: Encourages topic diversity
- **Negative**: Stays on topic

```dart
presencePenalty: 0.0  // No effect
presencePenalty: 0.6  // Encourage new topics
```

#### `repeatLastN` (int, default: 64)
Window size for repetition penalty (how many recent tokens to consider).

- **0**: No repetition penalty
- **64**: Last 64 tokens (recommended)
- **256+**: Longer memory

```dart
repeatLastN: 64   // Good default
repeatLastN: 256  // Long-form content
```

#### `penalizeNewline` (bool, default: true)
Whether to apply repetition penalty to newline characters.

```dart
penalizeNewline: true   // Avoid excessive line breaks
penalizeNewline: false  // For code/poetry
```

### 4. Mirostat Parameters

**Mirostat**: Advanced sampling that maintains perplexity target for coherence.

#### `mirostat` (int, default: 0)
Mirostat algorithm version.

- **0**: Disabled (default, use temperature/top-p/top-k)
- **1**: Mirostat v1
- **2**: Mirostat v2 (recommended if using mirostat)

```dart
mirostat: 0  // Disabled
mirostat: 2  // Enable Mirostat v2
```

#### `mirostatTau` (double, default: 5.0)
Target perplexity (entropy). Controls coherence.

- **3-4**: Very focused
- **5**: Balanced (default)
- **6-8**: More creative

Only used when `mirostat > 0`.

```dart
mirostatTau: 5.0  // Good default
```

#### `mirostatEta` (double, default: 0.1)
Learning rate for Mirostat algorithm.

- **0.05-0.1**: Smooth adaptation (recommended)
- **0.2+**: Faster adaptation

Only used when `mirostat > 0`.

```dart
mirostatEta: 0.1  // Good default
```

### 5. Other Parameters

#### `seed` (int?, default: null)
Random seed for reproducibility.

- **null**: Random seed (non-deterministic)
- **Any int**: Fixed seed (deterministic)

```dart
seed: null    // Different output each time
seed: 42      // Same output every time (with same temperature etc)
```

## Parameter Combinations

### For Factual/Coding Tasks
```dart
temperature: 0.1,
topP: 0.9,
topK: 40,
repeatPenalty: 1.1,
mirostat: 0,
```

### For Balanced Chat
```dart
temperature: 0.7,
topP: 0.9,
topK: 40,
minP: 0.05,
repeatPenalty: 1.1,
frequencyPenalty: 0.0,
presencePenalty: 0.0,
```

### For Creative Writing
```dart
temperature: 1.0,
topP: 0.95,
topK: 100,
minP: 0.02,
repeatPenalty: 1.15,
presencePenalty: 0.5,
```

### Using Mirostat (Alternative to Temperature)
```dart
temperature: 1.0,  // Set to 1.0 when using mirostat
mirostat: 2,
mirostatTau: 5.0,
mirostatEta: 0.1,
```

### For Deterministic Output
```dart
temperature: 0.0,  // or
topK: 1,           // Same effect
seed: 42,          // Fixed seed
```

## Usage Examples

### Basic Chat
```dart
await controller.generateChat(
  messages: messages,
  maxTokens: 256,
  temperature: 0.7,
  topP: 0.9,
  topK: 40,
);
```

### Advanced Control
```dart
await controller.generateChat(
  messages: messages,
  maxTokens: 512,
  temperature: 0.8,
  topP: 0.9,
  topK: 50,
  minP: 0.05,
  repeatPenalty: 1.2,
  frequencyPenalty: 0.5,
  presencePenalty: 0.3,
  repeatLastN: 128,
  seed: 42,  // Reproducible
);
```

### Code Generation
```dart
await controller.generate(
  prompt: "Write a Python function to...",
  maxTokens: 500,
  temperature: 0.1,
  topP: 0.95,
  topK: 40,
  repeatPenalty: 1.05,
  penalizeNewline: false,  // Don't penalize code formatting
);
```

## Parameter Priority

When multiple sampling methods are enabled:

1. **Temperature = 0** → Greedy (ignores everything else)
2. **Mirostat > 0** → Uses mirostat (ignores top-p/top-k)
3. **Otherwise**: Temperature → Min-P → Top-K → Top-P → Typical-P

## Tips

1. **Start simple**: Use just `temperature` and `topP`, add others if needed
2. **Repetition issues**: Increase `repeatPenalty` or add `frequencyPenalty`
3. **Too creative/random**: Lower `temperature` or `topP`
4. **Too boring**: Increase `temperature` or add `presencePenalty`
5. **For experimentation**: Use `seed` to make results reproducible
6. **Mirostat**: Good for maintaining coherence, try it if temperature isn't working well

## System Prompt

The system prompt is set via the first message with `role: 'system'`:

```dart
final messages = [
  ChatMessage(
    role: 'system',
    content: '''You are a helpful AI assistant.
    - Be concise and accurate
    - Use markdown formatting
    - Always cite sources when possible''',
  ),
  ChatMessage(role: 'user', content: 'Hello!'),
];
```

## Model-Specific Settings

Different models may respond better to different parameters:

- **Qwen**: Works well with default settings
- **Llama-2**: Often needs higher `repeatPenalty` (1.2-1.3)
- **Code models**: Use low temperature (0.1-0.3)
- **Small models** (<1B): May need stronger penalties

## See Also

- [Chat Templates](CHAT_TEMPLATES.md)
- [Quick Start](CHAT_TEMPLATE_QUICKSTART.md)
- [API Reference](README.md)
