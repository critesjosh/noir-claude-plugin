# UX Patterns

Proving in the browser is slow and resource-intensive. Good UX design is essential to keep users informed and prevent confusion.

## Progress Indicators

### Phase-Based Status

Report proving phases to give users a sense of progress:

```typescript
// In the worker
self.postMessage({ type: "status", phase: "witness" });
const { witness } = await noir.execute(inputs);

self.postMessage({ type: "status", phase: "proving" });
const proof = await backend.generateProof(witness);

self.postMessage({ type: "status", phase: "done" });
```

```typescript
// In the React component
const phaseLabels: Record<string, string> = {
  witness: "Generating witness...",
  proving: "Creating proof...",
  done: "Proof ready!",
};

worker.onmessage = (e) => {
  if (e.data.type === "status") {
    setPhaseLabel(phaseLabels[e.data.phase]);
  }
};
```

### Indeterminate Progress Bar

Proving time is unpredictable and depends on circuit size, device speed, and available memory. Use an indeterminate progress bar (animated, no percentage):

```typescript
{status === "proving" && (
  <div className="progress-container">
    <div className="progress-bar indeterminate" />
    <p>{phaseLabel}</p>
  </div>
)}
```

### Estimated Time

Give users a rough expectation based on circuit size:

| Circuit Size | Constraint Count | Estimated Time |
|-------------|-----------------|----------------|
| Small | < 10,000 | 1-5 seconds |
| Medium | 10,000-100,000 | 5-30 seconds |
| Large | 100,000+ | 30 seconds to minutes |

```typescript
<p>This proof typically takes 5-15 seconds. Please keep this tab open.</p>
```

Warn users not to close the tab during proving.

## Error Design

### Witness Generation Errors

These are almost always caused by bad inputs. The error messages from WASM are often cryptic, so translate them into user-friendly messages:

```typescript
worker.onmessage = (e) => {
  if (e.data.type === "error") {
    const msg = e.data.error;
    if (msg.includes("Cannot satisfy constraint")) {
      setError("Invalid inputs. Please check your values and try again.");
    } else if (msg.includes("expected")) {
      setError("Input format error. Check that all fields are filled correctly.");
    } else {
      setError("An unexpected error occurred. Please refresh and try again.");
    }
  }
};
```

### Proving Errors

Usually caused by WASM or memory issues. Suggest a page refresh:

```typescript
<div className="error">
  <p>Proof generation failed.</p>
  <p>Try refreshing the page. If the problem persists, the circuit may be too large for this device.</p>
  <button onClick={() => window.location.reload()}>Refresh</button>
</div>
```

### Verification Errors

The proof is invalid. Show a clear failure state:

```typescript
<div className="verification-result">
  {isValid ? (
    <span className="badge valid">Verified</span>
  ) : (
    <span className="badge invalid">Invalid Proof</span>
  )}
</div>
```

## Mobile Considerations

### Memory Limits

Mobile devices have significantly less available memory than desktops. Large circuits (100k+ constraints) may crash mobile browsers without warning.

```typescript
function isMobileDevice(): boolean {
  return /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
}

function ProofComponent({ circuit }: { circuit: CompiledCircuit }) {
  const isMobile = isMobileDevice();

  return (
    <div>
      {isMobile && (
        <div className="warning">
          Proof generation is resource-intensive. For the best experience, use a
          desktop browser.
        </div>
      )}
      {/* ... proving UI */}
    </div>
  );
}
```

### Server-Side Proving Fallback

For heavy circuits on mobile, consider offloading proving to a server:

```typescript
async function proveServerSide(inputs: Record<string, string>) {
  const response = await fetch("/api/prove", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ inputs }),
  });
  return response.json();
}
```

This trades privacy for usability -- the server sees the inputs. Document this trade-off for users.

## Proof Display

### Truncated Proof Hex

Proofs are binary data. Show a truncated representation:

```typescript
function ProofDisplay({ proof }: { proof: Uint8Array }) {
  const hex = Array.from(proof.slice(0, 32))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  return (
    <div className="proof-display">
      <span className="badge">Proof Generated</span>
      <code>{hex}...({proof.length} bytes)</code>
    </div>
  );
}
```

### Copy to Clipboard

```typescript
function CopyProofButton({ proof }: { proof: Uint8Array }) {
  const [copied, setCopied] = useState(false);

  const copy = async () => {
    const hex = Array.from(proof)
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
    await navigator.clipboard.writeText(hex);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <button onClick={copy}>
      {copied ? "Copied!" : "Copy proof"}
    </button>
  );
}
```

### Download as File

```typescript
function DownloadProofButton({ proof }: { proof: Uint8Array }) {
  const download = () => {
    const blob = new Blob([proof], { type: "application/octet-stream" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "proof.bin";
    a.click();
    URL.revokeObjectURL(url);
  };

  return <button onClick={download}>Download proof</button>;
}
```

## Input Forms

### Field Inputs

Accept both hex and decimal formats:

```typescript
function FieldInput({
  label,
  value,
  onChange,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
}) {
  const isValid = /^(0x[0-9a-fA-F]+|\d+)$/.test(value) || value === "";

  return (
    <label>
      {label}
      <input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder="Decimal or 0x hex"
        className={isValid ? "" : "invalid"}
      />
      {!isValid && <span className="hint">Enter a decimal or hex number</span>}
    </label>
  );
}
```

### Array Inputs

Dynamic list with add and remove:

```typescript
function ArrayInput({
  label,
  values,
  onChange,
}: {
  label: string;
  values: string[];
  onChange: (v: string[]) => void;
}) {
  return (
    <fieldset>
      <legend>{label}</legend>
      {values.map((val, i) => (
        <div key={i} className="array-row">
          <input
            type="text"
            value={val}
            onChange={(e) => {
              const next = [...values];
              next[i] = e.target.value;
              onChange(next);
            }}
          />
          <button type="button" onClick={() => onChange(values.filter((_, j) => j !== i))}>
            Remove
          </button>
        </div>
      ))}
      <button type="button" onClick={() => onChange([...values, ""])}>
        Add element
      </button>
    </fieldset>
  );
}
```

### File Inputs

For large witness data, let users upload a file:

```typescript
function FileInput({
  label,
  onLoad,
}: {
  label: string;
  onLoad: (data: Record<string, any>) => void;
}) {
  const handleFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const text = await file.text();
    try {
      const data = JSON.parse(text);
      onLoad(data);
    } catch {
      alert("Invalid JSON file.");
    }
  };

  return (
    <label>
      {label}
      <input type="file" accept=".json" onChange={handleFile} />
    </label>
  );
}
```

## Verification UI

### Separate Verify Action

Useful when a third party needs to verify a proof they did not generate:

```typescript
function VerifyForm({ circuit }: { circuit: CompiledCircuit }) {
  const [proofHex, setProofHex] = useState("");
  const [publicInputs, setPublicInputs] = useState<string[]>([""]);
  const [result, setResult] = useState<boolean | null>(null);
  const workerRef = useRef<Worker | null>(null);

  // Initialize worker (same pattern as proving)

  const verify = () => {
    const proofBytes = new Uint8Array(
      proofHex.match(/.{1,2}/g)!.map((byte) => parseInt(byte, 16))
    );
    workerRef.current?.postMessage({
      type: "verify",
      circuit,
      proof: proofBytes,
      publicInputs,
    });
  };

  return (
    <div>
      <textarea
        placeholder="Paste proof hex"
        value={proofHex}
        onChange={(e) => setProofHex(e.target.value)}
      />
      <ArrayInput
        label="Public Inputs"
        values={publicInputs}
        onChange={setPublicInputs}
      />
      <button onClick={verify}>Verify</button>

      {result !== null && (
        <div className={result ? "valid" : "invalid"}>
          {result ? "Proof is valid" : "Proof is invalid"}
        </div>
      )}
    </div>
  );
}
```

### Public Inputs Display

Show public inputs alongside the verification result so verifiers know what was proven:

```typescript
function VerificationResult({
  isValid,
  publicInputs,
}: {
  isValid: boolean;
  publicInputs: string[];
}) {
  return (
    <div className="verification-result">
      <div className={isValid ? "badge valid" : "badge invalid"}>
        {isValid ? "Valid" : "Invalid"}
      </div>
      {publicInputs.length > 0 && (
        <div>
          <h4>Public Inputs</h4>
          <ul>
            {publicInputs.map((input, i) => (
              <li key={i}>
                <code>{input}</code>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
```
