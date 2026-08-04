"use strict";

const examples = {
  counter: [
    "local count = scope:Value(1)",
    "local doubled = scope:Computed(function()",
    "    return count:Get() * 2",
    "end)",
    "count:Set(2)",
    "scope:Batch(function()",
    "    count:Set(4)",
    "    count:Set(6)",
    "end)",
    "count:Update(function(current)",
    "    return current + 1",
    "end)",
  ].join("\n"),
  cart: [
    "local price = scope:Value(25)",
    "local quantity = scope:Value(1)",
    "local total = scope:Computed(function()",
    "    return price:Get() * quantity:Get()",
    "end)",
    "quantity:Set(2)",
    "scope:Batch(function()",
    "    price:Set(30)",
    "    quantity:Set(3)",
    "end)",
  ].join("\n"),
  health: [
    "local health = scope:Value(100)",
    "local armor = scope:Value(40)",
    "local effective = scope:Computed(function()",
    "    return health:Get() + armor:Get() * 0.5",
    "end)",
    "health:Set(70)",
    "armor:Update(function(current)",
    "    return current - 10",
    "end)",
  ].join("\n"),
};

const editor = document.getElementById("scriptEditor");
const picker = document.getElementById("examplePicker");
const runButton = document.getElementById("runButton");
const resetButton = document.getElementById("resetButton");
const errorOutput = document.getElementById("editorError");
const runtimeState = document.getElementById("runtimeState");
const writeCount = document.getElementById("writeCount");
const recomputeCount = document.getElementById("recomputeCount");
const paintCount = document.getElementById("paintCount");
const valueNodes = document.getElementById("valueNodes");
const computedNodes = document.getElementById("computedNodes");
const previewHeadline = document.getElementById("previewHeadline");
const previewDetail = document.getElementById("previewDetail");
const previewBars = document.getElementById("previewBars");
const trace = document.getElementById("trace");
const incrementButton = document.getElementById("incrementButton");
const batchButton = document.getElementById("batchButton");

let runVersion = 0;
let running = false;
let model = createModel();

function createModel() {
  return {
    values: new Map(),
    computed: new Map(),
    writes: 0,
    recomputes: 0,
    paints: 0,
  };
}

function wait(milliseconds) {
  return new Promise(function(resolve) {
    window.setTimeout(resolve, milliseconds);
  });
}

function codeLine(lines, index) {
  return lines[index].replace(/--.*$/, "").trim();
}

function parseMutation(lines, index) {
  const line = codeLine(lines, index);
  let match = line.match(/^([A-Za-z_]\w*):Set\((-?\d+(?:\.\d+)?)\)$/);
  if (match) {
    return {
      operation: {
        type: "set",
        name: match[1],
        value: Number(match[2]),
        line: index + 1,
      },
      next: index + 1,
    };
  }

  match = line.match(/^([A-Za-z_]\w*):Update\(function\(current\)$/);
  if (match) {
    let returnIndex = index + 1;
    while (returnIndex < lines.length && !codeLine(lines, returnIndex)) {
      returnIndex += 1;
    }
    const returnMatch = returnIndex < lines.length
      ? codeLine(lines, returnIndex).match(/^return\s+(.+)$/)
      : null;
    if (!returnMatch) {
      throw new Error("Line " + (index + 1) + ": Update needs a return expression");
    }
    let endIndex = returnIndex + 1;
    while (endIndex < lines.length && !codeLine(lines, endIndex)) {
      endIndex += 1;
    }
    if (endIndex >= lines.length || codeLine(lines, endIndex) !== "end)") {
      throw new Error("Line " + (index + 1) + ": close Update with end)");
    }
    return {
      operation: {
        type: "update",
        name: match[1],
        expression: returnMatch[1],
        line: index + 1,
      },
      next: endIndex + 1,
    };
  }

  return null;
}

function parseProgram(source) {
  const lines = source.split(/\r?\n/);
  const operations = [];
  let index = 0;

  while (index < lines.length) {
    const line = codeLine(lines, index);
    let match;

    if (!line) {
      index += 1;
      continue;
    }

    match = line.match(/^local\s+([A-Za-z_]\w*)\s*=\s*scope:Value\((-?\d+(?:\.\d+)?)\)$/);
    if (match) {
      operations.push({
        type: "value",
        name: match[1],
        value: Number(match[2]),
        line: index + 1,
      });
      index += 1;
      continue;
    }

    match = line.match(/^local\s+([A-Za-z_]\w*)\s*=\s*scope:Computed\(function\(\)$/);
    if (match) {
      let returnIndex = index + 1;
      while (returnIndex < lines.length && !codeLine(lines, returnIndex)) {
        returnIndex += 1;
      }
      const returnMatch = returnIndex < lines.length
        ? codeLine(lines, returnIndex).match(/^return\s+(.+)$/)
        : null;
      if (!returnMatch) {
        throw new Error("Line " + (index + 1) + ": Computed needs a return expression");
      }
      let endIndex = returnIndex + 1;
      while (endIndex < lines.length && !codeLine(lines, endIndex)) {
        endIndex += 1;
      }
      if (endIndex >= lines.length || codeLine(lines, endIndex) !== "end)") {
        throw new Error("Line " + (index + 1) + ": close Computed with end)");
      }
      operations.push({
        type: "computed",
        name: match[1],
        expression: returnMatch[1],
        line: index + 1,
      });
      index = endIndex + 1;
      continue;
    }

    if (/^scope:Batch\(function\(\)$/.test(line)) {
      const mutations = [];
      let cursor = index + 1;
      let closed = false;
      while (cursor < lines.length) {
        const nestedLine = codeLine(lines, cursor);
        if (!nestedLine) {
          cursor += 1;
          continue;
        }
        if (nestedLine === "end)") {
          closed = true;
          cursor += 1;
          break;
        }
        const parsed = parseMutation(lines, cursor);
        if (!parsed) {
          throw new Error("Line " + (cursor + 1) + ": Batch supports Set and Update");
        }
        mutations.push(parsed.operation);
        cursor = parsed.next;
      }
      if (!closed) {
        throw new Error("Line " + (index + 1) + ": close Batch with end)");
      }
      if (mutations.length === 0) {
        throw new Error("Line " + (index + 1) + ": Batch cannot be empty");
      }
      operations.push({ type: "batch", mutations: mutations, line: index + 1 });
      index = cursor;
      continue;
    }

    const mutation = parseMutation(lines, index);
    if (mutation) {
      operations.push(mutation.operation);
      index = mutation.next;
      continue;
    }

    throw new Error("Line " + (index + 1) + ": unsupported statement");
  }

  if (operations.length === 0) {
    throw new Error("Add at least one supported Weave statement.");
  }

  return operations;
}

function expressionDependencies(expression) {
  const dependencies = [];
  const pattern = /([A-Za-z_]\w*):Get\(\)/g;
  let match;
  while ((match = pattern.exec(expression)) !== null) {
    if (!dependencies.includes(match[1])) {
      dependencies.push(match[1]);
    }
  }
  return dependencies;
}

function evaluateExpression(expression, current) {
  let numeric = expression;
  numeric = numeric.replace(/([A-Za-z_]\w*):Get\(\)/g, function(_, name) {
    if (model.values.has(name)) {
      return String(model.values.get(name));
    }
    if (model.computed.has(name)) {
      return String(model.computed.get(name).value);
    }
    throw new Error("Unknown state " + name + " in expression");
  });
  if (typeof current === "number") {
    numeric = numeric.replace(/\bcurrent\b/g, String(current));
  }
  if (!/^[0-9+\-*/().\s]+$/.test(numeric)) {
    throw new Error("Expressions support numeric state reads and arithmetic only");
  }
  const result = Function('"use strict"; return (' + numeric + ");")();
  if (typeof result !== "number" || !Number.isFinite(result)) {
    throw new Error("Expression did not produce a finite number");
  }
  return result;
}

function addTrace(kind, label, detail) {
  const item = document.createElement("li");
  item.className = kind;
  const strong = document.createElement("strong");
  strong.textContent = label;
  const span = document.createElement("span");
  span.textContent = detail;
  item.append(strong, span);
  trace.appendChild(item);
  trace.scrollTop = trace.scrollHeight;
}

function formatNumber(value) {
  return Number.isInteger(value) ? String(value) : String(Number(value.toFixed(3)));
}

function renderNodeList(target, entries, kind) {
  target.replaceChildren();
  if (entries.length === 0) {
    const empty = document.createElement("div");
    empty.className = "empty-node";
    empty.textContent = kind === "computed" ? "No computed state yet" : "No values yet";
    target.appendChild(empty);
    return;
  }

  entries.forEach(function(entry) {
    const node = document.createElement("div");
    node.className = "state-node " + (kind === "computed" ? "computed" : "");
    node.dataset.state = entry.name;

    const title = document.createElement("div");
    title.className = "node-title";
    const name = document.createElement("strong");
    name.textContent = entry.name;
    const badge = document.createElement("span");
    badge.textContent = kind === "computed" ? "cached" : "writable";
    title.append(name, badge);

    const value = document.createElement("span");
    value.className = "node-value";
    value.textContent = formatNumber(entry.value);
    node.append(title, value);

    if (kind === "computed") {
      const deps = document.createElement("span");
      deps.className = "node-deps";
      deps.textContent = "reads " + entry.dependencies.join(", ");
      node.appendChild(deps);
    }

    target.appendChild(node);
  });
}

function renderPreview() {
  const values = Array.from(model.values, function(entry) {
    return { name: entry[0], value: entry[1] };
  });
  const computed = Array.from(model.computed, function(entry) {
    return {
      name: entry[0],
      value: entry[1].value,
      dependencies: entry[1].dependencies,
    };
  });

  renderNodeList(valueNodes, values, "value");
  renderNodeList(computedNodes, computed, "computed");

  if (values.length === 0) {
    previewHeadline.textContent = "Run a program";
    previewDetail.textContent = "Bindings will settle here.";
    previewBars.replaceChildren();
  } else {
    const primary = computed.length > 0 ? computed[computed.length - 1] : values[0];
    previewHeadline.textContent = primary.name + " = " + formatNumber(primary.value);
    previewDetail.textContent = values.map(function(entry) {
      return entry.name + " " + formatNumber(entry.value);
    }).join("  |  ");
    previewBars.replaceChildren();

    const maxMagnitude = Math.max.apply(null, values.map(function(entry) {
      return Math.abs(entry.value);
    }).concat([1]));
    values.forEach(function(entry) {
      const row = document.createElement("div");
      row.className = "preview-bar";
      const label = document.createElement("div");
      label.className = "preview-bar-label";
      const name = document.createElement("span");
      name.textContent = entry.name;
      const value = document.createElement("strong");
      value.textContent = formatNumber(entry.value);
      label.append(name, value);
      const track = document.createElement("div");
      track.className = "preview-track";
      const fill = document.createElement("div");
      fill.className = "preview-fill";
      fill.style.width = Math.max(4, Math.min(100, Math.abs(entry.value) / maxMagnitude * 100)) + "%";
      track.appendChild(fill);
      row.append(label, track);
      previewBars.appendChild(row);
    });
  }

  writeCount.textContent = String(model.writes);
  recomputeCount.textContent = String(model.recomputes);
  paintCount.textContent = String(model.paints);
}

function pulseStates(names) {
  names.forEach(function(name) {
    const node = document.querySelector('[data-state="' + name + '"]');
    if (node) {
      node.classList.add("is-active");
      window.setTimeout(function() {
        node.classList.remove("is-active");
      }, 240);
    }
  });
}

function assertWritable(operation) {
  if (!model.values.has(operation.name)) {
    throw new Error("Line " + operation.line + ": unknown Value " + operation.name);
  }
}

function applyMutation(operation, changed) {
  assertWritable(operation);
  const previous = model.values.get(operation.name);
  const next = operation.type === "set"
    ? operation.value
    : evaluateExpression(operation.expression, previous);
  model.values.set(operation.name, next);
  model.writes += 1;
  changed.add(operation.name);
  return { previous: previous, next: next };
}

function flush(changed) {
  const invalidated = new Set(changed);
  const recomputed = [];

  model.computed.forEach(function(entry, name) {
    const affected = entry.dependencies.some(function(dependency) {
      return invalidated.has(dependency);
    });
    if (affected) {
      const previous = entry.value;
      entry.value = evaluateExpression(entry.expression);
      model.recomputes += 1;
      recomputed.push(name);
      if (entry.value !== previous) {
        invalidated.add(name);
      }
    }
  });

  model.paints += 1;
  renderPreview();
  pulseStates(Array.from(changed).concat(recomputed));
  return recomputed;
}

async function executeOperation(operation, version) {
  if (version !== runVersion) {
    return;
  }

  if (operation.type === "value") {
    if (model.values.has(operation.name) || model.computed.has(operation.name)) {
      throw new Error("Line " + operation.line + ": duplicate state " + operation.name);
    }
    model.values.set(operation.name, operation.value);
    addTrace("write", "create", operation.name + " starts at " + formatNumber(operation.value));
    renderPreview();
    pulseStates([operation.name]);
  } else if (operation.type === "computed") {
    if (model.values.has(operation.name) || model.computed.has(operation.name)) {
      throw new Error("Line " + operation.line + ": duplicate state " + operation.name);
    }
    const dependencies = expressionDependencies(operation.expression);
    if (dependencies.length === 0) {
      throw new Error("Line " + operation.line + ": Computed must read state with Get()");
    }
    const value = evaluateExpression(operation.expression);
    model.computed.set(operation.name, {
      expression: operation.expression,
      dependencies: dependencies,
      value: value,
    });
    model.recomputes += 1;
    addTrace("compute", "track", operation.name + " reads " + dependencies.join(", "));
    renderPreview();
    pulseStates([operation.name]);
  } else if (operation.type === "set" || operation.type === "update") {
    const changed = new Set();
    const result = applyMutation(operation, changed);
    const recomputed = flush(changed);
    addTrace(
      "write",
      operation.type,
      operation.name + " " + formatNumber(result.previous) + " to " + formatNumber(result.next)
        + (recomputed.length ? "; recomputed " + recomputed.join(", ") : "")
    );
  } else if (operation.type === "batch") {
    const changed = new Set();
    operation.mutations.forEach(function(mutation) {
      applyMutation(mutation, changed);
    });
    const recomputed = flush(changed);
    addTrace(
      "batch",
      "batch",
      operation.mutations.length + " writes, 1 paint"
        + (recomputed.length ? ", recomputed " + recomputed.join(", ") : "")
    );
  }

  await wait(430);
}

function setRuntime(label, stateClass) {
  runtimeState.textContent = label;
  runtimeState.className = "runtime-state" + (stateClass ? " " + stateClass : "");
}

async function runProgram() {
  const version = ++runVersion;
  let operations;

  try {
    operations = parseProgram(editor.value);
  } catch (error) {
    errorOutput.textContent = error.message;
    setRuntime("Needs attention", "");
    return;
  }

  model = createModel();
  running = true;
  runButton.disabled = true;
  incrementButton.disabled = true;
  batchButton.disabled = true;
  errorOutput.textContent = "";
  trace.replaceChildren();
  renderPreview();
  setRuntime("Propagating", "is-running");

  try {
    for (const operation of operations) {
      await executeOperation(operation, version);
    }
    if (version !== runVersion) {
      return;
    }
    setRuntime("Settled", "is-complete");
    const hasValue = model.values.size > 0;
    incrementButton.disabled = !hasValue;
    batchButton.disabled = !hasValue;
  } catch (error) {
    if (version === runVersion) {
      errorOutput.textContent = error.message;
      setRuntime("Stopped", "");
    }
  } finally {
    if (version === runVersion) {
      running = false;
      runButton.disabled = false;
    }
  }
}

function firstValueName() {
  return model.values.keys().next().value;
}

function quickWrite(amount, batched) {
  if (running || model.values.size === 0) {
    return;
  }
  const name = firstValueName();
  const changed = new Set([name]);
  const previous = model.values.get(name);
  const writes = batched ? 3 : 1;
  for (let index = 0; index < writes; index += 1) {
    model.values.set(name, model.values.get(name) + amount);
    model.writes += 1;
  }
  const recomputed = flush(changed);
  addTrace(
    batched ? "batch" : "write",
    batched ? "quick batch" : "quick set",
    name + " " + formatNumber(previous) + " to " + formatNumber(model.values.get(name))
      + (recomputed.length ? "; recomputed " + recomputed.join(", ") : "")
  );
  setRuntime("Settled", "is-complete");
}

function loadExample(name) {
  ++runVersion;
  running = false;
  editor.value = examples[name];
  model = createModel();
  trace.replaceChildren();
  errorOutput.textContent = "";
  runButton.disabled = false;
  incrementButton.disabled = true;
  batchButton.disabled = true;
  setRuntime("Ready", "");
  renderPreview();
}

picker.addEventListener("change", function() {
  loadExample(picker.value);
});

resetButton.addEventListener("click", function() {
  loadExample(picker.value);
});

runButton.addEventListener("click", runProgram);
incrementButton.addEventListener("click", function() {
  quickWrite(1, false);
});
batchButton.addEventListener("click", function() {
  quickWrite(1, true);
});

loadExample("counter");
