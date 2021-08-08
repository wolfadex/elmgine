import { StreamLanguage } from "@codemirror/stream-parser";
import { elm as codemirrorElmLanguage } from "@codemirror/legacy-modes/mode/elm";
import { basicSetup } from "@codemirror/basic-setup";
import { EditorView, keymap } from "@codemirror/view";
import { defaultTabBinding } from "@codemirror/commands";
import {
  EditorState,
  Transaction,
  Compartment,
  StateField,
} from "@codemirror/state";
import {
  IndentContext,
  indentString,
  getIndentation,
} from "@codemirror/language";

// Mostly copied from https://github.com/codemirror/commands/blob/0f8b2acc5faedcc50131a214ee837eb9b27dc547/src/commands.ts#L617
const insertElmTab = ({ state, dispatch }) => {
  if (state.selection.ranges.some((r) => !r.empty))
    return indentMore({ state, dispatch });
  dispatch(
    // Elm uses 4 spaces for indentation
    state.update(state.replaceSelection("    "), {
      scrollIntoView: true,
      annotations: Transaction.userEvent.of("input"),
    })
  );
  return true;
};

/// Copied from https://github.com/codemirror/commands/blob/0f8b2acc5faedcc50131a214ee837eb9b27dc547/src/commands.ts#L571
const indentSelection = ({ state, dispatch }) => {
  let updated = Object.create(null);
  let context = new IndentContext(state, {
    overrideIndentation: (start) => {
      let found = updated[start];
      return found == null ? -1 : found;
    },
  });
  let changes = changeBySelectedLine(state, (line, changes, range) => {
    let indent = getIndentation(context, line.from);
    if (indent == null) return;
    let cur = /^\s*/.exec(line.text)[0];
    let norm = indentString(state, indent);
    if (cur != norm || range.from < line.from + cur.length) {
      updated[line.from] = indent;
      changes.push({
        from: line.from,
        to: line.from + cur.length,
        insert: norm,
      });
    }
  });
  if (!changes.changes.empty) dispatch(state.update(changes));
  return true;
};

const elmEditorTabBinding = {
  key: "Tab",
  run: insertElmTab,
  shift: indentSelection,
};

customElements.define(
  "code-editor",
  class extends HTMLElement {
    connectedCallback() {
      const editorElement = document.createElement("div");

      this.appendChild(editorElement);

      const language = new Compartment();
      const tabSize = new Compartment();
      const forwardUpdate = StateField.define({
        create: (state) => state,
        update: (state, transaction) => {
          console.log(transaction.newDoc.text);
          this.emitUpdate(transaction.newDoc.text);
          return state;
        },
      });
      const state = EditorState.create({
        extensions: [
          basicSetup,
          keymap.of([
            elmEditorTabBinding,
            // defaultTabBinding
          ]),
          //   language.of(markdown()),
          StreamLanguage.define(codemirrorElmLanguage),
          forwardUpdate,
        ],
      });

      let view = new EditorView({
        state: state,
        parent: editorElement,
      });
    }

    emitUpdate(text) {
      this.dispatchEvent(
        new CustomEvent("change", { detail: text.join("\n") })
      );
    }

    disconnectedCallback() {}

    adoptedCallback() {}
  }
);
